import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/booking/presentation/booking_create_screen.dart';
import '../../features/booking/presentation/booking_details_screen.dart';
import '../../features/booking/presentation/booking_list_screen.dart';
import '../../features/item/presentation/create_item_screen.dart';
import '../../features/item/presentation/edit_item_screen.dart';
import '../../features/item/presentation/item_details_screen.dart';
import '../../features/item/presentation/owned_items_screen.dart';
import '../../features/notifications/presentation/inbox_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/profile/presentation/analytics_settings_screen.dart';
import '../../features/profile/presentation/account_closure_screen.dart';
import '../../features/profile/presentation/documents_screen.dart';
import '../../features/profile/presentation/data_export_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/sessions_screen.dart';
import '../../features/safety/presentation/blocked_users_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/presentation/support_ticket_screen.dart';
import '../compatibility/compatibility_gate.dart';
import '../compatibility/update_required_screen.dart';
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
  ref.listen<UpdateRequirement?>(
    compatibilityRequirementProvider,
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
        updateRequirement: ref.read(compatibilityRequirementProvider),
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SplashScreen()),
      GoRoute(
        path: '/update-required',
        builder: (context, state) => const UpdateRequiredScreen(),
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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/items/new',
        builder: (context, state) => const CreateItemScreen(),
      ),
      GoRoute(
        path: '/items/mine',
        builder: (context, state) => const OwnedItemsScreen(),
      ),
      GoRoute(
        path: '/items/:id/edit',
        builder: (context, state) =>
            EditItemScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/items/:id/booking',
        builder: (context, state) =>
            BookingCreateScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) =>
            ItemDetailsScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingListScreen(),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(path: '/inbox', builder: (context, state) => const InboxScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/sessions',
        builder: (context, state) => const SessionsScreen(),
      ),
      GoRoute(
        path: '/profile/analytics',
        builder: (context, state) => const AnalyticsSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/profile/data-export',
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: '/profile/close-account',
        builder: (context, state) => const AccountClosureScreen(),
      ),
      GoRoute(
        path: '/profile/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/support/export',
        builder: (context, state) => const SupportScreen(
          initialSubject: 'Запрос экспорта данных',
          initialMessage: 'Прошу подготовить экспорт данных моего аккаунта.',
        ),
      ),
      GoRoute(
        path: '/support/:ticketId',
        builder: (context, state) =>
            SupportTicketScreen(ticketId: state.pathParameters['ticketId']!),
      ),
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
  String location, {
  UpdateRequirement? updateRequirement,
}) {
  if (updateRequirement != null) {
    return location == '/update-required' ? null : '/update-required';
  }

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
