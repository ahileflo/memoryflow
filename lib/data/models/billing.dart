/// Subscription + AI-credit state for the signed-in user.
class BillingState {
  const BillingState({
    required this.plan,
    required this.isPremium,
    required this.balance,
    this.checkoutUrl,
  });

  final String plan; // 'free' | 'premium'
  final bool isPremium;
  final int balance; // AI credits

  /// Set when a real Stripe checkout must be opened (null in mock activation).
  final String? checkoutUrl;

  factory BillingState.fromMap(Map<String, dynamic> m) => BillingState(
        plan: (m['plan'] as String?) ?? 'free',
        isPremium: (m['isPremium'] as bool?) ?? ((m['plan'] as String?) == 'premium'),
        balance: (m['balance'] as int?) ?? 0,
        checkoutUrl: m['url'] as String?,
      );
}

/// Result of spending an AI credit on a paywalled tool.
class SpendResult {
  const SpendResult({required this.ok, required this.balance, this.needCredits = false});
  final bool ok;
  final int balance;
  final bool needCredits;
}
