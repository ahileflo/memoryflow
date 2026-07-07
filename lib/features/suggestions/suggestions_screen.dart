import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

/// Gifts tab: AI-designed product suggestions generated from the top albums.
class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            const Eyebrow('Made for you'),
            const SizedBox(height: 8),
            Text('Gift ideas from your photos',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Our AI designed these automatically. Tap to preview & order — your print partner ships it.',
              style: TextStyle(color: BrandColors.muted, fontSize: 14.5, height: 1.5),
            ),
            const SizedBox(height: 18),
            suggestionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load gift ideas: $e'),
              data: (products) => products.isEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BrandColors.panel,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          Text('🎁', style: TextStyle(fontSize: 30)),
                          SizedBox(height: 8),
                          Text('No gift ideas yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                            'Import and organize some photos — we’ll design gifts from your best albums.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: BrandColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (final p in products) ...[
                          ProductCard(
                            product: p,
                            onTap: () => context.push('${Routes.product}/${p.id}'),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
