import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/product_review.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool isSaved;
  final int cartQuantity;
  final int cartCount;
  final VoidCallback onSave;
  final ValueChanged<int> onCartQuantityChanged;
  final VoidCallback onOpenCart;
  final VoidCallback onBuyNow;
  final BuyerRepository buyerRepository;
  final String buyerId;
  final String buyerName;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.isSaved,
    required this.cartQuantity,
    required this.cartCount,
    required this.onSave,
    required this.onCartQuantityChanged,
    required this.onOpenCart,
    required this.onBuyNow,
    required this.buyerRepository,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late bool _isSaved = widget.isSaved;
  late Future<ProductReviewEligibility> _reviewEligibility;

  @override
  void initState() {
    super.initState();
    _reviewEligibility = _loadReviewEligibility();
  }

  Future<ProductReviewEligibility> _loadReviewEligibility() =>
      widget.buyerRepository.getProductReviewEligibility(
        buyerId: widget.buyerId,
        productId: widget.product.id,
      );

  @override
  void didUpdateWidget(covariant ProductDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _isSaved = widget.isSaved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Open cart',
            onPressed: widget.onOpenCart,
            icon: Badge(
              isLabelVisible: widget.cartCount > 0,
              label: Text('${widget.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: _isSaved ? 'Remove from saved' : 'Save item',
            onPressed: () {
              widget.onSave();
              setState(() => _isSaved = !_isSaved);
            },
            icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
            color: _isSaved ? Colors.redAccent : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                product.icon,
                size: 112,
                color: AppColors.text.withValues(alpha: 0.62),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFE0A72F)),
              Text(
                '${product.rating}  ·  Made by ${product.artisan}',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '₹${product.price}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 22),
          const Text(
            'About this piece',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 22),
          const _DetailLine(
            icon: Icons.handyman_outlined,
            text: 'Handmade in India',
          ),
          const _DetailLine(
            icon: Icons.inventory_2_outlined,
            text: 'Plastic-conscious packaging',
          ),
          const _DetailLine(
            icon: Icons.local_shipping_outlined,
            text: 'Estimated delivery in 4–7 days',
          ),
          const SizedBox(height: 20),
          _ProductReviewsSection(
            product: product,
            buyerId: widget.buyerId,
            buyerName: widget.buyerName,
            repository: widget.buyerRepository,
            eligibility: _reviewEligibility,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: widget.cartQuantity == 0
                  ? OutlinedButton.icon(
                      onPressed: () {
                        widget.onCartQuantityChanged(1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to cart'),
                    )
                  : Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: 'Decrease quantity',
                            onPressed: () => widget.onCartQuantityChanged(
                              widget.cartQuantity - 1,
                            ),
                            icon: const Icon(Icons.remove),
                            color: AppColors.primary,
                          ),
                          Text(
                            '${widget.cartQuantity}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Increase quantity',
                            onPressed: () => widget.onCartQuantityChanged(
                              widget.cartQuantity + 1,
                            ),
                            icon: const Icon(Icons.add),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onBuyNow,
                icon: const Icon(Icons.bolt),
                label: Text(
                  'Buy now  ·  ₹${product.price * (widget.cartQuantity == 0 ? 1 : widget.cartQuantity)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductReviewsSection extends StatelessWidget {
  final Product product;
  final String buyerId;
  final String buyerName;
  final BuyerRepository repository;
  final Future<ProductReviewEligibility> eligibility;

  const _ProductReviewsSection({
    required this.product,
    required this.buyerId,
    required this.buyerName,
    required this.repository,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductReview>>(
      stream: repository.watchProductReviews(product.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ProductReview>[];
        final ownReview = reviews.where((review) => review.buyerId == buyerId);
        final average = reviews.isEmpty
            ? product.rating
            : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                  reviews.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reviews & ratings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.star_rounded, color: Color(0xFFE0A72F)),
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${reviews.length})',
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<ProductReviewEligibility>(
              future: eligibility,
              builder: (context, eligibilitySnapshot) {
                if (eligibilitySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final result = eligibilitySnapshot.data;
                if (result?.canReview == true) {
                  return OutlinedButton.icon(
                    onPressed: () => _openReviewEditor(
                      context,
                      existing: ownReview.isEmpty ? null : ownReview.first,
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(
                      ownReview.isEmpty ? 'Write a review' : 'Edit your review',
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result?.message ??
                            'Could not verify your purchase right now.',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (snapshot.hasError)
              const Text(
                'Reviews are unavailable right now.',
                style: TextStyle(color: AppColors.mutedText),
              )
            else if (reviews.isEmpty)
              const Text(
                'No reviews yet. Verified buyers can be the first to review.',
                style: TextStyle(color: AppColors.mutedText),
              )
            else
              ...reviews.map((review) => _ReviewCard(review: review)),
          ],
        );
      },
    );
  }

  Future<void> _openReviewEditor(
    BuildContext context, {
    ProductReview? existing,
  }) async {
    var selectedRating = existing?.rating ?? 0;
    var isSaving = false;
    var reviewText = existing?.comment ?? '';
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Write a review' : 'Edit your review',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verified purchase',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value stars',
                      onPressed: isSaving
                          ? null
                          : () => setSheetState(() => selectedRating = value),
                      icon: Icon(
                        value <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFE0A72F),
                      ),
                    );
                  }),
                ),
                TextFormField(
                  initialValue: reviewText,
                  onChanged: (value) => reviewText = value,
                  enabled: !isSaving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    hintText: 'What did you like about this product?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final comment = reviewText.trim();
                            if (selectedRating == 0 || comment.length < 3) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Select a rating and write at least 3 characters.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              await repository.submitProductReview(
                                buyerId: buyerId,
                                buyerName: buyerName,
                                productId: product.id,
                                rating: selectedRating,
                                comment: comment,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existing == null
                                        ? 'Review submitted'
                                        : 'Review updated',
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (sheetContext.mounted) {
                                setSheetState(() => isSaving = false);
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not save review: ${_messageFor(error)}',
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(isSaving ? 'Saving…' : 'Submit review'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _messageFor(Object error) => error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '');
}

class _ReviewCard extends StatelessWidget {
  final ProductReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.buyerName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ...List.generate(
              5,
              (index) => Icon(
                index < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 17,
                color: const Color(0xFFE0A72F),
              ),
            ),
          ],
        ),
        if (review.verifiedPurchase) ...[
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.verified, size: 16, color: AppColors.primary),
              SizedBox(width: 5),
              Text(
                'Verified purchase',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Text(review.comment, style: const TextStyle(height: 1.4)),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 21, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(text),
      ],
    ),
  );
}
