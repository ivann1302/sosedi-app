import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../storage/onboarding_storage.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen<AuthState>(
    authControllerProvider,
    (_, _) => refreshNotifier.refresh(),
  );
  ref.listen<bool>(
    onboardingCompletedProvider,
    (_, _) => refreshNotifier.refresh(),
  );

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      return appRedirect(
        ref.read(authControllerProvider),
        ref.read(onboardingCompletedProvider),
        state.uri.path,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});

String? appRedirect(
  AuthState authState,
  bool onboardingCompleted,
  String location,
) {
  if (!onboardingCompleted) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  if (authState is AuthLoading) {
    return location == '/' ? null : '/';
  }

  if (authState is AuthAuthenticated) {
    final isAuthLocation = location == '/auth' || location.startsWith('/auth/');
    if (location == '/' || location == '/onboarding' || isAuthLocation) {
      return '/home';
    }

    return null;
  }

  if (location == '/auth/phone') {
    return null;
  }

  if (location == '/auth/otp' && authState is AuthCodeSent) {
    return null;
  }

  return '/auth/phone';
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
