import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/compatibility/compatibility_gate.dart';
import 'package:mobile/core/compatibility/update_required_screen.dart';

void main() {
  testWidgets('shows a blocking update action and opens the trusted URL', (
    tester,
  ) async {
    final launcher = _FakeExternalUrlLauncher();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compatibilityRequirementProvider.overrideWith(
            _RequiredUpdateController.new,
          ),
          externalUrlLauncherProvider.overrideWithValue(launcher),
        ],
        child: const MaterialApp(home: UpdateRequiredScreen()),
      ),
    );

    expect(find.text('Нужно обновить приложение'), findsOneWidget);
    expect(find.text('Минимальная версия: 2.0.0'), findsOneWidget);
    await tester.tap(find.text('Открыть магазин приложений'));
    await tester.pump();

    expect(launcher.opened, Uri.parse('https://store.example/sosedi'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
  });
}

class _RequiredUpdateController extends CompatibilityController {
  @override
  UpdateRequirement build() {
    return UpdateRequirement(
      code: 'MOBILE_UPDATE_REQUIRED',
      message: 'Требуется версия приложения 2.0.0 или новее',
      minimumVersion: '2.0.0',
      updateUrl: Uri.parse('https://store.example/sosedi'),
    );
  }
}

class _FakeExternalUrlLauncher extends ExternalUrlLauncher {
  Uri? opened;

  @override
  Future<bool> open(Uri url) async {
    opened = url;
    return true;
  }
}
