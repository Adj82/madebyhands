/// Size limits applied when a photo is picked, before it is uploaded to
/// Firebase Storage. `image_picker` re-encodes the photo as a JPEG at
/// [kImageQuality] and scales it down so its longest side fits the limit; a
/// 12 MP phone photo (3–5 MB) comes out at roughly 150–400 KB.
const int kImageQuality = 75;

/// Avatars and portfolio pictures.
const double kProfileImageMaxSide = 1200;

/// Product and customization photos (shown full width on the product page).
const double kProductImageMaxSide = 1600;

/// Identity documents: kept larger so the text stays readable for review.
const double kDocumentImageMaxSide = 2000;
