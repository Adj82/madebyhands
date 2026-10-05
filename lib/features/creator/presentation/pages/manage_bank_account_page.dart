import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/init_dependencies.dart';

class ManageBankAccountPage extends StatefulWidget {
  final CreatorProfile profile;

  const ManageBankAccountPage({super.key, required this.profile});

  @override
  State<ManageBankAccountPage> createState() => _ManageBankAccountPageState();
}

class _ManageBankAccountPageState extends State<ManageBankAccountPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountHolderController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _confirmAccountNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _ifscCodeController;
  late final TextEditingController _upiIdController;
  late final TextEditingController _panNumberController;

  String _accountType = 'Savings';
  bool _showAccountNumber = false;
  bool _showConfirmAccountNumber = false;
  bool _loading = true;
  String? _loadError;

  final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  @override
  void initState() {
    super.initState();
    _accountHolderController = TextEditingController(text: widget.profile.name);
    _accountNumberController = TextEditingController();
    _confirmAccountNumberController = TextEditingController();
    _bankNameController = TextEditingController();
    _branchNameController = TextEditingController();
    _ifscCodeController = TextEditingController();
    _upiIdController = TextEditingController();
    _panNumberController = TextEditingController();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await serviceLocator<CreatorRepository>().getCreatorBankAccount(
      widget.profile.uid,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) => _loadError = failure.message,
        (bankDetail) {
          if (bankDetail != null) _prefillData(bankDetail);
        },
      );
    });
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  void _prefillData(CreatorBankAccount bankDetail) {
    _accountHolderController.text = bankDetail.accountHolderName;
    _accountNumberController.text = bankDetail.accountNumber;
    _confirmAccountNumberController.text = bankDetail.accountNumber;
    _accountType = bankDetail.accountType.isNotEmpty ? bankDetail.accountType : 'Savings';
    _bankNameController.text = bankDetail.bankName;
    _branchNameController.text = bankDetail.branchName;
    _ifscCodeController.text = bankDetail.ifscCode;
    _upiIdController.text = bankDetail.upiId ?? '';
    _panNumberController.text = bankDetail.panNumber ?? '';
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final bankDetail = CreatorBankAccount(
        uid: widget.profile.uid,
        accountHolderName: _accountHolderController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountType: _accountType,
        bankName: _bankNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
        ifscCode: _ifscCodeController.text.trim().toUpperCase(),
        upiId: _upiIdController.text.trim().isNotEmpty
            ? _upiIdController.text.trim()
            : null,
        panNumber: _panNumberController.text.trim().isNotEmpty
            ? _panNumberController.text.trim().toUpperCase()
            : null,
      );

      context.read<CreatorBloc>().add(CreatorSaveBankAccount(bankDetail));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payout details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listenWhen: (previous, current) =>
            previous.actionId != current.actionId &&
            current.action == CreatorAction.saveBankAccount &&
            current.actionStatus != CreatorActionStatus.inProgress,
        listener: (context, state) {
          final success = state.actionStatus == CreatorActionStatus.success;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.actionMessage ??
                    (success ? 'Payout details saved.' : 'Could not save. Please try again.'),
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) Navigator.pop(context);
        },
        buildWhen: (previous, current) =>
            previous.isRunning(CreatorAction.saveBankAccount) !=
            current.isRunning(CreatorAction.saveBankAccount),
        builder: (context, state) {
          final saving = state.isRunning(CreatorAction.saveBankAccount);
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20.0,
              20.0,
              20.0,
              MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: AppColors.primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your bank account details are securely stored and strictly used by Admin for order payouts.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFieldTitle('Account Holder Name *'),
                  TextFormField(
                    controller: _accountHolderController,
                    decoration: const InputDecoration(
                      hintText: 'Full name as per bank records',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Account holder name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('Account Number *'),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    obscureText: !_showAccountNumber,
                    decoration: InputDecoration(
                      hintText: 'Enter bank account number',
                      prefixIcon: const Icon(Icons.numbers_outlined),
                      suffixIcon: IconButton(
                        tooltip: _showAccountNumber ? 'Hide' : 'Show',
                        icon: Icon(
                          _showAccountNumber
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _showAccountNumber = !_showAccountNumber,
                        ),
                      ),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Account number is required.';
                      }
                      if (trimmed.length < 8) {
                        return 'Enter a valid account number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('Confirm Account Number *'),
                  TextFormField(
                    controller: _confirmAccountNumberController,
                    keyboardType: TextInputType.number,
                    obscureText: !_showConfirmAccountNumber,
                    decoration: InputDecoration(
                      hintText: 'Re-enter bank account number',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        tooltip: _showConfirmAccountNumber ? 'Hide' : 'Show',
                        icon: Icon(
                          _showConfirmAccountNumber
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _showConfirmAccountNumber =
                              !_showConfirmAccountNumber,
                        ),
                      ),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Please confirm your account number.';
                      }
                      if (trimmed != _accountNumberController.text.trim()) {
                        return 'Account numbers do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('Account Type *'),
                  DropdownButtonFormField<String>(
                    initialValue: _accountType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Savings',
                        child: Text('Savings Account'),
                      ),
                      DropdownMenuItem(
                        value: 'Current',
                        child: Text('Current Account'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _accountType = val);
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select account type' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('Bank Name *'),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. State Bank of India, HDFC Bank',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Bank name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('Branch Name *'),
                  TextFormField(
                    controller: _branchNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Connaught Place, Jaipur Main',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Branch name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('IFSC Code *'),
                  TextFormField(
                    controller: _ifscCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. SBIN0001234',
                      prefixIcon: Icon(Icons.code_outlined),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim().toUpperCase() ?? '';
                      if (trimmed.isEmpty) {
                        return 'IFSC code is required.';
                      }
                      if (!_ifscRegex.hasMatch(trimmed)) {
                        return 'Enter a valid 11-digit IFSC code (e.g. SBIN0001234).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('UPI ID (Optional)'),
                  TextFormField(
                    controller: _upiIdController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'e.g. name@upi or mobile@paytm',
                      prefixIcon: Icon(Icons.qr_code_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFieldTitle('PAN Number (Optional)'),
                  TextFormField(
                    controller: _panNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ABCDE1234F',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim().toUpperCase() ?? '';
                      if (trimmed.isEmpty) return null;
                      if (!_panRegex.hasMatch(trimmed)) {
                        return 'Enter a valid 10-character PAN number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: saving ? null : _submit,
                      child: saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save payout details'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }
}
