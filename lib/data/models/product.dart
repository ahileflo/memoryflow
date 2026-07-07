/// A purchasable size/variant of a product, with its price in EUR.
class ProductSize {
  const ProductSize(this.label, this.price);

  /// e.g. "40×30", "28 pages", "Standard".
  final String label;

  /// Price in EUR for this size.
  final double price;
}

/// An AI-designed product suggestion built from a top album
/// (canvas, photo book, mug…). Milestone 5 generates the copy via Claude and
/// fulfills via the Gelato `PrintPartner` abstraction.
class ProductSuggestion {
  const ProductSuggestion({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.tag,
    required this.heroUrl,
    required this.sizes,
    required this.sourceAlbumId,
    required this.createdFromPhotoCount,
    this.defaultSizeIndex = 0,
  });

  final String id;

  /// canvas | book | mug — maps to a Gelato product category later.
  final String type;

  final String name;
  final String description;

  /// Short category chip ("Wall canvas", "Photo book", "Gift").
  final String tag;

  final String heroUrl;

  /// Available sizes; [defaultSizeIndex] is pre-selected on the product screen.
  final List<ProductSize> sizes;
  final int defaultSizeIndex;

  /// The album this gift was generated from.
  final String sourceAlbumId;

  /// How many source photos contributed — drives the viral "created from N" line.
  final int createdFromPhotoCount;

  ProductSize get defaultSize => sizes[defaultSizeIndex];
}
