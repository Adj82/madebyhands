part of 'admin_bloc.dart';

class AdminState extends Equatable {
  final List<AdminCreatorApplication> creatorApplications;
  final List<AdminProductApproval> productApprovals;
  final List<String> categories;
  final List<AdminSupportTicket> supportTickets;
  final double flatFee;
  final double percentFee;
  final bool isLoading;
  final String? errorMessage;

  const AdminState({
    this.creatorApplications = const [],
    this.productApprovals = const [],
    this.categories = const [],
    this.supportTickets = const [],
    this.flatFee = 50.0,
    this.percentFee = 5.0,
    this.isLoading = false,
    this.errorMessage,
  });

  AdminState copyWith({
    List<AdminCreatorApplication>? creatorApplications,
    List<AdminProductApproval>? productApprovals,
    List<String>? categories,
    List<AdminSupportTicket>? supportTickets,
    double? flatFee,
    double? percentFee,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminState(
      creatorApplications: creatorApplications ?? this.creatorApplications,
      productApprovals: productApprovals ?? this.productApprovals,
      categories: categories ?? this.categories,
      supportTickets: supportTickets ?? this.supportTickets,
      flatFee: flatFee ?? this.flatFee,
      percentFee: percentFee ?? this.percentFee,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        creatorApplications,
        productApprovals,
        categories,
        supportTickets,
        flatFee,
        percentFee,
        isLoading,
        errorMessage,
      ];
}
