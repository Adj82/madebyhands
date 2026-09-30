class CreatorBankAccount {
  final String uid;
  final String accountHolderName;
  final String accountNumber;
  final String accountType; // 'Savings' or 'Current'
  final String bankName;
  final String branchName;
  final String ifscCode;
  final String? upiId;
  final String? panNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CreatorBankAccount({
    required this.uid,
    required this.accountHolderName,
    required this.accountNumber,
    required this.accountType,
    required this.bankName,
    required this.branchName,
    required this.ifscCode,
    this.upiId,
    this.panNumber,
    this.createdAt,
    this.updatedAt,
  });
}
