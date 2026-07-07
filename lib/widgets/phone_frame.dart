import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Wraps the whole app. On phones it fills the screen (true mobile-first).
/// On wide screens (web/desktop) it presents the app inside a centered phone
/// frame on a dark backdrop — echoing the approved HTML prototype's preview.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double _frameWidth = 412;
  static const double _breakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= _breakpoint;

    if (!isWide) {
      return child;
    }

    final frameHeight = (size.height - 64).clamp(560.0, 900.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -1.1),
          radius: 1.4,
          colors: [Color(0xFF2A2150), BrandColors.bg],
          stops: [0.0, 0.6],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: const Color(0xFF2A2342), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 80,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery(
                // Inside the frame, the app should believe it's a phone.
                data: MediaQuery.of(context).copyWith(
                  size: Size(_frameWidth, frameHeight),
                ),
                child: child,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'MemoryFlow · clickable prototype · mock data',
              style: TextStyle(color: Color(0xFFB9B3D6), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
