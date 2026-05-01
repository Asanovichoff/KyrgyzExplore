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
import '../../shared/models/listing_model.dart';
import '../../features/host/screens/create_edit_listing_screen.dart';
import '../../features/host/screens/host_listings_screen.dart';
import '../../features/host/screens/manage_availability_screen.dart';
import '../../features/listing/screens/listing_detail_screen.dart';

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
      GoRoute(name: 'home',     path: '/',              builder: (_, __) => const ExploreScreen()),
      GoRoute(name: 'login',    path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(name: 'register', path: '/auth/register', builder: (_, __) => const RegisterScreen()),
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
      ),
      GoRoute(
        name: 'host-listings-new',
        path: '/host/listings/new',
        builder: (_, __) => const CreateEditListingScreen(),
      ),
      GoRoute(
        name: 'host-listings-edit',
        path: '/host/listings/:id/edit',
        builder: (_, state) => CreateEditListingScreen(
          listing: state.extra as ListingModel,
        ),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        name: 'host-availability',
        path: '/host/listings/:id/availability',
        builder: (_, state) => ManageAvailabilityScreen(
          listing: state.extra as ListingModel,
        ),
      ),
    ],
  );
});

// GoRouter needs a Listenable to know when to re-evaluate redirects.
// We wrap the Riverpod notifier in a ChangeNotifier adapter.
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
