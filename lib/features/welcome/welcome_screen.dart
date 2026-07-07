import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';

/// First screen. Photo mosaic, brand statement, and the "Get started" CTA.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _mosaic = [
    BrandColors.coral, BrandColors.violet, BrandColors.amber, BrandColors.mint,
    BrandColors.violet, BrandColors.amber, BrandColors.mint, BrandColors.coral,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.indigo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              _buildMosaic(),
              const SizedBox(height: 34),
              const Eyebrow('AI Memory Concierge'),
              const SizedBox(height: 14),
              const Text(
                'MemoryFlow',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Color(0xFFC9C4E4), fontSize: 16.5, height: 1.55),
                  children: [
                    TextSpan(
                        text:
                            'Your photos are scattered across a dozen apps. We organize them and turn them into '),
                    TextSpan(
                      text: 'albums, gifts and memories — automatically.',
                      style: TextStyle(color: BrandColors.amber, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              BrandButton(
                label: 'Get started →',
                onPressed: () => context.go(Routes.connect),
              ),
              const SizedBox(height: 12),
              BrandButton(
                label: 'I already have an account',
                style: BrandButtonStyle.transparent,
                onPressed: () => context.go(Routes.connect),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The decorative 4×2 photo-tile mosaic. Built from fixed-height rows (not a
  /// GridView) so it composes correctly inside the IntrinsicHeight used to pin
  /// the CTAs to the bottom while still allowing the screen to scroll.
  Widget _buildMosaic() {
    Widget tile(Color c) => Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    Widget mosaicRow(int start) => SizedBox(
          height: 80,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                tile(_mosaic[start + i]),
              ],
            ],
          ),
        );
    return Column(
      children: [
        mosaicRow(0),
        const SizedBox(height: 9),
        mosaicRow(4),
      ],
    );
  }
}
