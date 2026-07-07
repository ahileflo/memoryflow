import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/album_card.dart';
import '../../widgets/common.dart';

/// Home tab: greeting, the "we organized everything" summary, the smart-album
/// grid, and a gift-ideas call-to-action.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final albumsAsync = ref.watch(albumsProvider);

    final greetingName = profileAsync.maybeWhen(
      data: (p) => p.name,
      orElse: () => '',
    );
    final totalPhotos = profileAsync.maybeWhen(data: (p) => p.totalPhotos, orElse: () => 0);
    final albumCount = profileAsync.maybeWhen(data: (p) => p.albumCount, orElse: () => 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good evening, $greetingName',
                          style: const TextStyle(fontSize: 13, color: BrandColors.muted)),
                      const SizedBox(height: 2),
                      Text('Your memories',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                BrandAvatar(
                  initial: greetingName.isNotEmpty ? greetingName[0] : 'A',
                  onTap: () => context.go(Routes.profile),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: BrandColors.indigo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('We organized everything',
                            style: TextStyle(fontSize: 13, color: Color(0xFFBDB8DC))),
                        const SizedBox(height: 2),
                        Text(
                          '${_commas(totalPhotos)} photos → $albumCount smart albums',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const Text('✨', style: TextStyle(fontSize: 26)),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Smart albums header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SectionLabel('Smart albums'),
                Text('See all',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: BrandColors.coral)),
              ],
            ),
            const SizedBox(height: 12),

            albumsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load albums: $e'),
              data: (albums) => albums.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BrandColors.panel,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          Text('📷', style: TextStyle(fontSize: 30)),
                          SizedBox(height: 8),
                          Text('No albums yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                            'Connect a photo source to import and organize your memories.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: BrandColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      children: [
                        for (final a in albums)
                          AlbumCard(
                            album: a,
                            onTap: () => context.push('${Routes.album}/${a.id}'),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Gift CTA
            GestureDetector(
              onTap: () => context.go(Routes.gifts),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [BrandColors.coral, BrandColors.amber],
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎁 3 gift ideas ready',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          SizedBox(height: 3),
                          Text('AI designed these from your best shots',
                              style: TextStyle(color: Colors.white, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Text('→', style: TextStyle(color: Colors.white, fontSize: 22)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _commas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
