import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(const AdminState()) {
    on<AdminLoadDataRequested>(_onLoadDataRequested);
    on<AdminApproveCreatorRequested>(_onApproveCreatorRequested);
    on<AdminRejectCreatorRequested>(_onRejectCreatorRequested);
    on<AdminApproveProductRequested>(_onApproveProductRequested);
    on<AdminRejectProductRequested>(_onRejectProductRequested);
    on<AdminAddCategoryRequested>(_onAddCategoryRequested);
    on<AdminDeleteCategoryRequested>(_onDeleteCategoryRequested);
    on<AdminSendMessageRequested>(_onSendMessageRequested);
    on<AdminUpdateSettingsRequested>(_onUpdateSettingsRequested);
  }

  void _onLoadDataRequested(AdminLoadDataRequested event, Emitter<AdminState> emit) {
    emit(state.copyWith(isLoading: true));
    // Simulate API fetch with mock data
    emit(state.copyWith(
      isLoading: false,
      creatorApplications: List.generate(
          8,
          (i) => AdminCreatorApplication(
              id: 'app-$i',
              name: 'Artisan $i',
              category: 'Pottery',
              bio: 'A creator from Jaipur.',
              appliedAt: DateTime.now())),
      productApprovals: List.generate(
          10,
          (i) => AdminProductApproval(
              id: 'prod-$i',
              name: 'Handmade Vase $i',
              creatorName: 'Creator $i',
              price: 1200,
              category: 'Pottery')),
      categories: ['Pottery', 'Jewellery', 'Home Decor', 'Textiles', 'Gifts'],
      supportTickets: List.generate(
          6,
          (i) => AdminSupportTicket(
              id: 'ticket-$i',
              subject: 'Issue $i',
              lastMessage: 'I need help.',
              isOpen: i < 3)),
    ));
  }

  void _onApproveCreatorRequested(AdminApproveCreatorRequested event, Emitter<AdminState> emit) {
    final newList = state.creatorApplications.where((a) => a.id != event.applicationId).toList();
    emit(state.copyWith(creatorApplications: newList));
  }

  void _onRejectCreatorRequested(AdminRejectCreatorRequested event, Emitter<AdminState> emit) {
    final newList = state.creatorApplications.where((a) => a.id != event.applicationId).toList();
    emit(state.copyWith(creatorApplications: newList));
  }

  void _onApproveProductRequested(AdminApproveProductRequested event, Emitter<AdminState> emit) {
    final newList = state.productApprovals.where((p) => p.id != event.productId).toList();
    emit(state.copyWith(productApprovals: newList));
  }

  void _onRejectProductRequested(AdminRejectProductRequested event, Emitter<AdminState> emit) {
    final newList = state.productApprovals.where((p) => p.id != event.productId).toList();
    emit(state.copyWith(productApprovals: newList));
  }

  void _onAddCategoryRequested(AdminAddCategoryRequested event, Emitter<AdminState> emit) {
    final newList = List<String>.from(state.categories)..add(event.name);
    emit(state.copyWith(categories: newList));
  }

  void _onDeleteCategoryRequested(AdminDeleteCategoryRequested event, Emitter<AdminState> emit) {
    final newList = state.categories.where((c) => c != event.name).toList();
    emit(state.copyWith(categories: newList));
  }

  void _onSendMessageRequested(AdminSendMessageRequested event, Emitter<AdminState> emit) {
    // In a real app, this would push to Firestore
    // For now, we'll just emit the same state to trigger listener feedback
    emit(state);
  }

  void _onUpdateSettingsRequested(AdminUpdateSettingsRequested event, Emitter<AdminState> emit) {
    emit(state.copyWith(flatFee: event.flatFee, percentFee: event.percentFee));
  }
}
