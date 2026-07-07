import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// A signed-in user, decoupled from the Supabase SDK so the rest of the app
/// doesn't depend on it directly.
class AuthUser {
  const AuthUser({required this.id, this.email});
  final String id;
  final String? email;
}

/// Authentication contract. Implemented by [SupabaseAuthService] (real) and
/// [MockAuthService] (no-op, always "signed in") so mock mode never gates.
abstract interface class AuthService {
  /// Emits the current user (or null when signed out) and on every change.
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);

  /// OAuth sign-in with Google (sign-in identity only; Photos/Gmail read
  /// scopes are requested later at import time — Milestone 3).
  Future<void> signInWithGoogle();

  Future<void> signOut();
}

/// Mock auth used whenever the backend is disabled. There is always a fake
/// user, so the app behaves exactly like Milestone 1 (no sign-in gate).
class MockAuthService implements AuthService {
  static const _user = AuthUser(id: 'mock-user', email: 'woopsahile@gmail.com');

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(_user);

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signUpWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

/// Real authentication backed by Supabase Auth.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService() : _client = sb.Supabase.instance.client;

  final sb.SupabaseClient _client;

  AuthUser? _map(sb.User? u) => u == null ? null : AuthUser(id: u.id, email: u.email);

  @override
  AuthUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((event) => _map(event.session?.user));

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Redirect-based OAuth (works on web; uses the configured redirect URLs).
    await _client.auth.signInWithOAuth(sb.OAuthProvider.google);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
