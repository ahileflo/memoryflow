import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';

/// Order success + the viral "share how it was made" moment. Confetti bursts,
/// and "THE MAGIC" card reframes the purchase as "created from N photos
/// automatically" — the shareable hook.
class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key});

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..forward();
    // First-party analytics (no-op in mock mode).
    ref.read(repositoryProvider).logEvent('order_completed');
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _noun(String? type) {
    switch (type) {
      case 'canvas':
        return 'canvas';
      case 'book':
        return 'photo book';
      case 'mug':
        return 'mug';
      default:
        return 'gift';
    }
  }

  void _backToMemories() {
    // Reset the order flow so a fresh visit starts clean.
    ref.read(orderDraftProvider.notifier).state = null;
    ref.read(orderConfirmationProvider.notifier).state = null;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final confirmation = ref.watch(orderConfirmationProvider);
    final photoCount =
        confirmation?.createdFromPhotoCount ?? AppConfig.demoLibraryPhotoCount;
    final noun = _noun(confirmation?.draft.product.type);

    return Scaffold(
      backgroundColor: BrandColors.indigo,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: BrandColors.mint),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, color: Colors.white, size: 42),
                    ),
                    const SizedBox(height: 24),
                    const Text('Order placed!',
                        style: TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    const Text(
                      "Your gift is on its way. You'll get tracking by email.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFC9C4E4), fontSize: 15),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BrandColors.indigo2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('THE MAGIC',
                              style: TextStyle(
                                  color: BrandColors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 19, height: 1.4),
                              children: [
                                TextSpan(text: '“Your $noun was created from '),
                                TextSpan(
                                  text: '${_commas(photoCount)} photos',
                                  style: const TextStyle(
                                      color: BrandColors.amber, fontWeight: FontWeight.w800),
                                ),
                                const TextSpan(text: ' automatically.”'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          BrandButton(
                            label: '📤 Share how it was made',
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: BrandColors.ink,
                                  content: Text('✅ Shared! Your friends will be curious 👀'),
                                ));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    BrandButton(
                      label: 'Back to my memories',
                      style: BrandButtonStyle.transparent,
                      onPressed: _backToMemories,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Confetti overlay (non-interactive).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) =>
                    CustomPaint(painter: _ConfettiPainter(_confetti.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _commas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static const _colors = [
    BrandColors.coral,
    BrandColors.violet,
    BrandColors.amber,
    BrandColors.mint,
    Colors.white,
  ];

  // Deterministic pieces so the burst is stable across rebuilds.
  static final _pieces = List.generate(28, (i) {
    final r = math.Random(i * 7 + 3);
    return (
      x: r.nextDouble(),
      color: _colors[i % _colors.length],
      delay: r.nextDouble() * 0.25,
      duration: 0.55 + r.nextDouble() * 0.4,
      rot: r.nextDouble() * math.pi,
      rotSpeed: (r.nextDouble() * 2 - 1) * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final local = ((t - p.delay) / p.duration).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = (-20.0) + (size.height + 40) * Curves.easeIn.transform(local);
      final x = p.x * size.width;
      final paint = Paint()..color = p.color.withValues(alpha: 1 - local * 0.8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.rotSpeed * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4.5, -7, 9, 14),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
