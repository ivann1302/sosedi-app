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
  final authState = ref.watch(authControllerProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading;

      if (!onboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }

      if (!onboardingCompleted) {
        return null;
      }

      if (isLoading) {
        return location == '/onboarding' ? '/' : null;
      }

      if (isAuthenticated &&
          (location == '/' ||
              location == '/onboarding' ||
              location.startsWith('/auth'))) {
        return '/home';
      }

      if (!isAuthenticated && (location == '/' || location == '/home')) {
        return '/auth/phone';
      }

      if (!isAuthenticated &&
          location == '/auth/otp' &&
          authState is! AuthCodeSent) {
        return '/auth/phone';
      }

      if (!isAuthenticated && location == '/onboarding') {
        return '/auth/phone';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashScreen(),
      ),
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
