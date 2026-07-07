/// A photo source the user can link on the Connect screen.
///
/// Milestone 1 toggles these in memory only. Milestone 3 wires Google Photos
/// and Gmail to real, read-only OAuth handled server-side.
class ConnectedAccount {
  ConnectedAccount({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.brandColor,
    this.comingSoon = false,
    this.connected = false,
  });

  /// gphotos | gmail | icloud | dropbox | facebook.
  final String id;
  final String name;
  final String subtitle;

  /// Emoji/glyph stand-in for the provider logo (matches the prototype).
  final String emoji;

  /// ARGB value for the provider logo background tile.
  final int brandColor;

  /// "Coming soon" providers are shown disabled with a SOON lock.
  final bool comingSoon;

  /// Whether the user has linked this source (mock state in Milestone 1).
  bool connected;
}
