import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';

part 'creator_event.dart';
part 'creator_state.dart';

class CreatorBloc extends Bloc<CreatorEvent, CreatorState> {
  final CreatorRepository _repository;

  CreatorBloc({required CreatorRepository creatorRepository})
    : _repository = creatorRepository,
      super(const CreatorState()) {
    on<CreatorCheckProfileExists>(_onCheckProfile);
    on<CreatorSessionEnded>((_, emit) => emit(const CreatorState()));
    on<CreatorSubmitOnboarding>(_onSubmitOnboarding);
    on<CreatorSubmitVerification>(_onSubmitVerification);
    on<CreatorSaveProduct>(_onSaveProduct);
    on<CreatorDeleteProduct>(
      (event, emit) => _run(
        emit,
        CreatorAction.deleteProduct,
        () => _repository.deleteProduct(event.productId),
        success: 'Product deleted.',
      ),
    );
    on<CreatorSetProductPublished>(
      (event, emit) => _run(
        emit,
        CreatorAction.publishProduct,
        () => _repository.setProductPublished(event.productId, event.published),
        success: event.published
            ? 'Product is live for buyers.'
            : 'Product hidden from buyers.',
      ),
    );
    on<CreatorUpdateStock>(
      (event, emit) => _run(
        emit,
        CreatorAction.updateStock,
        () => _repository.updateStock(event.productId, event.stock),
        success: 'Stock updated.',
      ),
    );
    on<CreatorUpdateOrderStatus>(
      (event, emit) => _run(
        emit,
        CreatorAction.updateOrder,
        () => _repository.updateOrderStatus(
          event.orderId,
          event.status,
          consignmentNumber: event.consignmentNumber,
          carrierName: event.carrierName,
        ),
        success: 'Order updated.',
      ),
    );
    on<CreatorRejectOrder>(_onRejectOrder);
    on<CreatorSaveBankAccount>(
      (event, emit) => _run(
        emit,
        CreatorAction.saveBankAccount,
        () => _repository.saveCreatorBankAccount(event.bankDetail),
        success: 'Payout details saved.',
      ),
    );
  }

  Future<void> _run(
    Emitter<CreatorState> emit,
    CreatorAction action,
    Future<Either<Failure, void>> Function() call, {
    required String success,
  }) async {
    emit(state.withAction(action, CreatorActionStatus.inProgress));
    final result = await call();
    emit(
      result.fold(
        (failure) => state.withAction(
          action,
          CreatorActionStatus.failure,
          message: failure.message,
        ),
        (_) => state.withAction(
          action,
          CreatorActionStatus.success,
          message: success,
        ),
      ),
    );
  }

  Future<void> _loadProfile(
    String uid,
    Emitter<CreatorState> emit, {
    bool silent = false,
  }) async {
    if (!silent || state.profile == null) {
      emit(state.withSession(status: CreatorSessionStatus.loading, profile: state.profile));
    }
    final result = await _repository.getCreatorProfile(uid);
    result.fold(
      (failure) {
        // A failed background refresh keeps the profile already on screen.
        if (state.profile != null && silent) return;
        emit(
          state.withSession(
            status: CreatorSessionStatus.failure,
            sessionError: failure.message,
          ),
        );
      },
      (profile) => emit(
        state.withSession(
          status: profile == null
              ? CreatorSessionStatus.notFound
              : CreatorSessionStatus.ready,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _onCheckProfile(
    CreatorCheckProfileExists event,
    Emitter<CreatorState> emit,
  ) => _loadProfile(event.uid, emit, silent: event.silent);

  Future<void> _onSubmitOnboarding(
    CreatorSubmitOnboarding event,
    Emitter<CreatorState> emit,
  ) async {
    emit(state.withAction(CreatorAction.saveProfile, CreatorActionStatus.inProgress));
    final result = await _repository.saveCreatorProfile(
      uid: event.uid,
      name: event.name,
      profileImageFile: event.profileImageFile,
      bio: event.bio,
      location: event.location,
      socialLinks: event.socialLinks,
      portfolioImageFiles: event.portfolioImageFiles,
      story: event.story,
      existingProfileImageUrl: event.existingProfileImageUrl,
      existingPortfolioUrls: event.existingPortfolioUrls,
    );
    if (result.isLeft()) {
      emit(
        state.withAction(
          CreatorAction.saveProfile,
          CreatorActionStatus.failure,
          message: result.getLeft().toNullable()!.message,
        ),
      );
      return;
    }
    await _loadProfile(event.uid, emit, silent: true);
    emit(
      state.withAction(
        CreatorAction.saveProfile,
        CreatorActionStatus.success,
        message: 'Profile saved.',
      ),
    );
  }

  Future<void> _onSubmitVerification(
    CreatorSubmitVerification event,
    Emitter<CreatorState> emit,
  ) async {
    emit(
      state.withAction(CreatorAction.submitVerification, CreatorActionStatus.inProgress),
    );
    final result = await _repository.submitVerification(
      uid: event.uid,
      creatorName: event.creatorName,
      businessName: event.businessName,
      address: event.address,
      latestPhotoFile: event.latestPhotoFile,
      idCardFile: event.idCardFile,
      existingLatestPhotoUrl: event.existingLatestPhotoUrl,
      existingIdCardUrl: event.existingIdCardUrl,
    );
    if (result.isLeft()) {
      emit(
        state.withAction(
          CreatorAction.submitVerification,
          CreatorActionStatus.failure,
          message: result.getLeft().toNullable()!.message,
        ),
      );
      return;
    }
    await _loadProfile(event.uid, emit, silent: true);
    emit(
      state.withAction(
        CreatorAction.submitVerification,
        CreatorActionStatus.success,
        message: 'Documents submitted. We will review them shortly.',
      ),
    );
  }

  Future<void> _onSaveProduct(
    CreatorSaveProduct event,
    Emitter<CreatorState> emit,
  ) {
    final productId = event.productId;
    return _run(
      emit,
      CreatorAction.saveProduct,
      () => productId == null
          ? _repository.addProduct(event.input)
          : _repository.updateProduct(productId, event.input),
      success: productId == null
          ? 'Product submitted for admin approval.'
          : 'Changes saved. The listing is back in admin review.',
    );
  }

  Future<void> _onRejectOrder(
    CreatorRejectOrder event,
    Emitter<CreatorState> emit,
  ) async {
    emit(state.withAction(CreatorAction.rejectOrder, CreatorActionStatus.inProgress));
    final result = await _repository.rejectOrder(event.orderId, event.reason);
    emit(
      result.fold(
        (failure) => state.withAction(
          CreatorAction.rejectOrder,
          CreatorActionStatus.failure,
          message: failure.message,
        ),
        (outcome) => state.withAction(
          CreatorAction.rejectOrder,
          CreatorActionStatus.success,
          message:
              outcome.warning ??
              (outcome.refunded
                  ? 'Order rejected. The buyer has been refunded.'
                  : 'Order rejected.'),
        ),
      ),
    );
  }
}
