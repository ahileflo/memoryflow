import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/product.dart';
import 'brand_button.dart';
import 'photo_tile.dart';

/// Gift-suggestion card used on the Gifts tab: 4:3 hero with a category tag,
/// name + description + price, and a "Preview & order" action.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductSuggestion product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = product.defaultSize.price;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: BrandColors.line),
          borderRadius: BorderRadius.circular(BrandRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PhotoTile(url: product.heroUrl, borderRadius: 0, width: double.infinity),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.tag,
                      style: const TextStyle(
                          color: BrandColors.violetDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              product.description,
                              style: const TextStyle(
                                  fontSize: 12.5, color: BrandColors.muted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '€${price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: BrandColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: 'Preview & order →',
                    style: BrandButtonStyle.ghost,
                    onPressed: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
