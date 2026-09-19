part of 'buyer_bloc.dart';

sealed class BuyerEvent extends Equatable {
  const BuyerEvent();

  @override
  List<Object> get props => [];
}

final class BuyerWatchProducts extends BuyerEvent {}

final class BuyerProductsUpdated extends BuyerEvent {
  final List<Product> products;
  const BuyerProductsUpdated(this.products);
}

final class BuyerWatchFavorites extends BuyerEvent {
  final String userId;
  const BuyerWatchFavorites(this.userId);
}

final class BuyerFavoritesUpdated extends BuyerEvent {
  final Set<String> favoriteIds;
  const BuyerFavoritesUpdated(this.favoriteIds);
}

final class BuyerToggleFavorite extends BuyerEvent {
  final String userId;
  final Product product;
  const BuyerToggleFavorite({required this.userId, required this.product});
}

final class BuyerUpdateCartQuantity extends BuyerEvent {
  final Product product;
  final int quantity;
  const BuyerUpdateCartQuantity(this.product, this.quantity);
}

final class BuyerErrorOccurred extends BuyerEvent {
  final String message;
  const BuyerErrorOccurred(this.message);
}
