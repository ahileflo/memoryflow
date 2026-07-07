import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/models/album.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_tile.dart';

/// Album Detail: a hero image, the AI-curated "best of this album" grid, and a
/// "Turn this into a gift" CTA that opens the matching product.
class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumProvider(albumId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: albumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load album: $e')),
          data: (album) => _AlbumBody(album: album),
        ),
      ),
    );
  }
}

class _AlbumBody extends StatelessWidget {
  const _AlbumBody({required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onTap: () => context.pop()),
          ),
        ),
        const SizedBox(height: 4),
        // Hero with title overlay
        Stack(
          children: [
            PhotoTile(url: album.heroUrl, height: 230, borderRadius: 0, width: double.infinity),
            Positioned(
              left: 22,
              bottom: 14,
              right: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandChip('✨ Auto-created',
                      background: Color(0xE6FFFFFF), foreground: BrandColors.violetDark),
                  const SizedBox(height: 8),
                  Text(
                    album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                    ),
                  ),
                  Text(
                    album.detailCountLabel,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Best of this album'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
                children: [
                  for (final photo in album.bestShots)
                    PhotoTile(url: photo.url, borderRadius: 10),
                ],
              ),
              const SizedBox(height: 20),
              BrandButton(
                label: '🎁 Turn this into a gift',
                // Mock mode opens the canvas product directly. Backend mode sends
                // you to the Gifts tab, where real AI suggestions live.
                onPressed: () => AppConfig.backendEnabled
                    ? context.go(Routes.gifts)
                    : context.push('${Routes.product}/canvas'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back, color: BrandColors.ink),
      iconSize: 24,
    );
  }
}
