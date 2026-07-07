import 'models/connected_account.dart';

/// The static catalog of photo sources shown on the Connect screen.
///
/// Account `id`s match the `account_provider` enum in the database, so the
/// Supabase repository can map a connected row straight to a catalog entry.
/// Both `MockRepository` and `SupabaseRepository` build their account list
/// from this single source of truth.
List<ConnectedAccount> connectedAccountCatalog() => [
      ConnectedAccount(
        id: 'google_photos',
        name: 'Google Photos',
        subtitle: '~4,500 photos & videos',
        emoji: '📷',
        brandColor: 0xFF4285F4,
      ),
      ConnectedAccount(
        id: 'gmail',
        name: 'Gmail attachments',
        subtitle: 'Photos hiding in your inbox',
        emoji: '✉️',
        brandColor: 0xFFEA4335,
      ),
      ConnectedAccount(
        id: 'icloud',
        name: 'iCloud Photos',
        subtitle: 'Coming soon',
        emoji: '☁️',
        brandColor: 0xFFA2AAAD,
        comingSoon: true,
      ),
      ConnectedAccount(
        id: 'dropbox',
        name: 'Dropbox',
        subtitle: 'Coming soon',
        emoji: '📦',
        brandColor: 0xFF0061FF,
        comingSoon: true,
      ),
      ConnectedAccount(
        id: 'facebook',
        name: 'Facebook',
        subtitle: 'Coming soon',
        emoji: '📘',
        brandColor: 0xFF1877F2,
        comingSoon: true,
      ),
    ];
