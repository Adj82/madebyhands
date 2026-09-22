part of 'creator_bloc.dart';

@immutable
sealed class CreatorState {}

final class CreatorInitial extends CreatorState {}

final class CreatorLoading extends CreatorState {}

final class CreatorProfileLoaded extends CreatorState {
  final CreatorProfile profile;
  CreatorProfileLoaded(this.profile);
}

final class CreatorProfileNotFound extends CreatorState {}

final class CreatorOnboardingSuccess extends CreatorState {}

final class CreatorVerificationSuccess extends CreatorState {}

final class CreatorAllProfilesLoaded extends CreatorState {
  final List<CreatorProfile> profiles;
  CreatorAllProfilesLoaded(this.profiles);
}

final class CreatorAddProductSuccess extends CreatorState {}

final class CreatorPendingProductsLoaded extends CreatorState {
  final List<CreatorProduct> products;
  CreatorPendingProductsLoaded(this.products);
}

final class CreatorAdminAllProductsLoaded extends CreatorState {
  final List<CreatorProduct> products;
  CreatorAdminAllProductsLoaded(this.products);
}

final class CreatorMyProductsLoaded extends CreatorState {
  final List<CreatorProduct> products;
  CreatorMyProductsLoaded(this.products);
}

final class CreatorOrdersLoaded extends CreatorState {
  final List<CreatorOrder> orders;
  CreatorOrdersLoaded(this.orders);
}

final class CreatorFailure extends CreatorState {
  final String message;
  CreatorFailure(this.message);
}
