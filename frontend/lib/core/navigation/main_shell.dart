import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  // Routes for each role. Order determines tab index.
  static const _hostRoutes = [
    (label: 'Explore',  icon: Icons.explore_outlined,        route: '/'),
    (label: 'Listings', icon: Icons.home_work_outlined,       route: '/host/listings'),
    (label: 'Bookings', icon: Icons.event_note_outlined,      route: '/host/bookings'),
    (label: 'Profile',  icon: Icons.person_outline,           route: '/profile'),
  ];

  static const _travelerRoutes = [
    (label: 'Explore',  icon: Icons.explore_outlined,         route: '/'),
    (label: 'Bookings', icon: Icons.receipt_long_outlined,    route: '/bookings'),
    (label: 'Profile',  icon: Icons.person_outline,           route: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authStateProvider).valueOrNull;
    final isHost   = user?.isHost == true;
    final items    = isHost ? _hostRoutes : _travelerRoutes;
    final location = GoRouterState.of(context).uri.path;

    // Find the deepest matching tab without triggering false-positives for '/'.
    int selectedIndex = 0;
    for (int i = items.length - 1; i >= 0; i--) {
      final route = items[i].route;
      if (route == '/' ? location == '/' : location.startsWith(route)) {
        selectedIndex = i;
        break;
      }
    }

    // WHY Column instead of nested Scaffold?
    // Each main screen (ExploreScreen, HostBookingsScreen, etc.) already has its
    // own Scaffold. Wrapping them in another Scaffold causes nested-Scaffold layout
    // conflicts: the outer Scaffold's body passes infinite-width constraints to
    // the inner Scaffold's ListView in some rendering paths, crashing with
    // "BoxConstraints forces an infinite width."
    // Using Column + Expanded avoids the nested Scaffold entirely.
    // MediaQuery.removePadding strips the bottom safe-area so the inner Scaffold
    // doesn't double-count the home indicator — NavigationBar handles it itself.
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(items[i].route),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
          ],
        ),
      ],
    );
  }
}

// Standalone notification bell widget — used in AppBars across the app.
// Kept here alongside the shell so both pieces of nav UI live together.
class NotificationBellAction extends ConsumerWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: () => context.pushNamed('notifications'),
        color: kDark,
      ),
    );
  }
}
