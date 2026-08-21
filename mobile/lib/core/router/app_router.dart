import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/booking/presentation/booking_create_screen.dart';
import '../../features/booking/presentation/booking_chat_screen.dart';
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
import '../../features/reviews/presentation/review_form_screen.dart';
import '../../features/reviews/presentation/owner_profile_screen.dart';
import '../../features/safety/presentation/blocked_users_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/presentation/support_ticket_screen.dart';
import '../compatibility/compatibility_gate.dart';
import '../compatibility/update_required_screen.dart';
import '../storage/onboarding_storage.dart';
import 'auth_intent.dart';
import 'app_shell.dart';

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
        state.uri.toString(),
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
        builder: (context, state) => OnboardingScreen(
          returnTo: safeAppReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => PhoneScreen(
          returnTo: safeAppReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => OtpScreen(
          returnTo: safeAppReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(path: '/home', redirect: (context, state) => '/catalog'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BookingDetailsScreen(
                      bookingId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) => BookingChatScreen(
                          bookingId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'review',
                        builder: (context, state) => ReviewFormScreen(
                          bookingId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/items/mine',
                builder: (context, state) => const OwnedItemsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'sessions',
                    builder: (context, state) => const SessionsScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) =>
                        const AnalyticsSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsScreen(),
                  ),
                  GoRoute(
                    path: 'data-export',
                    builder: (context, state) => const DataExportScreen(),
                  ),
                  GoRoute(
                    path: 'close-account',
                    builder: (context, state) => const AccountClosureScreen(),
                  ),
                  GoRoute(
                    path: 'blocked-users',
                    builder: (context, state) => const BlockedUsersScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/support',
                builder: (context, state) => const SupportScreen(),
                routes: [
                  GoRoute(
                    path: 'export',
                    builder: (context, state) => const SupportScreen(
                      initialSubject: 'Запрос экспорта данных',
                      initialMessage:
                          'Прошу подготовить экспорт данных моего аккаунта.',
                    ),
                  ),
                  GoRoute(
                    path: ':ticketId',
                    builder: (context, state) => SupportTicketScreen(
                      ticketId: state.pathParameters['ticketId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/items/new',
        builder: (context, state) => const CreateItemScreen(),
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
        path: '/items/:id/owner',
        builder: (context, state) =>
            OwnerProfileScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) =>
            ItemDetailsScreen(itemId: state.pathParameters['id']!),
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
  final uri = Uri.tryParse(location) ?? Uri(path: location);
  final path = uri.path;

  if (updateRequirement != null) {
    return path == '/update-required' ? null : '/update-required';
  }

  if (!onboardingCompleted) {
    if (path == '/onboarding') {
      return null;
    }
    final returnTo = safeAppReturnTo(uri.toString());
    if (returnTo == null || returnTo == '/catalog') {
      return '/onboarding';
    }
    return routeWithReturnTo('/onboarding', returnTo);
  }

  if (authState is AuthLoading) {
    if (path == '/' || isPublicAppPath(path)) {
      return null;
    }
    return '/';
  }

  if (authState is AuthAuthenticated) {
    final isAuthLocation = path == '/auth' || path.startsWith('/auth/');
    if (isAuthLocation) {
      return safeAppReturnTo(uri.queryParameters['returnTo']) ?? '/catalog';
    }
    if (path == '/' || path == '/onboarding') {
      return '/catalog';
    }

    return null;
  }

  if (path == '/' || path == '/onboarding') {
    return '/catalog';
  }

  if (isPublicAppPath(path)) {
    return null;
  }

  if (path == '/auth/phone') {
    return null;
  }

  if (path == '/auth/otp' && authState is AuthCodeSent) {
    return null;
  }

  final returnTo = safeAppReturnTo(uri.toString());
  return returnTo == null
      ? '/auth/phone'
      : routeWithReturnTo('/auth/phone', returnTo);
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
