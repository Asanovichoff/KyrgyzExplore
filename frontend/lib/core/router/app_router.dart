import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/booking/screens/booking_request_screen.dart';
import '../../features/booking/screens/host_bookings_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/booking/models/booking_model.dart';
import '../../shared/models/listing_model.dart';
import '../../features/host/screens/create_edit_listing_screen.dart';
import '../../features/host/screens/host_listings_screen.dart';
import '../../features/host/screens/manage_availability_screen.dart';
import '../../features/host/screens/payout_screen.dart';
import '../../features/listing/screens/listing_detail_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/message/screens/chat_screen.dart';
import '../navigation/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthNotifierListenable(ref),
    redirect: (context, state) {
      final authState  = ref.read(authStateProvider);
      final isLoading  = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuth   = state.matchedLocation.startsWith('/auth');

      if (isLoading) return null;

      if (!isLoggedIn && !isOnAuth) return '/auth/login';
      if (isLoggedIn  &&  isOnAuth) return '/';
      return null;
    },
    routes: [
      // Auth screens — no bottom nav bar.
      GoRoute(name: 'login',    path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(name: 'register', path: '/auth/register', builder: (_, __) => const RegisterScreen()),

      // All main screens share the bottom navigation bar via ShellRoute.
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            name: 'my-bookings',
            path: '/bookings',
            builder: (_, __) => const MyBookingsScreen(),
          ),
          GoRoute(
            name: 'host-bookings',
            path: '/host/bookings',
            builder: (_, __) => const HostBookingsScreen(),
          ),
          GoRoute(
            name: 'host-listings',
            path: '/host/listings',
            builder: (_, __) => const HostListingsScreen(),
            routes: [
              GoRoute(
                name: 'host-listings-new',
                path: 'new',
                builder: (_, __) => const CreateEditListingScreen(),
              ),
              GoRoute(
                name: 'host-listings-edit',
                path: ':id/edit',
                builder: (_, state) => CreateEditListingScreen(
                  listing: state.extra as ListingModel,
                ),
              ),
              GoRoute(
                name: 'host-availability',
                path: ':id/availability',
                builder: (_, state) => ManageAvailabilityScreen(
                  listing: state.extra as ListingModel,
                ),
              ),
            ],
          ),
          GoRoute(
            name: 'profile',
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                name: 'payouts',
                path: 'payouts',
                builder: (_, __) => const PayoutScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen flows — no bottom nav bar (pushed on top of the shell).
      GoRoute(
        name: 'listing-detail',
        path: '/listings/:listingId',
        builder: (_, state) => ListingDetailScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),
      GoRoute(
        name: 'booking-request',
        path: '/listings/:listingId/book',
        builder: (_, state) => BookingRequestScreen(
          listing: state.extra as ListingModel,
        ),
      ),
      GoRoute(
        name: 'notifications',
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        name: 'chat',
        path: '/chat/:bookingId',
        builder: (_, state) => ChatScreen(
          booking: state.extra as BookingModel,
        ),
      ),
    ],
  );
});

class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
