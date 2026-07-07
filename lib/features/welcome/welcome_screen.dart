import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/waitlist_service.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';

/// First screen. Photo mosaic, brand statement, the "Get started" CTA, and —
/// when a Supabase project is compiled in — an early-access email capture that
/// feeds the waitlist (the public demo's conversion point).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _mosaic = [
    BrandColors.coral, BrandColors.violet, BrandColors.amber, BrandColors.mint,
    BrandColors.violet, BrandColors.amber, BrandColors.mint, BrandColors.coral,
  ];

  final _email = TextEditingController();
  bool _joining = false;
  bool _joined = false;
  String? _waitlistError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final email = _email.text.trim();
    if (!WaitlistService.isValidEmail(email)) {
      setState(() => _waitlistError = 'Please enter a valid email');
      return;
    }
    setState(() {
      _joining = true;
      _waitlistError = null;
    });
    bool ok = false;
    try {
      ok = await WaitlistService.join(email);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _joining = false;
      _joined = ok;
      if (!ok) _waitlistError = 'Could not join right now — try again in a minute';
    });
  }

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
                          style: TextStyle(
                              color: Color(0xFFC9C4E4), fontSize: 16.5, height: 1.55),
                          children: [
                            TextSpan(
                                text:
                                    'Your photos are scattered across a dozen apps. We organize them and turn them into '),
                            TextSpan(
                              text: 'albums, gifts and memories — automatically.',
                              style: TextStyle(
                                  color: BrandColors.amber, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      BrandButton(
                        label: 'Try the demo →',
                        onPressed: () => context.go(Routes.connect),
                      ),
                      if (WaitlistService.available) ...[
                        const SizedBox(height: 18),
                        _buildWaitlist(),
                      ] else ...[
                        const SizedBox(height: 12),
                        BrandButton(
                          label: 'I already have an account',
                          style: BrandButtonStyle.transparent,
                          onPressed: () => context.go(Routes.connect),
                        ),
                      ],
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

  /// Early-access capture: email field + join button, feeding the waitlist.
  Widget _buildWaitlist() {
    if (_joined) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BrandColors.indigo2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅ ', style: TextStyle(fontSize: 16)),
            Flexible(
              child: Text(
                "You're on the list — we'll email you at launch!",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '🔔 Want the real thing? Get early access:',
          style: TextStyle(color: Color(0xFF9A95B5), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                onSubmitted: (_) => _join(),
                decoration: InputDecoration(
                  hintText: 'you@email.com',
                  hintStyle: const TextStyle(color: Color(0xFF7A7690)),
                  filled: true,
                  fillColor: BrandColors.indigo2,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF3A3460)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BrandColors.violet, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 86,
              child: _joining
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : BrandButton(label: 'Join', onPressed: _join),
            ),
          ],
        ),
        if (_waitlistError != null) ...[
          const SizedBox(height: 8),
          Text(_waitlistError!,
              style: const TextStyle(color: BrandColors.coral, fontSize: 12.5)),
        ],
      ],
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
