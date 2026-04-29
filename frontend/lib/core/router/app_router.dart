import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/booking/screens/booking_request_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/explore/models/listing_model.dart';
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
      GoRoute(path: '/',              builder: (_, __) => const ExploreScreen()),
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/listings/:listingId',
        builder: (_, state) => ListingDetailScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),
      GoRoute(
        path: '/listings/:listingId/book',
        builder: (_, state) => BookingRequestScreen(
          listing: state.extra as ListingModel,
        ),
      ),
      GoRoute(
        path: '/bookings',
        builder: (_, __) => const MyBookingsScreen(),
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
