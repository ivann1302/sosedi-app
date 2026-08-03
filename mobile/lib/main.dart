import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/private_state_cleanup.dart';
import 'core/analytics/analytics.dart';
import 'core/network/dio_provider.dart';
import 'core/observability/glitchtip.dart';
import 'core/router/app_router.dart';
import 'core/storage/onboarding_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_controller.dart';
import 'features/booking/data/booking_service.dart';
import 'features/notifications/domain/notification_navigation_controller.dart';
import 'features/profile/domain/data_export_controller.dart';

Future<void> main() async {
  await runWithGlitchTip(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
