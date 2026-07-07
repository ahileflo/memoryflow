/// Compile-time / run-time configuration flags.
///
/// Milestone 1 ships with [useMockData] = true so the entire UI runs with no
/// external accounts. Milestone 2 introduces a `SupabaseRepository` behind the
/// same [Repository] interface; flipping this flag (or wiring it to an
/// `--dart-define`) is all that's needed to switch data sources.
abstract final class AppConfig {
  /// When true, the app is served by the in-memory `MockRepository`.
  ///
  /// Can be overridden at build time:
  ///   flutter run -d chrome --dart-define=USE_MOCK_DATA=false
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  /// Supabase project URL + anon (publishable) key, injected at build time:
  ///   flutter run -d chrome --dart-define=USE_MOCK_DATA=false \
  ///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  ///
  /// The anon key is safe to ship in the client because Row Level Security
  /// protects the data. The service-role key is NEVER placed here.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether a Supabase project is configured.
  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// The app talks to the real backend only when mock mode is off AND a
  /// Supabase project is configured. Otherwise it stays fully mock so the UI
  /// always runs with no external accounts.
  static bool get backendEnabled => !useMockData && supabaseConfigured;

  /// Total photos in the demo library — drives the scan counter and the
  /// "created from N photos" viral share. Mirrors the prototype (4,532).
  static const int demoLibraryPhotoCount = 4532;

  /// Number of smart albums the AI "created" (shown on Home).
  static const int demoSmartAlbumCount = 18;
}
