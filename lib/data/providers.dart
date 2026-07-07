import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import 'auth/auth_service.dart';
import 'models/album.dart';
import 'models/billing.dart';
import 'models/connected_account.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/user_profile.dart';
import 'repository/mock_repository.dart';
import 'repository/repository.dart';
import 'repository/supabase_repository.dart';

/// Authentication service — real (Supabase) when the backend is enabled,
/// otherwise a no-op mock that is always "signed in".
final authServiceProvider = Provider<AuthService>((ref) {
  return AppConfig.backendEnabled ? SupabaseAuthService() : MockAuthService();
});

/// Streams the signed-in user (or null). Drives the router's auth gate.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// The active [Repository]. Uses Supabase when [AppConfig.backendEnabled],
/// otherwise the in-memory mock — the rest of the app is identical either way.
final repositoryProvider = Provider<Repository>((ref) {
  if (AppConfig.backendEnabled) {
    // Rebuild (and refetch) whenever auth changes so queries target the
    // current user.
    ref.watch(authStateProvider);
    return SupabaseRepository();
  }
  return MockRepository();
});

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(repositoryProvider).getProfile(),
);

final accountsProvider = FutureProvider<List<ConnectedAccount>>(
  (ref) => ref.watch(repositoryProvider).getAccounts(),
);

final albumsProvider = FutureProvider<List<Album>>(
  (ref) => ref.watch(repositoryProvider).getAlbums(),
);

final albumProvider = FutureProvider.family<Album, String>(
  (ref, id) => ref.watch(repositoryProvider).getAlbum(id),
);

final suggestionsProvider = FutureProvider<List<ProductSuggestion>>(
  (ref) => ref.watch(repositoryProvider).getSuggestions(),
);

/// Subscription + AI-credit state for the Profile screen.
final billingStatusProvider = FutureProvider<BillingState>(
  (ref) => ref.watch(repositoryProvider).billingStatus(),
);

final productProvider = FutureProvider.family<ProductSuggestion, String>(
  (ref, id) => ref.watch(repositoryProvider).getProduct(id),
);

/// Tracks which photo sources the user has toggled on the Connect screen.
class ConnectSelection extends StateNotifier<Set<String>> {
  ConnectSelection() : super(<String>{});

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  bool isOn(String id) => state.contains(id);
  int get count => state.length;
}

final connectSelectionProvider =
    StateNotifierProvider<ConnectSelection, Set<String>>((ref) => ConnectSelection());

/// The in-progress order, shared between the Product, Checkout and Success
/// screens. Selecting a size updates this; checkout reads it.
final orderDraftProvider = StateProvider<OrderDraft?>((ref) => null);

/// The placed order's confirmation, read by the Success screen.
final orderConfirmationProvider = StateProvider<OrderConfirmation?>((ref) => null);

/// The id of the in-flight import job (backend mode). The scanning screen polls
/// it for live progress; null means "use the mock scan animation".
final currentImportJobIdProvider = StateProvider<String?>((ref) => null);
