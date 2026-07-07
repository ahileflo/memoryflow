import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/album.dart';
import 'photo_tile.dart';

/// Square album tile used in the Home grid: cover photo, category badge,
/// gradient scrim, title + photo count.
class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BrandRadius.card),
            boxShadow: softShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BrandRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoTile(url: album.coverUrl, borderRadius: 0),
                // bottom scrim
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD1141024)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Badge(album.badge),
                ),
                Positioned(
                  left: 13,
                  right: 13,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        album.photoCountLabel,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: BrandColors.violetDark, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
