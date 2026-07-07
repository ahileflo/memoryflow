import '../models/album.dart';
import '../models/billing.dart';
import '../models/connected_account.dart';
import '../models/import_job.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

/// The single data contract the whole app talks to.
///
/// Milestone 1 implements this with `MockRepository` (in-memory). Milestone 2
/// adds `SupabaseRepository` behind the *same* interface, selected via
/// `AppConfig.useMockData`. UI code never depends on the concrete class.
abstract interface class Repository {
  /// The signed-in user (mock identity in Milestone 1).
  Future<UserProfile> getProfile();

  /// Photo sources available on the Connect screen.
  Future<List<ConnectedAccount>> getAccounts();

  /// All smart albums for the Home grid.
  Future<List<Album>> getAlbums();

  /// A single album with its best shots, for Album Detail.
  Future<Album> getAlbum(String id);

  /// AI-designed gift suggestions for the Gifts tab.
  Future<List<ProductSuggestion>> getSuggestions();

  /// A single product suggestion, for the Product Detail / customize screen.
  Future<ProductSuggestion> getProduct(String id);

  /// Place an order. In mock mode this just synthesizes a confirmation;
  /// from Milestone 5 it creates a draft order with the print partner.
  Future<OrderConfirmation> placeOrder(OrderDraft draft);

  /// Kick off a read-only import for [provider]. Returns the job immediately
  /// (status 'running'); the scanning screen then polls [getImportJob].
  /// [mode] is 'sample' (no Google account) or 'google' (real Library API).
  Future<ImportJob> startImport({required String provider, String mode = 'sample'});

  /// Current progress of an import job (drives the live scan screen).
  Future<ImportJob> getImportJob(String id);

  /// Run the AI organization pipeline (clusters imported photos into albums,
  /// picks best shots, labels albums). Idempotent. Returns the album count.
  /// [mode] is 'heuristic' (no key) or 'ai' (Claude).
  Future<int> organize({String mode = 'heuristic'});

  /// Generate gift suggestions from the user's top albums (Claude writes copy
  /// in 'ai' mode). Idempotent. Returns the number of suggestions.
  Future<int> generateSuggestions({String mode = 'heuristic'});

  // ---- Monetization (Milestone 6) ----

  /// Current plan + AI credit balance.
  Future<BillingState> billingStatus();

  /// Start the €4.99/mo subscription. Returns the new state (mock activation),
  /// or a state carrying a Stripe [BillingState.checkoutUrl] to open.
  Future<BillingState> subscribe();

  /// Buy AI credits (mock grant unless Stripe is configured). Returns balance.
  Future<int> buyCredits(int amount);

  /// Spend one AI credit on a paywalled tool (enhance/restore/bg-removal).
  /// Premium users are unlimited.
  Future<SpendResult> spendCredit(String reason);

  /// Record a first-party analytics event (no-op in mock mode).
  Future<void> logEvent(String event, [Map<String, dynamic> props]);
}
