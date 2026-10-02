part of 'admin_bloc.dart';

class AdminState extends Equatable {
  final List<String> categories;
  final List<CreatorProfile> creatorProfiles;
  final double flatFee;
  final double percentFee;
  final bool isLoading;

  /// One-shot messages for a snackbar; cleared by the next state.
  final String? errorMessage;
  final String? notice;

  const AdminState({
    this.categories = const [],
    this.creatorProfiles = const [],
    this.flatFee = 50.0,
    this.percentFee = 5.0,
    this.isLoading = false,
    this.errorMessage,
    this.notice,
  });

  /// Profiles that submitted documents and await a decision.
  List<CreatorProfile> get pendingVerifications => creatorProfiles
      .where((profile) => profile.verificationStatus == 'In-Process')
      .toList();

  AdminState copyWith({
    List<String>? categories,
    List<CreatorProfile>? creatorProfiles,
    double? flatFee,
    double? percentFee,
    bool? isLoading,
    String? errorMessage,
    String? notice,
  }) {
    return AdminState(
      categories: categories ?? this.categories,
      creatorProfiles: creatorProfiles ?? this.creatorProfiles,
      flatFee: flatFee ?? this.flatFee,
      percentFee: percentFee ?? this.percentFee,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    creatorProfiles,
    flatFee,
    percentFee,
    isLoading,
    errorMessage,
    notice,
  ];
}
