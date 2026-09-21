part of 'admin_bloc.dart';

class AdminState extends Equatable {
  final List<AdminCreatorApplication> creatorApplications;
  final List<AdminProductApproval> productApprovals;
  final List<String> categories;
  final List<AdminSupportTicket> supportTickets;
  
  final List<CreatorProfile> creatorProfiles;
  final List<UserEntity> buyers;
  final List<UserEntity> creators;
  final List<UserEntity> admins;

  final int totalUsersCount;
  final int activeCreatorsCount;
  final int pendingApprovalsCount;
  final double totalRevenue;

  final double flatFee;
  final double percentFee;
  final bool isLoading;
  final String? errorMessage;

  const AdminState({
    this.creatorApplications = const [],
    this.productApprovals = const [],
    this.categories = const [],
    this.supportTickets = const [],
    this.creatorProfiles = const [],
    this.buyers = const [],
    this.creators = const [],
    this.admins = const [],
    this.totalUsersCount = 0,
    this.activeCreatorsCount = 0,
    this.pendingApprovalsCount = 0,
    this.totalRevenue = 0.0,
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
    List<CreatorProfile>? creatorProfiles,
    List<UserEntity>? buyers,
    List<UserEntity>? creators,
    List<UserEntity>? admins,
    int? totalUsersCount,
    int? activeCreatorsCount,
    int? pendingApprovalsCount,
    double? totalRevenue,
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
      creatorProfiles: creatorProfiles ?? this.creatorProfiles,
      buyers: buyers ?? this.buyers,
      creators: creators ?? this.creators,
      admins: admins ?? this.admins,
      totalUsersCount: totalUsersCount ?? this.totalUsersCount,
      activeCreatorsCount: activeCreatorsCount ?? this.activeCreatorsCount,
      pendingApprovalsCount: pendingApprovalsCount ?? this.pendingApprovalsCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
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
        creatorProfiles,
        buyers,
        creators,
        admins,
        totalUsersCount,
        activeCreatorsCount,
        pendingApprovalsCount,
        totalRevenue,
        flatFee,
        percentFee,
        isLoading,
        errorMessage,
      ];
}
