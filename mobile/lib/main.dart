import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/private_state_cleanup.dart';
import 'core/analytics/analytics.dart';
import 'core/config/app_config.dart';
import 'core/location/listing_point_picker.dart';
import 'core/network/dio_provider.dart';
import 'core/observability/glitchtip.dart';
import 'core/router/app_router.dart';
import 'core/storage/onboarding_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_controller.dart';
import 'features/booking/data/booking_service.dart';
import 'features/map/presentation/map_point_picker_screen.dart';
import 'features/notifications/domain/notification_navigation_controller.dart';
import 'features/notifications/data/inbox_service.dart';
import 'features/notifications/domain/inbox_controller.dart';
import 'features/profile/domain/data_export_controller.dart';

Future<void> main() async {
  await runWithGlitchTip(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();
    final yandexTilesApiKey = AppConfig.yandexTilesApiKey;

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          if (yandexTilesApiKey != null)
            listingPointPickerProvider.overrideWithValue(
              (context, initialPoint) => openMapPointPicker(
                context,
                initialPoint,
                apiKey: yandexTilesApiKey,
              ),
            ),
        ],
        child: const SosediApp(),
      ),
    );
  });
}

class SosediApp extends ConsumerStatefulWidget {
  const SosediApp({super.key});

  @override
  ConsumerState<SosediApp> createState() => _SosediAppState();
}

class _SosediAppState extends ConsumerState<SosediApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      ref.read(analyticsServiceProvider).track(AnalyticsEvent.appOpened),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authControllerProvider.notifier).validateSessionOnResume();
      ref.invalidate(bookingMessagesProvider);
      ref.invalidate(inboxEventsProvider);
      ref.invalidate(inboxControllerProvider);
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.invalidate(bookingDetailsProvider);
      ref.invalidate(bookingActsProvider);
      ref.invalidate(dataExportControllerProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(apiCompatibilityCheckProvider);
    ref.watch(privateStateCleanupProvider);
    ref.watch(notificationNavigationProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Соседи',
      theme: AppTheme.light(),
      locale: const Locale('ru'),
      localizationsDelegates: FormBuilderLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('ru')],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
