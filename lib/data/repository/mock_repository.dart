import '../../core/config.dart';
import '../catalog.dart';
import '../models/album.dart';
import '../models/billing.dart';
import '../models/import_job.dart';
import '../models/connected_account.dart';
import '../models/order.dart';
import '../models/photo.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import 'repository.dart';

/// Builds a placeholder image URL from a seed (deterministic, like the
/// prototype's `https://picsum.photos/seed/<seed>/<w>/<h>`).
String picsum(String seed, int w, int h) => 'https://picsum.photos/seed/$seed/$w/$h';

/// In-memory implementation of [Repository]. No network, no accounts, no keys.
///
/// Data mirrors the approved prototype's `ALBUMS` and `PRODUCTS` arrays so the
/// Flutter app and the HTML demo show the same memories. A small artificial
/// latency is added so loading states are exercised.
class MockRepository implements Repository {
  // ----- Albums (from the prototype's ALBUMS) ------------------------------
  static final List<_AlbumSeed> _albumSeeds = [
    const _AlbumSeed('italy', 'Italy 2024', 'Trip', 312, 47, 'italy7'),
    const _AlbumSeed('baby', "Baby's first year", 'People', 604, 60, 'baby4'),
    const _AlbumSeed('dog', 'Biscuit 🐶', 'Pet', 188, 22, 'dog9'),
    const _AlbumSeed('family', 'Mom & Dad', 'People', 421, 38, 'family3'),
    const _AlbumSeed('best', 'Best of 2025', 'Best-of', 50, 50, 'sunset2'),
    const _AlbumSeed('wed', 'The wedding', 'Event', 733, 64, 'wedding5'),
  ];

  // ----- Products (from the prototype's PRODUCTS) --------------------------
  static final List<ProductSuggestion> _products = [
    ProductSuggestion(
      id: 'canvas',
      type: 'canvas',
      name: 'Italy 2024 Canvas',
      description:
          'A 40×30cm gallery-wrap canvas built from the 6 best shots of your trip.',
      tag: 'Wall canvas',
      heroUrl: picsum('italy7', 600, 450),
      sourceAlbumId: 'italy',
      createdFromPhotoCount: 312,
      defaultSizeIndex: 1,
      sizes: const [
        ProductSize('30×20', 29),
        ProductSize('40×30', 49),
        ProductSize('60×40', 79),
      ],
    ),
    ProductSuggestion(
      id: 'book',
      type: 'book',
      name: "Baby's First Year book",
      description: '28-page hardcover photo book, auto-laid-out from your best moments.',
      tag: 'Photo book',
      heroUrl: picsum('baby4', 600, 450),
      sourceAlbumId: 'baby',
      createdFromPhotoCount: 604,
      defaultSizeIndex: 1,
      sizes: const [
        ProductSize('20 pages', 29),
        ProductSize('28 pages', 39),
        ProductSize('40 pages', 59),
      ],
    ),
    ProductSuggestion(
      id: 'mug',
      type: 'mug',
      name: 'Biscuit mug',
      description: "Ceramic mug featuring your dog's best portrait.",
      tag: 'Gift',
      heroUrl: picsum('dog9', 600, 450),
      sourceAlbumId: 'dog',
      createdFromPhotoCount: 188,
      defaultSizeIndex: 0,
      sizes: const [
        ProductSize('Standard', 15),
        ProductSize('Large', 19),
      ],
    ),
  ];

  static const _latency = Duration(milliseconds: 450);

