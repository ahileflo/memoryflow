import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_tile.dart';

/// Product Detail / customize: a framed preview, size options, and the order
/// CTA. Selecting a size updates the live total. Ordering writes an [OrderDraft]
/// and continues to checkout.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: productAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load product: $e')),
          data: (product) {
            final selected = _selectedIndex ?? product.defaultSizeIndex;
            final size = product.sizes[selected];
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14, top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back, color: BrandColors.ink),
                          ),
                        ),
                      ),
                      _FramedPreview(url: product.heroUrl),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BrandChip('✨ AI-designed layout'),
                            const SizedBox(height: 10),
                            Text(product.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(product.description,
                                style: const TextStyle(
                                    color: BrandColors.muted, fontSize: 14.5, height: 1.5)),
                            const SizedBox(height: 20),
                            const SectionLabel('Choose a size'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (var i = 0; i < product.sizes.length; i++) ...[
                                  Expanded(
                                    child: _SizeOption(
                                      size: product.sizes[i],
                                      selected: i == selected,
                                      onTap: () => setState(() => _selectedIndex = i),
                                    ),
                                  ),
                                  if (i != product.sizes.length - 1) const SizedBox(width: 9),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _OrderBar(
                  product: product,
                  size: size,
                  onOrder: () {
                    ref.read(orderDraftProvider.notifier).state =
                        OrderDraft(product: product, size: size);
                    context.push(Routes.checkout);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FramedPreview extends StatelessWidget {
  const _FramedPreview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: BrandColors.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.026, // ~ -1.5deg, the prototype's tilt
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: softShadow(opacity: 0.22),
              ),
              child: PhotoTile(url: url, width: 210, height: 158, borderRadius: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({required this.size, required this.selected, required this.onTap});
  final ProductSize size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4F0) : Colors.white,
          border: Border.all(
            color: selected ? BrandColors.coral : BrandColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              size.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? BrandColors.coral : BrandColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text('€${size.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: BrandColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _OrderBar extends StatelessWidget {
  const _OrderBar({required this.product, required this.size, required this.onOrder});
  final ProductSuggestion product;
  final ProductSize size;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BrandColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(color: BrandColors.muted, fontSize: 14.5)),
              Text('€${size.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: BrandColors.ink)),
            ],
          ),
          const SizedBox(height: 12),
          BrandButton(label: 'Order this gift →', onPressed: onOrder),
          const SizedBox(height: 9),
          const Text('Fulfilled & shipped by our print partner',
              style: TextStyle(fontSize: 11.5, color: BrandColors.muted)),
        ],
      ),
    );
  }
}
