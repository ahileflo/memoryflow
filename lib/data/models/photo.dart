/// A single photo in the user's library.
///
/// In Milestone 1 these are synthesized by the `MockRepository` using
/// placeholder image URLs. From Milestone 3 onward, [url] points at a thumbnail
/// in Supabase Storage and the AI fields ([qualityScore], [isBestShot]) are
/// computed server-side.
class Photo {
  const Photo({
    required this.id,
    required this.url,
    this.qualityScore = 0,
    this.isBestShot = false,
  });

  final String id;

  /// Thumbnail URL (placeholder in mock mode).
  final String url;

  /// 0..1 "best shot" score produced by the AI pipeline (Milestone 4).
  final double qualityScore;

  /// Whether the AI flagged this as one of the album's best shots.
  final bool isBestShot;
}
