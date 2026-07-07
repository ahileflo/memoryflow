/// The signed-in user's profile and plan, shown on Home and Profile.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.planLabel,
    required this.isPremium,
    required this.totalPhotos,
    required this.albumCount,
  });

  final String name;
  final String email;

  /// e.g. "Free plan · 1 account".
  final String planLabel;
  final bool isPremium;

  final int totalPhotos;
  final int albumCount;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
