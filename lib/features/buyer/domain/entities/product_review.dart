class ProductReview {
  final String id;
  final String buyerId;
  final String buyerName;
  final int rating;
  final String comment;
  final bool verifiedPurchase;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductReview({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.comment,
    required this.verifiedPurchase,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ProductReviewEligibility {
  final bool canReview;
  final String? orderId;
  final String message;

  const ProductReviewEligibility._({
    required this.canReview,
    required this.orderId,
    required this.message,
  });

  const ProductReviewEligibility.eligible(String orderId)
    : this._(canReview: true, orderId: orderId, message: '');

  const ProductReviewEligibility.ineligible()
    : this._(
        canReview: false,
        orderId: null,
        message: 'You can review this product after a delivered purchase.',
      );
}
