import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/features/support/data/support_models.dart';
import 'package:mobile/features/support/data/support_service.dart';
import 'package:mobile/features/support/presentation/support_screen.dart';
import 'package:mobile/features/support/presentation/support_ticket_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('creates and refreshes an ordinary support ticket', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _FakeSupportService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supportServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: SupportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Обращений пока нет'), findsOneWidget);
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({
      'subject': 'Вопрос о профиле',
      'message': 'Не получается изменить имя в профиле.',
    });
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pumpAndSettle();

    expect(service.created, hasLength(1));
    expect(find.text('Вопрос о профиле'), findsOneWidget);
    expect(find.text('Открыто'), findsOneWidget);
  });

  testWidgets('retries the support list after an error', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportTicketsProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) {
              throw Exception('offline');
            }
            return [ticket];
          }),
        ],
        child: const MaterialApp(home: SupportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить обращения'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text(ticket.subject), findsOneWidget);
  });

  testWidgets('opens a ticket thread and sends a message', (tester) async {
    _useTallSurface(tester);
    final service = _FakeSupportService()
      ..created.add(ticket)
      ..messages.add(message);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supportServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: SupportTicketScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ticket.message), findsOneWidget);
    expect(find.text(message.body), findsOneWidget);
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({'body': 'Спасибо, вопрос теперь понятен.'});
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pumpAndSettle();

    expect(service.sentBodies, ['Спасибо, вопрос теперь понятен.']);
    expect(find.text('Спасибо, вопрос теперь понятен.'), findsOneWidget);
  });

  testWidgets('does not duplicate a legacy admin response in the thread', (
    tester,
  ) async {
    _useTallSurface(tester);
    final legacyReply = message.body;
    final service = _FakeSupportService()
      ..created.add(ticket.copyWith(adminResponse: legacyReply))
      ..messages.add(message);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supportServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: SupportTicketScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(legacyReply), findsOneWidget);
  });

  testWidgets('selects a private photo and sends it with the message', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _FakeSupportService()..created.add(ticket);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportServiceProvider.overrideWithValue(service),
          supportPhotoPickerProvider.overrideWithValue(_FakePhotoPicker()),
          appPermissionGatewayProvider.overrideWithValue(
            _FakePermissionGateway(),
          ),
        ],
        child: const MaterialApp(
          home: SupportTicketScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Добавить фото'));
    await tester.pumpAndSettle();
    expect(find.text('support.jpg'), findsOneWidget);

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({'body': 'Прикладываю фото повреждения.'});
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pumpAndSettle();

    expect(service.sentAttachmentCounts, [1]);
    expect(find.text('support.jpg'), findsNothing);
  });

  testWidgets('shows a closed ticket as read-only', (tester) async {
    _useTallSurface(tester);
    final service = _FakeSupportService()
      ..created.add(ticket.copyWith(status: 'CLOSED'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supportServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: SupportTicketScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Обращение закрыто. Создайте новое, если вопрос остался.'),
      findsOneWidget,
    );
    expect(find.byType(FormBuilder), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Отправить'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Добавить фото'), findsNothing);
  });

  testWidgets('prefills a manual data export request', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportServiceProvider.overrideWithValue(_FakeSupportService()),
        ],
        child: const MaterialApp(
          home: SupportScreen(
            initialSubject: 'Запрос экспорта данных',
            initialMessage: 'Прошу подготовить экспорт данных моего аккаунта.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    expect(form.instantValue['subject'], 'Запрос экспорта данных');
    expect(
      form.instantValue['message'],
      'Прошу подготовить экспорт данных моего аккаунта.',
    );
  });
}

class _FakeSupportService extends SupportService {
  _FakeSupportService() : super(Dio());

  final List<SupportTicket> created = [];
  final List<SupportMessage> messages = [];
  final List<String> sentBodies = [];
  final List<int> sentAttachmentCounts = [];

  @override
  Future<List<SupportTicket>> listMine() async => [...created];

  @override
  Future<SupportTicket> create(CreateSupportTicketDraft draft) async {
    final result = ticket.copyWith(
      subject: draft.subject,
      message: draft.message,
    );
    created.add(result);
    return result;
  }

  @override
  Future<List<SupportMessage>> listMessages(String ticketId) async => [
    ...messages,
  ];

  @override
  Future<SupportMessage> createMessage(
    String ticketId,
    String body, {
    List<XFile> attachments = const [],
  }) async {
    sentBodies.add(body);
    sentAttachmentCounts.add(attachments.length);
    final result = SupportMessage(
      id: 'message-${messages.length + 1}',
      authorRole: 'USER',
      body: body,
      attachments: const [],
      createdAt: DateTime.utc(2026, 7, 29, 12, 10),
    );
    messages.add(result);
    return result;
  }
}

class _FakePhotoPicker extends SupportPhotoPicker {
  _FakePhotoPicker() : super(ImagePicker());

  @override
  Future<List<XFile>> pick({required int limit}) async => [
    XFile('/private/tmp/support.jpg', mimeType: 'image/jpeg'),
  ];
}

class _FakePermissionGateway implements AppPermissionGateway {
  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      PermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;
}

void _useTallSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 2200);
  addTearDown(tester.view.reset);
}

final ticket = SupportTicket(
  id: 'ticket-1',
  type: 'GENERAL',
  bookingId: null,
  bookingIssueReason: null,
  subject: 'Вопрос о профиле',
  message: 'Не получается изменить имя в профиле.',
  status: 'OPEN',
  adminResponse: null,
  respondedAt: null,
  createdAt: DateTime.utc(2026, 7, 29),
  updatedAt: DateTime.utc(2026, 7, 29),
);

final message = SupportMessage(
  id: 'message-1',
  authorRole: 'SUPPORT',
  body: 'Опишите, пожалуйста, что именно не получается.',
  attachments: const [],
  createdAt: DateTime.utc(2026, 7, 29, 12, 5),
);
