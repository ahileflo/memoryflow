import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase only when the real backend is enabled. In the default
  // mock mode we skip this entirely, so the app runs with zero configuration.
  if (AppConfig.backendEnabled) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Publishable (anon) key — safe in the client; RLS protects the data.
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: MemoryFlowApp()));
}