  Album _buildAlbum(_AlbumSeed s) {
    final best = List<Photo>.generate(
      9,
      (i) => Photo(
        id: '${s.id}-$i',
        url: picsum('${s.seed}-$i', 250, 250),
        qualityScore: 0.9 - i * 0.03,
        isBestShot: true,
      ),
    );
    return Album(
      id: s.id,
      title: s.title,
      badge: s.badge,
      photoCount: s.photoCount,
      bestShotCount: s.bestShotCount,
      coverUrl: picsum(s.seed, 400, 400),
      heroUrl: picsum(s.seed, 700, 500),
      bestShots: best,
    );
  }

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(_latency);
    return const UserProfile(
      name: 'Ahile',
      email: 'woopsahile@gmail.com',
      planLabel: 'Free plan · 1 account',
      isPremium: false,
      totalPhotos: AppConfig.demoLibraryPhotoCount,
      albumCount: AppConfig.demoSmartAlbumCount,
    );
  }

  @override
  Future<List<ConnectedAccount>> getAccounts() async {
    await Future<void>.delayed(_latency);
    return connectedAccountCatalog();
  }

  @override
  Future<List<Album>> getAlbums() async {
    await Future<void>.delayed(_latency);
    return _albumSeeds.map(_buildAlbum).toList();
  }

  @override
  Future<Album> getAlbum(String id) async {
    await Future<void>.delayed(_latency);
    final seed = _albumSeeds.firstWhere(
      (s) => s.id == id,
      orElse: () => _albumSeeds.first,
    );
    return _buildAlbum(seed);
  }

  @override
  Future<List<ProductSuggestion>> getSuggestions() async {
    await Future<void>.delayed(_latency);
    return _products;
  }

  @override
  Future<ProductSuggestion> getProduct(String id) async {
    await Future<void>.delayed(_latency);
    return _products.firstWhere((p) => p.id == id, orElse: () => _products.first);
  }

  @override
  Future<OrderConfirmation> placeOrder(OrderDraft draft) async {
    await Future<void>.delayed(_latency);
    return OrderConfirmation(
      orderId: 'MF-MOCK-0001',
      draft: draft,
      createdFromPhotoCount: AppConfig.demoLibraryPhotoCount,
    );
  }

  // Mock import is instantaneous — the mock scanning screen uses its own
  // animation, so these exist only to satisfy the interface.
  @override
  Future<ImportJob> startImport({required String provider, String mode = 'sample'}) async {
    await Future<void>.delayed(_latency);
    return const ImportJob(
      id: 'mock-job',
      status: 'done',
      total: AppConfig.demoLibraryPhotoCount,
      processed: AppConfig.demoLibraryPhotoCount,
    );
  }

  @override
  Future<ImportJob> getImportJob(String id) async => const ImportJob(
        id: 'mock-job',
        status: 'done',
        total: AppConfig.demoLibraryPhotoCount,
        processed: AppConfig.demoLibraryPhotoCount,
      );

  @override
  Future<int> organize({String mode = 'heuristic'}) async {
    await Future<void>.delayed(_latency);
    return AppConfig.demoSmartAlbumCount;
  }

  @override
  Future<int> generateSuggestions({String mode = 'heuristic'}) async {
    await Future<void>.delayed(_latency);
    return _products.length;
  }

  // ---- Monetization (in-memory, so the upgrade/credits flow demos in mock) ----
  String _plan = 'free';
  int _credits = 0;

  @override
  Future<BillingState> billingStatus() async {
    await Future<void>.delayed(_latency);
    return BillingState(plan: _plan, isPremium: _plan == 'premium', balance: _credits);
  }

  @override
  Future<BillingState> subscribe() async {
    await Future<void>.delayed(_latency);
    _plan = 'premium';
    _credits += 50;
    return BillingState(plan: _plan, isPremium: true, balance: _credits);
  }

  @override
  Future<int> buyCredits(int amount) async {
    await Future<void>.delayed(_latency);
    _credits += amount;
    return _credits;
  }

  @override
  Future<SpendResult> spendCredit(String reason) async {
    await Future<void>.delayed(_latency);
    if (_plan == 'premium') return SpendResult(ok: true, balance: _credits);
    if (_credits < 1) return const SpendResult(ok: false, balance: 0, needCredits: true);
    _credits -= 1;
    return SpendResult(ok: true, balance: _credits);
  }

  @override
  Future<void> logEvent(String event, [Map<String, dynamic> props = const {}]) async {}
}

class _AlbumSeed {
  const _AlbumSeed(
      this.id, this.title, this.badge, this.photoCount, this.bestShotCount, this.seed);
  final String id;
  final String title;
  final String badge;
  final int photoCount;
  final int bestShotCount;
  final String seed;
}
