import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/product_review.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool isSaved;
  final int cartQuantity;
  final int cartCount;
  final VoidCallback onSave;
  final ValueChanged<int> onCartQuantityChanged;
  final VoidCallback onOpenCart;
  final ValueChanged<ProductCustomizationSelection> onBuyNow;
  final ProductCustomizationSelection customizationSelection;
  final ValueChanged<ProductCustomizationSelection> onCustomizationChanged;
  final BuyerRepository buyerRepository;
  final String buyerId;
  final String buyerName;
  final VoidCallback? onCreatorTap;

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
    this.customizationSelection = const ProductCustomizationSelection(),
    required this.onCustomizationChanged,
    required this.buyerRepository,
    required this.buyerId,
    required this.buyerName,
    this.onCreatorTap,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late bool _isSaved = widget.isSaved;
  late Future<ProductReviewEligibility> _reviewEligibility;
  late Map<String, List<String>> _customizationValues;

  @override
  void initState() {
    super.initState();
    _reviewEligibility = _loadReviewEligibility();
    _customizationValues = {
      for (final entry in widget.customizationSelection.values.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  Future<ProductReviewEligibility> _loadReviewEligibility() =>
      widget.buyerRepository.getProductReviewEligibility(
        buyerId: widget.buyerId,
        productId: widget.product.id,
      );

  ProductCustomizationSelection get _customizationSelection {
    final values = <String, List<String>>{
      for (final entry in _customizationValues.entries)
        if (entry.value.any((value) => value.trim().isNotEmpty))
          entry.key: entry.value
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
    };
    final additionalPrice = widget.product.customizations
        .where((customization) => values.containsKey(customization.name))
        .fold<int>(
          0,
          (total, customization) => total + customization.additionalPrice,
        );
    return ProductCustomizationSelection(
      values: values,
      additionalPrice: additionalPrice,
    );
  }

  void _updateCustomization(String name, List<String> values) {
    setState(() {
      if (values.every((value) => value.trim().isEmpty)) {
        _customizationValues.remove(name);
      } else {
        _customizationValues[name] = values;
      }
    });
    widget.onCustomizationChanged(_customizationSelection);
  }

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
    final customizationSelection = _customizationSelection;
    final unitPrice = customizationSelection.unitPriceFor(product);

    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Product details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          actions: [
            IconButton(
              tooltip: 'Open cart',
              onPressed: widget.onOpenCart,
              icon: Badge(
                isLabelVisible: widget.cartCount > 0,
                label: Text('${widget.cartCount}'),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF8B261D),
                ),
              ),
            ),
            IconButton(
              tooltip: _isSaved ? 'Remove from saved' : 'Save item',
              onPressed: () {
                widget.onSave();
                setState(() => _isSaved = !_isSaved);
              },
              icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
              color: const Color(0xFF8B261D),
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
                color: Color(0xFF8B261D),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1810),
                  ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: widget.onCreatorTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFE0A72F)),
                    Expanded(
                      child: Text(
                        '${product.rating}  ·  Made by ${product.artisan}',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                    if (widget.onCreatorTap != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFF8B261D),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$unitPrice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8B261D),
                      ),
                ),
                if (customizationSelection.additionalPrice > 0) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'includes ₹${customizationSelection.additionalPrice} customization',
                      style: const TextStyle(
                        color: Color(0xFF8B261D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'About this piece',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B261D),
              ),
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
            if (product.materials.isNotEmpty ||
                product.dimensions.isNotEmpty ||
                product.shippingInfo.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'Product information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B261D),
                ),
              ),
              const SizedBox(height: 8),
              if (product.materials.isNotEmpty)
                _DetailLine(
                  icon: Icons.texture,
                  text: 'Materials: ${product.materials}',
                ),
              if (product.dimensions.isNotEmpty)
                _DetailLine(
                  icon: Icons.straighten,
                  text: 'Dimensions: ${product.dimensions}',
                ),
              if (product.shippingInfo.isNotEmpty)
                _DetailLine(
                  icon: Icons.local_shipping_outlined,
                  text: product.shippingInfo,
                ),
            ],
            if (product.isCustomizable &&
                (product.predefinedCustomizations.isNotEmpty ||
                    product.customizations.isNotEmpty)) ...[
              const SizedBox(height: 24),
              _ProductCustomizationSection(
                product: product,
                values: _customizationValues,
                onChanged: _updateCustomization,
              ),
            ],
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
        bottomNavigationBar: Container(
          color: const Color(0xFFFAF6EE),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: !product.isAvailable || product.stock <= 0
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon:
                              const Icon(Icons.remove_shopping_cart_outlined),
                          label: const Text('Out of stock'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF8B261D),
                              width: 1.2,
                            ),
                            foregroundColor: const Color(0xFF8B261D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                      : widget.cartQuantity == 0
                      ? OutlinedButton.icon(
                          onPressed: () {
                            widget.onCartQuantityChanged(1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF8B261D),
                              width: 1.5,
                            ),
                            foregroundColor: const Color(0xFF8B261D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Color(0xFF8B261D),
                          ),
                          label: const Text(
                            'Add to cart',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B261D),
                            ),
                          ),
                        )
                      : Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B261D),
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
                                color: const Color(0xFF8B261D),
                              ),
                              Text(
                                '${widget.cartQuantity}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8B261D),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase quantity',
                                onPressed:
                                    widget.cartQuantity >= product.stock
                                        ? null
                                        : () => widget.onCartQuantityChanged(
                                            widget.cartQuantity + 1,
                                          ),
                                icon: const Icon(Icons.add),
                                color: const Color(0xFF8B261D),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !product.isAvailable || product.stock <= 0
                        ? null
                        : () => widget.onBuyNow(customizationSelection),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B261D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.bolt),
                    label: Text(
                      'Buy now  ·  ₹${unitPrice * (widget.cartQuantity == 0 ? 1 : widget.cartQuantity)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCustomizationSection extends StatelessWidget {
  final Product product;
  final Map<String, List<String>> values;
  final void Function(String name, List<String> values) onChanged;

  const _ProductCustomizationSection({
    required this.product,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF8B261D).withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF8B261D)),
                SizedBox(width: 10),
                Text(
                  'Customize this product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B261D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Selections are optional and will be shared with the creator.',
              style: TextStyle(color: AppColors.mutedText),
            ),
            if (product.predefinedCustomizations.isNotEmpty) ...[
              const SizedBox(height: 18),
              ...product.predefinedCustomizations.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    key: ValueKey('predefined-${product.id}-$name'),
                    initialValue: values[name]?.firstOrNull ?? '',
                    onChanged: (value) => onChanged(name, [value]),
                    decoration: InputDecoration(
                      labelText: name,
                      hintText: _hintFor(name),
                      prefixIcon: Icon(_iconFor(name), color: const Color(0xFF8B261D)),
                    ),
                  ),
                ),
              ),
            ],
            ...product.customizations.map(
              (customization) => _CustomizationChoice(
                customization: customization,
                selectedValues: values[customization.name] ?? const [],
                onChanged: (selection) =>
                    onChanged(customization.name, selection),
              ),
            ),
          ],
        ),
      );

  static String _hintFor(String name) => switch (name.toLowerCase()) {
        'name/text' => 'Enter the name or text you want',
        'color' => 'Enter your preferred colour',
        'size' => 'Enter your preferred size',
        'design' => 'Describe your preferred design',
        'material' => 'Enter your preferred material',
        _ => 'Enter your preference',
      };

  static IconData _iconFor(String name) => switch (name.toLowerCase()) {
        'name/text' => Icons.edit_note,
        'color' => Icons.palette_outlined,
        'size' => Icons.aspect_ratio,
        'design' => Icons.brush_outlined,
        'material' => Icons.texture,
        _ => Icons.tune,
      };
}

