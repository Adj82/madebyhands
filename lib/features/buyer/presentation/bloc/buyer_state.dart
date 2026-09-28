part of 'buyer_bloc.dart';

class BuyerState extends Equatable {
  final List<Product> products;
  final List<PublicCreator> creators;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final Map<String, ProductCustomizationSelection> cartCustomizations;
  final bool isLoadingProducts;
  final String? errorMessage;

  const BuyerState({
    this.products = const [],
    this.creators = const [],
    this.favoriteIds = const {},
    this.cartQuantities = const {},
    this.cartCustomizations = const {},
    this.isLoadingProducts = false,
    this.errorMessage,
  });

  BuyerState copyWith({
    List<Product>? products,
    List<PublicCreator>? creators,
    Set<String>? favoriteIds,
    Map<String, int>? cartQuantities,
    Map<String, ProductCustomizationSelection>? cartCustomizations,
    bool? isLoadingProducts,
    String? errorMessage,
  }) {
    return BuyerState(
      products: products ?? this.products,
      creators: creators ?? this.creators,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      cartCustomizations: cartCustomizations ?? this.cartCustomizations,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    products,
    creators,
    favoriteIds,
    cartQuantities,
    cartCustomizations,
    isLoadingProducts,
    errorMessage,
  ];
}
