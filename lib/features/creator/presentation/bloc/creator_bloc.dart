import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';

part 'creator_event.dart';
part 'creator_state.dart';

class CreatorBloc extends Bloc<CreatorEvent, CreatorState> {
  final CreatorRepository _creatorRepository;

  CreatorBloc({
    required CreatorRepository creatorRepository,
  })  : _creatorRepository = creatorRepository,
        super(CreatorInitial()) {
    on<CreatorCheckProfileExists>(_onCheckProfileExists);
    on<CreatorSubmitOnboarding>(_onSubmitOnboarding);
    on<CreatorSubmitVerification>(_onSubmitVerification);
    on<CreatorFetchAllProfiles>(_onFetchAllProfiles);
    on<CreatorUpdateVerificationStatus>(_onUpdateVerificationStatus);
    on<CreatorAddProduct>(_onAddProduct);
    on<CreatorUpdateProduct>(_onUpdateProduct);
    on<CreatorFetchPendingProducts>(_onFetchPendingProducts);
    on<CreatorFetchAdminAllProducts>(_onFetchAdminAllProducts);
    on<CreatorFetchCreatorProducts>(_onFetchCreatorProducts);
    on<CreatorUpdateProductStatus>(_onUpdateProductStatus);
    on<CreatorFetchOrders>(_onFetchOrders);
    on<CreatorUpdateOrderStatus>(_onUpdateOrderStatus);
  }

  void _onCheckProfileExists(
    CreatorCheckProfileExists event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.getCreatorProfile(event.uid);
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) {
        if (r == null) {
          emit(CreatorProfileNotFound());
        } else {
          emit(CreatorProfileLoaded(r));
        }
      },
    );
  }

  void _onSubmitOnboarding(
    CreatorSubmitOnboarding event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.saveCreatorProfile(
      uid: event.uid,
      name: event.name,
      profileImageFile: event.profileImageFile,
      bio: event.bio,
      category: event.category,
      location: event.location,
      socialLinks: event.socialLinks,
      portfolioImageFiles: event.portfolioImageFiles,
      story: event.story,
    );

    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorOnboardingSuccess()),
    );
  }

  void _onSubmitVerification(
    CreatorSubmitVerification event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.submitVerification(
      uid: event.uid,
      creatorName: event.creatorName,
      businessName: event.businessName,
      address: event.address,
      latestPhotoFile: event.latestPhotoFile,
      idCardFile: event.idCardFile,
      existingLatestPhotoUrl: event.existingLatestPhotoUrl,
      existingIdCardUrl: event.existingIdCardUrl,
    );

    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorVerificationSuccess()),
    );
  }

  void _onFetchAllProfiles(
    CreatorFetchAllProfiles event,
    Emitter<CreatorState> emit,
  ) async {
    if (state is! CreatorAllProfilesLoaded) {
      emit(CreatorLoading());
    }
    final res = await _creatorRepository.getAllCreatorProfiles();
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorAllProfilesLoaded(r)),
    );
  }

  void _onUpdateVerificationStatus(
    CreatorUpdateVerificationStatus event,
    Emitter<CreatorState> emit,
  ) async {
    final currentState = state;
    final List<CreatorProfile> previousProfiles = currentState is CreatorAllProfilesLoaded ? currentState.profiles : [];

    final res = await _creatorRepository.updateVerificationStatus(event.uid, event.status);
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) {
        if (previousProfiles.isNotEmpty) {
          final updatedProfiles = previousProfiles.map((p) {
            if (p.uid == event.uid) {
              return CreatorProfile(
                uid: p.uid,
                name: p.name,
                profileImage: p.profileImage,
                bio: p.bio,
                category: p.category,
                location: p.location,
                socialLinks: p.socialLinks,
                portfolio: p.portfolio,
                story: p.story,
                verificationStatus: event.status,
                businessName: p.businessName,
                address: p.address,
                latestPhoto: p.latestPhoto,
                idCard: p.idCard,
              );
            }
            return p;
          }).toList();
          emit(CreatorAllProfilesLoaded(updatedProfiles));
        } else {
          add(CreatorFetchAllProfiles());
        }
      },
    );
  }

  void _onAddProduct(
    CreatorAddProduct event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.addProduct(
      name: event.name,
      description: event.description,
      imageFiles: event.imageFiles,
      category: event.category,
      price: event.price,
      stock: event.stock,
      materials: event.materials,
      dimensions: event.dimensions,
      weight: event.weight,
      shippingInfo: event.shippingInfo,
      creatorUid: event.creatorUid,
      creatorName: event.creatorName,
      isCustomizable: event.isCustomizable,
      customizations: event.customizations,
    );

    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorAddProductSuccess()),
    );
  }

  void _onUpdateProduct(
    CreatorUpdateProduct event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.updateProduct(
      productId: event.productId,
      name: event.name,
      description: event.description,
      newImageFiles: event.newImageFiles,
      existingImageUrls: event.existingImageUrls,
      category: event.category,
      price: event.price,
      stock: event.stock,
      materials: event.materials,
      dimensions: event.dimensions,
      weight: event.weight,
      shippingInfo: event.shippingInfo,
      creatorUid: event.creatorUid,
      creatorName: event.creatorName,
      isCustomizable: event.isCustomizable,
      customizations: event.customizations,
      hasChanges: event.hasChanges,
    );

    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorAddProductSuccess()),
    );
  }

  void _onFetchPendingProducts(
    CreatorFetchPendingProducts event,
    Emitter<CreatorState> emit,
  ) async {
    if (state is! CreatorPendingProductsLoaded) {
      emit(CreatorLoading());
    }
    final res = await _creatorRepository.getPendingProducts();
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorPendingProductsLoaded(r)),
    );
  }

  void _onFetchAdminAllProducts(
    CreatorFetchAdminAllProducts event,
    Emitter<CreatorState> emit,
  ) async {
    if (state is! CreatorAdminAllProductsLoaded) {
      emit(CreatorLoading());
    }
    final res = await _creatorRepository.getAdminAllProducts();
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorAdminAllProductsLoaded(r)),
    );
  }

  void _onFetchCreatorProducts(
    CreatorFetchCreatorProducts event,
    Emitter<CreatorState> emit,
  ) async {
    if (state is! CreatorMyProductsLoaded) {
      emit(CreatorLoading());
    }
    final res = await _creatorRepository.getCreatorProducts(event.uid);
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorMyProductsLoaded(r)),
    );
  }

  void _onUpdateProductStatus(
    CreatorUpdateProductStatus event,
    Emitter<CreatorState> emit,
  ) async {
    final res = await _creatorRepository.updateProductStatus(
      event.productId,
      event.status,
      approvedBy: event.approvedBy,
      approvedByEmail: event.approvedByEmail,
    );
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) {
        add(CreatorFetchAdminAllProducts());
      },
    );
  }

  void _onFetchOrders(
    CreatorFetchOrders event,
    Emitter<CreatorState> emit,
  ) async {
    if (state is! CreatorOrdersLoaded) {
      emit(CreatorLoading());
    }
    final res = await _creatorRepository.getCreatorOrders(event.uid);
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorOrdersLoaded(r)),
    );
  }

  void _onUpdateOrderStatus(
    CreatorUpdateOrderStatus event,
    Emitter<CreatorState> emit,
  ) async {
    final res = await _creatorRepository.updateOrderStatus(
      event.orderId,
      event.status,
      rejectionReason: event.rejectionReason,
      consignmentNumber: event.consignmentNumber,
    );
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => add(CreatorFetchOrders(event.uid)),
    );
  }
}