class _CustomizationChoice extends StatelessWidget {
  final BuyerProductCustomization customization;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const _CustomizationChoice({
    required this.customization,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customization.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B261D),
                    ),
                  ),
                ),
                if (customization.additionalPrice > 0)
                  Text(
                    '+₹${customization.additionalPrice}',
                    style: const TextStyle(
                      color: Color(0xFF8B261D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            if (customization.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                customization.description,
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
            if (customization.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: customization.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      customization.images[index],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 72,
                        color: AppColors.background,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (customization.options.isEmpty)
              TextFormField(
                key: ValueKey('custom-${customization.name}'),
                initialValue: selectedValues.firstOrNull ?? '',
                onChanged: (value) => onChanged([value]),
                decoration: InputDecoration(
                  hintText: 'Enter your ${customization.name.toLowerCase()}',
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customization.options.map((option) {
                  final selected = selectedValues.contains(option);
                  return customization.isMultipleSelection
                      ? FilterChip(
                          label: Text(option),
                          selected: selected,
                          selectedColor: const Color(0xFFF2DEDD),
                          checkmarkColor: const Color(0xFF8B261D),
                          onSelected: (isSelected) {
                            final updated = List<String>.from(selectedValues);
                            isSelected
                                ? updated.add(option)
                                : updated.remove(option);
                            onChanged(updated);
                          },
                        )
                      : ChoiceChip(
                          label: Text(option),
                          selected: selected,
                          selectedColor: const Color(0xFFF2DEDD),
                          onSelected: (isSelected) =>
                              onChanged(isSelected ? [option] : []),
                        );
                }).toList(),
              ),
          ],
        ),
      );
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B261D),
                    ),
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
                  return const LinearProgressIndicator(color: Color(0xFF8B261D));
                }
                final result = eligibilitySnapshot.data;
                if (result?.canReview == true) {
                  return OutlinedButton.icon(
                    onPressed: () => _openReviewEditor(
                      context,
                      existing: ownReview.isEmpty ? null : ownReview.first,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF8B261D),
                        width: 1.2,
                      ),
                      foregroundColor: const Color(0xFF8B261D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.rate_review_outlined,
                      color: Color(0xFF8B261D),
                    ),
                    label: Text(
                      ownReview.isEmpty ? 'Write a review' : 'Edit your review',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B261D),
                      ),
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
      backgroundColor: const Color(0xFFFAF6EE),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8B261D),
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verified purchase',
                  style: TextStyle(
                    color: Color(0xFF8B261D),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B261D),
                    ),
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
          color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF8B261D).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.buyerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B261D),
                    ),
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
                  Icon(Icons.verified, size: 16, color: Color(0xFF8B261D)),
                  SizedBox(width: 5),
                  Text(
                    'Verified purchase',
                    style: TextStyle(
                      color: Color(0xFF8B261D),
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
            Icon(icon, size: 21, color: const Color(0xFF8B261D)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}
