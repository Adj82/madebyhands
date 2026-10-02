/// Marketplace product categories.
///
/// Creators pick up to two of these when listing a product (stored in the
/// product's `categories` array) and buyers filter by the same names, so the
/// two sides always agree.
const List<String> kProductCategories = [
  'Paintings, Drawing, Fine Art & Traditional Art',
  'Digital Art, Illustration, Design & Photography',
  'Pottery, Ceramics, Clay & Sculpture',
  'Textile, Fiber, Embroidery, Toys & Dolls',
  'Fashion, Jewellery & Wearables',
  'Home Décor & Lifestyle',
  'Wood, Metal, Leather & Natural Crafts',
  'Paper, Books & Stationery',
  'Handicrafts & Artisan Goods',
  'Resin & Mixed-Material Art',
  'Other Creative Works',
];

/// The category that offers the "Is it framed?" question.
const String kPaintingCategory = 'Paintings, Drawing, Fine Art & Traditional Art';

/// Older listings stored short, free-form category names. These map them onto
/// the current categories so they still appear under the right filter.
const Map<String, List<String>> _legacyAliases = {
  'Paintings, Drawing, Fine Art & Traditional Art': [
    'painting', 'paintings', 'fine art', 'drawing', 'drawings', 'traditional art',
    'folk art', 'traditional and folk art', 'paintings and fine art',
  ],
  'Digital Art, Illustration, Design & Photography': [
    'digital art', 'digital design', 'illustration', 'illustrations', 'photography',
    'prints', 'digital art and design', 'drawings and illustrations', 'photography and prints',
  ],
  'Pottery, Ceramics, Clay & Sculpture': [
    'pottery', 'ceramics', 'ceramic', 'clay', 'sculpture', 'sculptures', 'figurines',
    'pottery ceramics and clay', 'sculptures and figurines',
  ],
  'Textile, Fiber, Embroidery, Toys & Dolls': [
    'textile', 'textiles', 'fiber art', 'fibre art', 'embroidery', 'toys', 'toy',
    'dolls', 'textile and fiber art', 'toys dolls and collectibles',
  ],
  'Fashion, Jewellery & Wearables': [
    'fashion', 'wearables', 'clothing', 'jewellery', 'jewelry', 'accessories',
    'fashion and wearables', 'jewellery and accessories',
  ],
  'Home Décor & Lifestyle': ['home decor', 'decor', 'home and living', 'home decor and living', 'lifestyle'],
  'Wood, Metal, Leather & Natural Crafts': [
    'wood', 'wooden', 'woodwork', 'bamboo', 'metal', 'leather', 'natural crafts',
    'wood bamboo and natural crafts',
  ],
  'Paper, Books & Stationery': ['paper', 'books', 'stationery', 'paper crafts', 'origami'],
  'Handicrafts & Artisan Goods': ['handicrafts', 'handicraft', 'artisan goods', 'handmade', 'gifts', 'gift', 'personalized'],
  'Resin & Mixed-Material Art': ['resin', 'mixed material art', 'mixed media', 'candles', 'candle making'],
  'Other Creative Works': ['other', 'wellness', 'other creative crafts'],
};

/// Lower-cases and strips punctuation so 'Home Décor' and 'home decor' match.
String normalizeCategory(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('é', 'e')
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

/// Whether a product tagged with [productCategories] belongs to [category].
bool productMatchesCategory(List<String> productCategories, String category) {
  final target = normalizeCategory(category);
  final aliases = (_legacyAliases[category] ?? const <String>[])
      .map(normalizeCategory)
      .toSet();
  for (final raw in productCategories) {
    final value = normalizeCategory(raw);
    if (value.isEmpty) continue;
    if (value == target || aliases.contains(value)) return true;
  }
  return false;
}
