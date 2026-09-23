import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';

part 'buyer_event.dart';
part 'buyer_state.dart';

class BuyerBloc extends Bloc<BuyerEvent, BuyerState> {
  final BuyerRepository _repository;
  StreamSubscription? _productSubscription;
  StreamSubscription? _favoriteSubscription;

  BuyerBloc({required BuyerRepository repository})
      : _repository = repository,
        super(const BuyerState()) {
    on<BuyerWatchProducts>(_onWatchProducts);
    on<BuyerProductsUpdated>(_onProductsUpdated);
    on<BuyerWatchFavorites>(_onWatchFavorites);
    on<BuyerFavoritesUpdated>(_onFavoritesUpdated);
    on<BuyerToggleFavorite>(_onToggleFavorite);
    on<BuyerUpdateCartQuantity>(_onUpdateCartQuantity);
    on<BuyerErrorOccurred>(_onErrorOccurred);
  }

  BuyerRepository get repository => _repository;

  void _onWatchProducts(BuyerWatchProducts event, Emitter<BuyerState> emit) {
    emit(state.copyWith(isLoadingProducts: true));
    _productSubscription?.cancel();
    _productSubscription = _repository.watchProducts().listen(
      (products) => add(BuyerProductsUpdated(products)),
      onError: (err) => add(BuyerErrorOccurred(err.toString())),
    );
  }

  void _onProductsUpdated(BuyerProductsUpdated event, Emitter<BuyerState> emit) {
    emit(state.copyWith(products: event.products, isLoadingProducts: false));
  }

  void _onWatchFavorites(BuyerWatchFavorites event, Emitter<BuyerState> emit) {
    _favoriteSubscription?.cancel();
    _favoriteSubscription = _repository.watchFavoriteProductIds(event.userId).listen(
      (ids) => add(BuyerFavoritesUpdated(ids)),
    );
  }

  void _onFavoritesUpdated(BuyerFavoritesUpdated event, Emitter<BuyerState> emit) {
    emit(state.copyWith(favoriteIds: event.favoriteIds));
  }

  Future<void> _onToggleFavorite(BuyerToggleFavorite event, Emitter<BuyerState> emit) async {
    final isFavorite = state.favoriteIds.contains(event.product.id);
    try {
      await _repository.setFavorite(
        userId: event.userId,
        productId: event.product.id,
        isFavorite: !isFavorite,
      );
    } catch (e) {
      add(BuyerErrorOccurred('Could not update favorites.'));
    }
  }

  void _onUpdateCartQuantity(BuyerUpdateCartQuantity event, Emitter<BuyerState> emit) {
    final newCart = Map<String, int>.from(state.cartQuantities);
    if (event.quantity <= 0) {
      newCart.remove(event.product.id);
    } else {
      newCart[event.product.id] = event.quantity;
    }
    emit(state.copyWith(cartQuantities: newCart));
  }

  void _onErrorOccurred(BuyerErrorOccurred event, Emitter<BuyerState> emit) {
    emit(state.copyWith(errorMessage: event.message, isLoadingProducts: false));
  }

  @override
  Future<void> close() {
    _productSubscription?.cancel();
    _favoriteSubscription?.cancel();
    return super.close();
  }
}
