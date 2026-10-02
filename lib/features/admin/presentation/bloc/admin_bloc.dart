import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_repository.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

part 'admin_event.dart';
part 'admin_state.dart';

/// Admin panel data that is not streamed directly by the views: platform
/// economics, creator profiles for the overview, and categories (which the
/// creator onboarding and listing forms also read).
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;

  AdminBloc({required AdminRepository adminRepository})
    : _adminRepository = adminRepository,
      super(const AdminState()) {
    on<AdminLoadDataRequested>(_onLoadDataRequested);
    on<AdminCategoriesRequested>(_onCategoriesRequested);
    on<AdminApproveCreatorRequested>(_onApproveCreatorRequested);
    on<AdminRejectCreatorRequested>(_onRejectCreatorRequested);
    on<AdminAddCategoryRequested>(_onAddCategoryRequested);
    on<AdminDeleteCategoryRequested>(_onDeleteCategoryRequested);
    on<AdminSuspendUserRequested>(_onSuspendUserRequested);
    on<AdminUpdateSettingsRequested>(_onUpdateSettingsRequested);
    on<AdminProductReviewRequested>(_onProductReviewRequested);
  }

  Future<void> _onProductReviewRequested(
    AdminProductReviewRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.reviewProduct(
      productId: event.productId,
      approve: event.approve,
      reviewerName: event.reviewerName,
      reviewerEmail: event.reviewerEmail,
      rejectionReason: event.rejectionReason,
    );
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          notice: event.approve ? 'Product approved.' : 'Product rejected.',
        ),
      ),
    );
  }

  Future<void> _onLoadDataRequested(
    AdminLoadDataRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final settingsResult = await _adminRepository.getPlatformSettings();
    final profilesResult = await _adminRepository.getCreatorProfiles();
    final categoriesResult = await _adminRepository.getCategories(
      seedDefaults: true,
    );

    var next = state.copyWith(isLoading: false);
    String? error;
    settingsResult.fold<void>((failure) => error = failure.message, (settings) {
      next = next.copyWith(
        flatFee: settings['flatFee'],
        percentFee: settings['percentFee'],
      );
    });
    profilesResult.fold<void>(
      (failure) => error ??= failure.message,
      (profiles) => next = next.copyWith(creatorProfiles: profiles),
    );
    categoriesResult.fold<void>(
      (failure) => error ??= failure.message,
      (categories) => next = next.copyWith(categories: categories),
    );
    emit(next.copyWith(errorMessage: error));
  }

  Future<void> _onCategoriesRequested(
    AdminCategoriesRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.getCategories();
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (categories) => emit(state.copyWith(categories: categories)),
    );
  }

  Future<void> _onApproveCreatorRequested(
    AdminApproveCreatorRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.approveCreator(event.uid);
    await res.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) => _reloadProfiles(emit, notice: 'Creator verified.'),
    );
  }

  Future<void> _onRejectCreatorRequested(
    AdminRejectCreatorRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.rejectCreator(event.uid, event.reason);
    await res.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) => _reloadProfiles(emit, notice: 'Verification rejected.'),
    );
  }

  Future<void> _reloadProfiles(Emitter<AdminState> emit, {String? notice}) async {
    final res = await _adminRepository.getCreatorProfiles();
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (profiles) => emit(state.copyWith(creatorProfiles: profiles, notice: notice)),
    );
  }

  Future<void> _onAddCategoryRequested(
    AdminAddCategoryRequested event,
    Emitter<AdminState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    if (state.categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      emit(state.copyWith(errorMessage: '"$name" already exists.'));
      return;
    }
    final res = await _adminRepository.addCategory(name);
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(categories: [...state.categories, name]..sort()),
      ),
    );
  }

  Future<void> _onDeleteCategoryRequested(
    AdminDeleteCategoryRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.deleteCategory(event.name);
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          categories: state.categories.where((c) => c != event.name).toList(),
        ),
      ),
    );
  }

  Future<void> _onSuspendUserRequested(
    AdminSuspendUserRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.suspendUser(event.uid, event.isSuspended);
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          notice: event.isSuspended ? 'User suspended.' : 'User reinstated.',
        ),
      ),
    );
  }

  Future<void> _onUpdateSettingsRequested(
    AdminUpdateSettingsRequested event,
    Emitter<AdminState> emit,
  ) async {
    final res = await _adminRepository.updatePlatformSettings(
      event.flatFee,
      event.percentFee,
    );
    res.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          flatFee: event.flatFee,
          percentFee: event.percentFee,
          notice: 'Platform fees updated.',
        ),
      ),
    );
  }
}
