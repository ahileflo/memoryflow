import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Early-access email capture, used by the public demo.
///
/// Talks straight to Supabase REST with the publishable key (safe in the
/// client). The `waitlist` table is INSERT-only for anon — nobody can read it
/// back through the API, so the list stays private. Works even in mock mode:
/// it only needs the URL + key to be compiled in, not the full backend flag.
abstract final class WaitlistService {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool get available => AppConfig.supabaseConfigured;

  static bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());

  /// Returns true when the email is on the list (newly added OR already there).
  static Future<bool> join(String email, {String source = 'web-demo'}) async {
    if (!available || !isValidEmail(email)) return false;
    final res = await http.post(
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/waitlist'),
      headers: {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({'email': email.trim().toLowerCase(), 'source': source}),
    );
    // 201 = added; 409 = duplicate (already on the list) — both are success.
    return res.statusCode == 201 || res.statusCode == 409;
  }
}
