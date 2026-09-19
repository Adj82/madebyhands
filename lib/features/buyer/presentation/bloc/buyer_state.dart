part of 'buyer_bloc.dart';

class BuyerState extends Equatable {
  final List<Product> products;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final bool isLoadingProducts;
  final String? errorMessage;

  const BuyerState({
    this.products = const [],
    this.favoriteIds = const {},
    this.cartQuantities = const {},
    this.isLoadingProducts = false,
    this.errorMessage,
  });

  BuyerState copyWith({
    List<Product>? products,
    Set<String>? favoriteIds,
    Map<String, int>? cartQuantities,
    bool? isLoadingProducts,
    String? errorMessage,
  }) {
    return BuyerState(
      products: products ?? this.products,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [products, favoriteIds, cartQuantities, isLoadingProducts, errorMessage];
}
