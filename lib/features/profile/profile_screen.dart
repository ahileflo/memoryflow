import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';

/// Profile tab: identity, the €4.99/mo Premium upsell, AI-credit balance +
/// paywalled tools, the referral loop, connected accounts, and sign-out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BrandColors.ink,
        content: Text(msg),
      ));
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final state = await repo.subscribe();
    if (state.checkoutUrl != null) {
      if (context.mounted) _toast(context, 'Opening secure checkout…'); // real Stripe path
      return;
    }
    ref.invalidate(billingStatusProvider);
    ref.invalidate(profileProvider);
    if (context.mounted) _toast(context, '✨ Premium active — enjoy unlimited AI');
  }

  Future<void> _buyCredits(BuildContext context, WidgetRef ref) async {
    final balance = await ref.read(repositoryProvider).buyCredits(50);
    ref.invalidate(billingStatusProvider);
    if (context.mounted) _toast(context, 'Added 50 credits · balance $balance');
  }

  Future<void> _enhance(BuildContext context, WidgetRef ref) async {
    final res = await ref.read(repositoryProvider).spendCredit('enhance');
    ref.invalidate(billingStatusProvider);
    if (!context.mounted) return;
    if (res.ok) {
      _toast(context, '🪄 Enhanced! ${res.balance} credits left');
    } else {
      _toast(context, 'Out of credits — buy more or go Premium');
    }
  }

  Future<void> _reorganizeAI(BuildContext context, WidgetRef ref) async {
    _toast(context, 'Re-organizing with AI…');
    final repo = ref.read(repositoryProvider);
    try {
      final albums = await repo.organize(mode: 'ai');
      final gifts = await repo.generateSuggestions(mode: 'ai');
      ref.invalidate(albumsProvider);
      ref.invalidate(suggestionsProvider);
      ref.invalidate(profileProvider);
      if (context.mounted) {
        _toast(context, '✨ Refreshed: $albums albums · $gifts gift ideas');
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'Re-organize failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final billingAsync = ref.watch(billingStatusProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load profile: $e')),
          data: (profile) {
            final isPremium = billingAsync.maybeWhen(
              data: (b) => b.isPremium,
              orElse: () => profile.isPremium,
            );
            final credits = billingAsync.maybeWhen(data: (b) => b.balance, orElse: () => 0);

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              children: [
                // Identity
                Column(
                  children: [
                    BrandAvatar(initial: profile.initial, size: 74),
                    const SizedBox(height: 14),
                    Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(profile.email,
                        style: const TextStyle(color: BrandColors.muted, fontSize: 14.5)),
                    const SizedBox(height: 12),
                    BrandChip(
                      isPremium ? 'Premium · unlimited' : 'Free plan · 1 account',
                      background: isPremium ? const Color(0xFFF0FBF9) : const Color(0xFFFFF4F0),
                      foreground: isPremium ? BrandColors.mint : BrandColors.coral,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Premium / subscription
                if (isPremium)
                  const _Card(
                    gradient: [BrandColors.mint, BrandColors.violet],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Premium is active ✨',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Unlimited accounts · full AI organization · family sharing · AI restore & enhance.',
                            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  )
                else
                  _Card(
                    gradient: const [BrandColors.violet, BrandColors.violetDark],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Go Premium — €4.99/mo',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          'Unlimited accounts · full AI organization · family sharing · AI restore & enhance.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 150,
                          child: BrandButton(
                            label: 'Upgrade',
                            style: BrandButtonStyle.ghost,
                            onPressed: () => _upgrade(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // AI tools + credits
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BrandColors.panel,
                    borderRadius: BorderRadius.circular(BrandRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI tools',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          BrandChip(
                            isPremium ? 'Unlimited' : '$credits credits',
                            foreground: BrandColors.violetDark,
                            background: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enhance, restore and remove backgrounds. Premium is unlimited; free uses 1 credit each.',
                        style: TextStyle(color: BrandColors.muted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BrandButton(
                              label: '🪄 Enhance (1)',
                              style: BrandButtonStyle.dark,
                              onPressed: () => _enhance(context, ref),
                            ),
                          ),
                          if (!isPremium) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: BrandButton(
                                label: 'Buy 50',
                                style: BrandButtonStyle.ghost,
                                onPressed: () => _buyCredits(context, ref),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (AppConfig.backendEnabled) ...[
                        const SizedBox(height: 10),
                        BrandButton(
                          label: '✨ Re-organize with AI',
                          style: BrandButtonStyle.ghost,
                          onPressed: () => _reorganizeAI(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Referral / viral loop
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BrandRadius.card),
                    gradient: const LinearGradient(
                      colors: [BrandColors.coral, BrandColors.amber],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invite a friend, get a free month',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'memoryflow.app/r/${profile.name.toLowerCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 150,
                        child: BrandButton(
                          label: '📤 Share link',
                          style: BrandButtonStyle.ghost,
                          onPressed: () =>
                              _toast(context, 'Referral link copied — share away! 👀'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                const SectionLabel('Connected accounts'),
                const SizedBox(height: 6),
                const _AccountRow(
                  emoji: '📷',
                  name: 'Google Photos',
                  trailing: BrandChip('Active',
                      background: Color(0xFFF0FBF9), foreground: BrandColors.mint),
                  showDivider: true,
                ),
                _AccountRow(
                  emoji: '✉️',
                  name: 'Gmail',
                  trailing: GestureDetector(
                    onTap: () => _toast(context, 'Real OAuth lands in Milestone 3'),
                    child: const Text('Connect',
                        style: TextStyle(color: BrandColors.muted, fontSize: 14)),
                  ),
                  showDivider: false,
                ),
                if (AppConfig.backendEnabled) ...[
                  const SizedBox(height: 24),
                  BrandButton(
                    label: 'Sign out',
                    style: BrandButtonStyle.ghost,
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.gradient, required this.child});
  final List<Color> gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: child,
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.emoji,
    required this.name,
    required this.trailing,
    required this.showDivider,
  });

  final String emoji;
  final String name;
  final Widget trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: BrandColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontSize: 14.5)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
