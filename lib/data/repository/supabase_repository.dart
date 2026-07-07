import 'package:supabase_flutter/supabase_flutter.dart';

import '../catalog.dart';
import '../models/album.dart';
import '../models/billing.dart';
import '../models/connected_account.dart';
import '../models/import_job.dart';
import '../models/order.dart';
import '../models/photo.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import 'repository.dart';

/// Real implementation of [Repository] backed by Supabase Postgres.
///
/// Every query is automatically scoped to the signed-in user by Row Level
/// Security (`user_id = auth.uid()`), so there are no manual user filters here.
/// On a fresh account most lists are empty until import (Milestone 3) and AI
/// organization (Milestone 4) populate them — that's expected. Use mock mode
/// to click through the full UI with rich data.
class SupabaseRepository implements Repository {
  SupabaseRepository() : _db = Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw StateError('SupabaseRepository used while signed out.');
    }
    return id;
  }

  @override
  Future<UserProfile> getProfile() async {
    final user = _db.auth.currentUser;
    final row = await _db.from('profiles').select().eq('id', _uid).maybeSingle();

    final photos = await _db.from('photos').select('id');
    final albums = await _db.from('albums').select('id');
    final accounts =
        await _db.from('connected_accounts').select('id').eq('status', 'connected');

    final plan = (row?['plan'] as String?) ?? 'free';
    final isPremium = plan == 'premium';
    final accountCount = (accounts as List).length;

    return UserProfile(
      name: (row?['display_name'] as String?) ?? user?.email?.split('@').first ?? 'You',
      email: (row?['email'] as String?) ?? user?.email ?? '',
      planLabel: isPremium
          ? 'Premium · unlimited'
          : 'Free plan · $accountCount account${accountCount == 1 ? '' : 's'}',
      isPremium: isPremium,
      totalPhotos: (photos as List).length,
      albumCount: (albums as List).length,
    );
  }

  @override
  Future<List<ConnectedAccount>> getAccounts() async {
    final rows = await _db
        .from('connected_accounts')
        .select('provider, status')
        .eq('status', 'connected');
    final connected = {for (final r in rows as List) r['provider'] as String};

    return connectedAccountCatalog()
      ..forEach((a) => a.connected = connected.contains(a.id));
  }

  @override
  Future<List<Album>> getAlbums() async {
    final rows = await _db.from('albums').select().order('created_at');
    return [for (final r in rows as List) _albumFromRow(r as Map<String, dynamic>)];
  }

  @override
  Future<Album> getAlbum(String id) async {
    final row = await _db.from('albums').select().eq('id', id).single();
    final photoRows = await _db
        .from('album_photos')
        .select('is_best_shot, rank, photos(id, thumbnail_url, quality_score, is_best_shot)')
        .eq('album_id', id)
        .order('rank');

    final best = <Photo>[];
    for (final r in photoRows as List) {
      final p = r['photos'] as Map<String, dynamic>?;
      if (p == null) continue;
      best.add(Photo(
        id: p['id'] as String,
        url: (p['thumbnail_url'] as String?) ?? '',
        qualityScore: ((p['quality_score'] as num?) ?? 0).toDouble(),
        isBestShot: (r['is_best_shot'] as bool?) ?? false,
      ));
    }
    return _albumFromRow(row, bestShots: best);
  }

  @override
  Future<List<ProductSuggestion>> getSuggestions() async {
    final rows = await _db
        .from('product_suggestions')
        .select()
        .neq('status', 'dismissed')
        .order('created_at');
    return [
      for (final r in rows as List) _suggestionFromRow(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<ProductSuggestion> getProduct(String id) async {
    final row = await _db.from('product_suggestions').select().eq('id', id).single();
    return _suggestionFromRow(row);
  }

  @override
  Future<OrderConfirmation> placeOrder(OrderDraft draft) async {
    // Checkout is handed off to the print partner server-side (create-order),
    // which creates the draft order, prices it, and records it in our DB.
    final res = await _db.functions.invoke('create-order', body: {
      'productSuggestionId': draft.product.id,
      'sizeLabel': draft.size.label,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    final orderId = data['orderId'] as String?;
    if (orderId == null) {
      throw Exception(data['error'] ?? 'Could not place order');
    }
    return OrderConfirmation(
      orderId: orderId,
      draft: draft,
      createdFromPhotoCount:
          (data['createdFromPhotoCount'] as int?) ?? draft.product.createdFromPhotoCount,
    );
  }

  @override
  Future<ImportJob> startImport({required String provider, String mode = 'sample'}) async {
    final res = await _db.functions.invoke(
      'import-photos',
      body: {'provider': provider, 'mode': mode},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    final jobId = data['jobId'] as String?;
    if (jobId == null) {
      throw Exception(data['error'] ?? 'Import failed to start');
    }
    return getImportJob(jobId);
  }

  @override
  Future<ImportJob> getImportJob(String id) async {
    final row = await _db.from('import_jobs').select().eq('id', id).maybeSingle();
    if (row == null) throw StateError('Import job $id not found');
    return ImportJob.fromMap(row);
  }

  @override
  Future<int> organize({String mode = 'heuristic'}) async {
    final res = await _db.functions.invoke('organize-photos', body: {'mode': mode});
    final data = (res.data as Map).cast<String, dynamic>();
    return (data['albums'] as int?) ?? 0;
  }

  @override
  Future<int> generateSuggestions({String mode = 'heuristic'}) async {
    final res = await _db.functions.invoke('suggest-products', body: {'mode': mode});
    final data = (res.data as Map).cast<String, dynamic>();
    return (data['suggestions'] as int?) ?? 0;
  }

  @override
  Future<BillingState> billingStatus() async {
    final res = await _db.functions.invoke('billing', body: {'action': 'status'});
    return BillingState.fromMap((res.data as Map).cast<String, dynamic>());
  }

  @override
  Future<BillingState> subscribe() async {
    final res = await _db.functions.invoke('billing', body: {'action': 'subscribe'});
    return BillingState.fromMap((res.data as Map).cast<String, dynamic>());
  }

  @override
  Future<int> buyCredits(int amount) async {
    final res = await _db.functions
        .invoke('billing', body: {'action': 'buy_credits', 'amount': amount});
    final data = (res.data as Map).cast<String, dynamic>();
    return (data['balance'] as int?) ?? 0;
  }

  @override
  Future<SpendResult> spendCredit(String reason) async {
    final res = await _db.functions
        .invoke('billing', body: {'action': 'spend_credit', 'reason': reason});
    final data = (res.data as Map).cast<String, dynamic>();
    return SpendResult(
      ok: (data['ok'] as bool?) ?? false,
      balance: (data['balance'] as int?) ?? 0,
      needCredits: (data['needCredits'] as bool?) ?? false,
    );
  }

  @override
  Future<void> logEvent(String event, [Map<String, dynamic> props = const {}]) async {
    try {
      await _db.from('analytics_events').insert({
        'user_id': _uid,
        'event': event,
        'props': props,
      });
    } catch (_) {
      // Analytics is best-effort.
    }
  }

  // ---- mapping helpers ------------------------------------------------------

  Album _albumFromRow(Map<String, dynamic> r, {List<Photo> bestShots = const []}) {
    return Album(
      id: r['id'] as String,
      title: (r['title'] as String?) ?? 'Album',
      badge: (r['badge'] as String?) ?? '',
      photoCount: (r['photo_count'] as int?) ?? 0,
      bestShotCount: (r['best_shot_count'] as int?) ?? 0,
      coverUrl: (r['cover_url'] as String?) ?? '',
      heroUrl: (r['hero_url'] as String?) ?? (r['cover_url'] as String?) ?? '',
      bestShots: bestShots,
    );
  }

  ProductSuggestion _suggestionFromRow(Map<String, dynamic> r) {
    final rawSizes = (r['sizes'] as List?) ?? const [];
    final sizes = [
      for (final s in rawSizes)
        ProductSize(
          (s['label'] as String?) ?? '',
          ((s['price'] as num?) ?? 0).toDouble(),
        ),
    ];
    return ProductSuggestion(
      id: r['id'] as String,
      type: (r['product_id'] as String?) ?? 'other',
      name: (r['name'] as String?) ?? 'Gift',
      description: (r['description'] as String?) ?? '',
      tag: (r['tag'] as String?) ?? '',
      heroUrl: (r['hero_url'] as String?) ?? '',
      sizes: sizes.isEmpty ? const [ProductSize('Standard', 0)] : sizes,
      defaultSizeIndex: (r['default_size_index'] as int?) ?? 0,
      sourceAlbumId: (r['source_album_id'] as String?) ?? '',
      createdFromPhotoCount: (r['created_from_photo_count'] as int?) ?? 0,
    );
  }
}
