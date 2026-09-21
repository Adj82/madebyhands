import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_repository.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;

  AdminBloc({
    required AdminRepository adminRepository,
  })  : _adminRepository = adminRepository,
        super(const AdminState()) {
    on<AdminLoadDataRequested>(_onLoadDataRequested);
    on<AdminFetchBuyersRequested>(_onFetchBuyersRequested);
    on<AdminFetchCreatorsRequested>(_onFetchCreatorsRequested);
    on<AdminFetchAdminsRequested>(_onFetchAdminsRequested);
    on<AdminApproveCreatorRequested>(_onApproveCreatorRequested);
    on<AdminRejectCreatorRequested>(_onRejectCreatorRequested);
    on<AdminApproveProductRequested>(_onApproveProductRequested);
    on<AdminRejectProductRequested>(_onRejectProductRequested);
    on<AdminAddCategoryRequested>(_onAddCategoryRequested);
    on<AdminDeleteCategoryRequested>(_onDeleteCategoryRequested);
    on<AdminSuspendUserRequested>(_onSuspendUserRequested);
    on<AdminChangeUserRoleRequested>(_onChangeUserRoleRequested);
    on<AdminSendMessageRequested>(_onSendMessageRequested);
    on<AdminUpdateSettingsRequested>(_onUpdateSettingsRequested);
  }

  void _onLoadDataRequested(AdminLoadDataRequested event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    // Fetch Platform Settings
    final settingsRes = await _adminRepository.getPlatformSettings();
    settingsRes.fold(
      (l) => emit(state.copyWith(isLoading: false, errorMessage: l.message)),
      (r) => emit(state.copyWith(
        flatFee: r['flatFee']!,
        percentFee: r['percentFee']!,
      )),
    );

    final ticketsRes = await _adminRepository.getSupportTickets();
    ticketsRes.fold(
      (l) => null,
      (r) => emit(state.copyWith(supportTickets: r)),
    );

    final verificationRes = await _adminRepository.getPendingVerifications();
    verificationRes.fold(
      (l) => null,
      (r) => emit(state.copyWith(creatorProfiles: r)),
    );

    final categoriesRes = await _adminRepository.getCategories();
    categoriesRes.fold(
      (l) => null,
      (r) => emit(state.copyWith(categories: r)),
    );
    
    // Initial mock data for other tabs until those specific repositories are ready
    emit(state.copyWith(
      isLoading: false,
      productApprovals: List.generate(
          10,
          (i) => AdminProductApproval(
              id: 'prod-$i',
              name: 'Handmade Vase $i',
              creatorName: 'Creator $i',
              price: 1200,
              category: 'Pottery')),
    ));
    
    // Trigger real data fetches
    add(AdminFetchBuyersRequested());
    add(AdminFetchCreatorsRequested());
    add(AdminFetchAdminsRequested());
    _fetchSummary(emit);
  }

  void _fetchSummary(Emitter<AdminState> emit) async {
    // In a real production app, we would use Cloud Function aggregation or a 'metadata' doc.
    // For MVP, we derive from existing lists or quick counts.
    final buyers = await _adminRepository.getUsers('buyer');
    final creators = await _adminRepository.getUsers('creator');
    
    emit(state.copyWith(
      totalUsersCount: (buyers.getOrElse((l) => []).length) + (creators.getOrElse((l) => []).length),
      activeCreatorsCount: creators.getOrElse((l) => []).length,
    ));
  }

  void _onFetchBuyersRequested(AdminFetchBuyersRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.getUsers('buyer');
    res.fold(
      (l) => null,
      (r) => emit(state.copyWith(buyers: r)),
    );
  }

  void _onFetchCreatorsRequested(AdminFetchCreatorsRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.getUsers('creator');
    res.fold(
      (l) => null,
      (r) => emit(state.copyWith(creators: r)),
    );
  }

  void _onFetchAdminsRequested(AdminFetchAdminsRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.getUsers('admin');
    res.fold(
      (l) => null,
      (r) => emit(state.copyWith(admins: r)),
    );
  }

  void _onApproveCreatorRequested(AdminApproveCreatorRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.approveCreator(event.applicationId);
    res.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(AdminLoadDataRequested()),
    );
  }

  void _onRejectCreatorRequested(AdminRejectCreatorRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.rejectCreator(event.applicationId);
    res.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(AdminLoadDataRequested()),
    );
  }

  void _onApproveProductRequested(AdminApproveProductRequested event, Emitter<AdminState> emit) {
    final newList = state.productApprovals.where((p) => p.id != event.productId).toList();
    emit(state.copyWith(productApprovals: newList));
  }

  void _onRejectProductRequested(AdminRejectProductRequested event, Emitter<AdminState> emit) {
    final newList = state.productApprovals.where((p) => p.id != event.productId).toList();
    emit(state.copyWith(productApprovals: newList));
  }

  void _onAddCategoryRequested(AdminAddCategoryRequested event, Emitter<AdminState> emit) async {
    await _adminRepository.addCategory(event.name);
    add(AdminLoadDataRequested());
  }

  void _onDeleteCategoryRequested(AdminDeleteCategoryRequested event, Emitter<AdminState> emit) async {
    await _adminRepository.deleteCategory(event.name);
    add(AdminLoadDataRequested());
  }

  void _onSuspendUserRequested(AdminSuspendUserRequested event, Emitter<AdminState> emit) async {
    await _adminRepository.suspendUser(event.uid, event.isSuspended);
    add(AdminLoadDataRequested());
  }

  void _onChangeUserRoleRequested(AdminChangeUserRoleRequested event, Emitter<AdminState> emit) async {
    await _adminRepository.updateUserRole(event.uid, event.newRole);
    add(AdminLoadDataRequested());
  }

  void _onSendMessageRequested(AdminSendMessageRequested event, Emitter<AdminState> emit) {
    emit(state);
  }

  void _onUpdateSettingsRequested(AdminUpdateSettingsRequested event, Emitter<AdminState> emit) async {
    final res = await _adminRepository.updatePlatformSettings(event.flatFee, event.percentFee);
    res.fold(
      (l) => null,
      (r) => emit(state.copyWith(flatFee: event.flatFee, percentFee: event.percentFee)),
    );
  }
}
