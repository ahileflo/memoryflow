import 'photo.dart';

/// A smart album — a cluster of photos the AI grouped into an event, trip,
/// person or pet (Milestone 4 produces these for real).
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.badge,
    required this.photoCount,
    required this.bestShotCount,
    required this.coverUrl,
    required this.heroUrl,
    required this.bestShots,
  });

  final String id;
  final String title;

  /// Short category label shown as an overlay badge (Trip, People, Pet…).
  final String badge;

  final int photoCount;
  final int bestShotCount;

  /// Square cover used in the Home grid.
  final String coverUrl;

  /// Wide hero used on the Album Detail screen.
  final String heroUrl;

  /// The curated "best of this album" thumbnails.
  final List<Photo> bestShots;

  String get photoCountLabel => '$photoCount photos';
  String get detailCountLabel => '$photoCount photos · $bestShotCount best shots';
}
