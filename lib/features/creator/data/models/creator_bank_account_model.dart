import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';

class CreatorBankAccountModel extends CreatorBankAccount {
  const CreatorBankAccountModel({
    required super.uid,
    required super.accountHolderName,
    required super.accountNumber,
    required super.accountType,
    required super.bankName,
    required super.branchName,
    required super.ifscCode,
    super.upiId,
    super.panNumber,
    super.createdAt,
    super.updatedAt,
  });

  factory CreatorBankAccountModel.fromJson(
    Map<String, dynamic> json,
    String uid,
  ) {
    return CreatorBankAccountModel(
      uid: uid,
      accountHolderName: json['accountHolderName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountType: json['accountType'] as String? ?? 'Savings',
      bankName: json['bankName'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      upiId: json['upiId'] as String?,
      panNumber: json['panNumber'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'accountType': accountType,
      'bankName': bankName,
      'branchName': branchName,
      'ifscCode': ifscCode,
      if (upiId != null && upiId!.trim().isNotEmpty) 'upiId': upiId!.trim(),
      if (panNumber != null && panNumber!.trim().isNotEmpty)
        'panNumber': panNumber!.trim().toUpperCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
