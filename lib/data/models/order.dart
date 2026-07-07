import 'product.dart';

/// A draft order assembled on the product screen and confirmed at checkout.
class OrderDraft {
  const OrderDraft({required this.product, required this.size});

  final ProductSuggestion product;
  final ProductSize size;

  double get itemPrice => size.price;

  /// Flat demo shipping fee (mirrors the prototype's €4.90).
  double get shipping => 4.90;

  double get total => itemPrice + shipping;
}

/// The result of placing an order. In Milestone 5 this is created against the
/// Gelato API and persisted in our DB; here it's synthesized locally.
class OrderConfirmation {
  const OrderConfirmation({
    required this.orderId,
    required this.draft,
    required this.createdFromPhotoCount,
  });

  final String orderId;
  final OrderDraft draft;
  final int createdFromPhotoCount;
}
