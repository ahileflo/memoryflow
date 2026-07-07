import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_tile.dart';

/// Checkout: a clear "handed off to Gelato" banner, order summary, demo
/// shipping/payment, totals, and the pay button. In Milestone 5 the pay action
/// hands off to the print partner's hosted flow; here it records a mock order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _placing = false;

  Future<void> _pay() async {
    final draft = ref.read(orderDraftProvider);
    if (draft == null) return;
    setState(() => _placing = true);
    final repo = ref.read(repositoryProvider);
    final confirmation = await repo.placeOrder(draft);
    ref.read(orderConfirmationProvider.notifier).state = confirmation;
    if (mounted) context.push(Routes.success);
    if (mounted) setState(() => _placing = false);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderDraftProvider);

    if (draft == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your cart is empty.'),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: 'Back to gifts',
                    style: BrandButtonStyle.ghost,
                    onPressed: () => context.go(Routes.gifts),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final product = draft.product;
    final size = draft.size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: BrandColors.ink),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        // Partner handoff banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: BrandColors.panel,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '🤝 Securely handed off to Gelato — our print & shipping partner',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: BrandColors.violetDark,
                                fontWeight: FontWeight.w700,
                                height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Item row
                        Row(
                          children: [
                            PhotoTile(url: product.heroUrl, width: 70, height: 55),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text('${size.label} · ${product.tag}',
                                      style: const TextStyle(
                                          fontSize: 12.5, color: BrandColors.muted)),
                                ],
                              ),
                            ),
                            Text('€${size.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, color: BrandColors.ink)),
                          ],
                        ),
                        const Divider(height: 36),
                        const SectionLabel('Shipping to'),
                        const SizedBox(height: 12),
                        _BoxedRow(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 14, color: BrandColors.ink),
                              children: [
                                TextSpan(
                                    text: 'Ahile\n',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(
                                    text: '12 Rue des Souvenirs · 75011 Paris · FR',
                                    style: TextStyle(color: BrandColors.muted, height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Payment'),
                        const SizedBox(height: 12),
                        const _BoxedRow(
                          child: Row(
                            children: [
                              Text('💳', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 10),
                              Text('Visa ···· 4242', style: TextStyle(fontSize: 14)),
                              Spacer(),
                              Text('Edit',
                                  style: TextStyle(color: BrandColors.muted, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _TotalRow(label: 'Item', value: '€${size.price.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _TotalRow(
                            label: 'Shipping',
                            value: '€${draft.shipping.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            Text('€${draft.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: BrandColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BrandColors.line)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: _placing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : BrandButton(
                      label: 'Pay €${draft.total.toStringAsFixed(2)}',
                      style: BrandButtonStyle.dark,
                      onPressed: _pay,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxedRow extends StatelessWidget {
  const _BoxedRow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: BrandColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: BrandColors.muted, fontSize: 14.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
