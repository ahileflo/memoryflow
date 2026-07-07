import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'widgets/phone_frame.dart';

/// Root widget. Wires the brand theme to the go_router configuration and wraps
/// every screen in the responsive [PhoneFrame] (centered phone on web/desktop,
/// full-screen on mobile).
class MemoryFlowApp extends ConsumerWidget {
  const MemoryFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MemoryFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
