import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A network photo with the brand "photo tile" look: rounded corners, a
/// violet→coral gradient placeholder while loading, and a graceful gradient
/// fallback if the image fails (so the demo never shows broken images).
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = BrandRadius.tile,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.violet, BrandColors.coral],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(gradient: _gradient),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(gradient: _gradient),
        ),
      ),
    );
  }
}
