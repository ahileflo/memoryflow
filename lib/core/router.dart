import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import 'config.dart';
import '../features/album/album_detail_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/connect/connect_screen.dart';
import '../features/home/home_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scanning/scanning_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/success/success_screen.dart';
import '../features/suggestions/suggestions_screen.dart';
import '../features/welcome/welcome_screen.dart';

/// App route paths in one place.
abstract final class Routes {
  static const signIn = '/sign-in';
  static const welcome = '/welcome';
  static const connect = '/connect';
  static const scanning = '/scanning';
  static const home = '/home';
  static const gifts = '/gifts';
  static const profile = '/profile';
  static const album = '/album'; // /album/:id
  static const product = '/product'; // /product/:id
  static const checkout = '/checkout';
  static const success = '/success';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// The app's go_router configuration.
///
/// Onboarding (welcome → connect → scanning) and drill-down screens (album,
/// product, checkout, success) are full-screen routes with no bottom bar.
/// Home / Gifts / Profile live inside a [StatefulShellRoute] so the tab bar is
/// persistent and each tab keeps its own state — exactly like the prototype.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.welcome,
    // Re-evaluate the auth gate whenever the sign-in state changes.
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      // No auth gate in mock mode — the app behaves like Milestone 1.
      if (!AppConfig.backendEnabled) return null;
      final signedIn = auth.currentUser != null;
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!signedIn && !atSignIn) return Routes.signIn;
      if (signedIn && atSignIn) return Routes.welcome;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.connect,
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: Routes.scanning,
        builder: (context, state) => const ScanningScreen(),
      ),

      // ----- Tabbed area: Home / Gifts / Profile -----
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.gifts,
                builder: (context, state) => const SuggestionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ----- Drill-down / flow screens (no bottom bar) -----
      GoRoute(
        path: '${Routes.album}/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            AlbumDetailScreen(albumId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.product}/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.checkout,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.success,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SuccessScreen(),
      ),
    ],
  );
});

/// Bridges a [Stream] (Supabase auth changes) to a [Listenable] so go_router
/// re-runs its [GoRouter.redirect] whenever the sign-in state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

