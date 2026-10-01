import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_onboarding_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/manage_bank_account_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/privacy_policy_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/terms_and_conditions_page.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';
import 'package:madebyhands/init_dependencies.dart';

class CreatorProfileView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorProfileView({super.key, required this.profile});

  @override
  State<CreatorProfileView> createState() => _CreatorProfileViewState();
}

class _CreatorProfileViewState extends State<CreatorProfileView> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  void _checkProfile() {
    context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.profile.uid));
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      _checkProfile();
      context.read<CreatorBloc>().add(CreatorFetchCreatorProducts(widget.profile.uid));
      context.read<CreatorBloc>().add(CreatorFetchOrders(widget.profile.uid));
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      buildWhen: (previous, current) =>
          current is CreatorProfileLoaded ||
          current is CreatorLoading ||
          current is CreatorFailure,
      builder: (context, state) {
        final profile = (state is CreatorProfileLoaded)
            ? state.profile
            : widget.profile;

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileCard(profile),
                const SizedBox(height: 24),
                _buildDeletionRequestStatusCard(profile),
                _buildActionItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Creator Profile',
                  subtitle: 'Update bio, craft category, story, and links',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreatorOnboardingPage(
                          user: UserEntity(
                            uid: profile.uid,
                            email: '',
                            name: profile.name,
                            role: 'creator',
                          ),
                          existingProfile: profile,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Manage Bank Account',
                  subtitle: 'Manage bank details, IFSC, and payout preferences',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageBankAccountPage(profile: profile),
                      ),
                    );
                  },
                ),
                _buildActionItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'Read artisan platform terms and rules',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsPage(),
                      ),
                    );
                  },
                ),
                _buildActionItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View data protection policies',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                _buildActionItem(
                  icon: Icons.delete_forever_outlined,
                  title: 'Request Account Deletion',
                  subtitle:
                      'Submit a request to delete your creator account and data',
                  badgeColor: Colors.red,
                  onTap: () => _showAccountDeletionDialog(profile),
                ),
                const SizedBox(height: 30),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label:
                      const Text('Log Out', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(CreatorProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.outline,
            backgroundImage: profile.profileImage.isNotEmpty
                ? NetworkImage(profile.profileImage)
                : null,
            child: profile.profileImage.isEmpty
                ? const Icon(Icons.person, size: 46, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            profile.category,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (profile.verificationStatus == 'Verified'
                      ? Colors.green
                      : (profile.verificationStatus == 'In-Process'
                          ? Colors.orange
                          : Colors.red))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              profile.verificationStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: profile.verificationStatus == 'Verified'
                    ? Colors.green
                    : (profile.verificationStatus == 'In-Process'
                        ? Colors.orange.shade800
                        : Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: badgeColor ?? AppColors.primary),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeletionRequestStatusCard(CreatorProfile profile) {
    final supportRepo = serviceLocator<SupportRepository>();
    return StreamBuilder<SupportTicket?>(
      stream: supportRepo.watchLatestDeletionRequest(profile.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final ticket = snapshot.data!;
        Color statusColor;
        switch (ticket.requestStatus) {
          case 'Approved':
            statusColor = Colors.green;
            break;
          case 'Rejected':
            statusColor = Colors.red;
            break;
          case 'Pending':
          default:
            statusColor = Colors.orange;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_remove_outlined,
                          color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Account Deletion Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.requestStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.requestStatus == 'Pending'
                    ? 'Your request is pending Admin review and approval.'
                    : (ticket.requestStatus == 'Approved'
                        ? 'Your account deletion request has been approved and processed.'
                        : 'Your account deletion request was rejected by Admin.'),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedText),
              ),
              if (ticket.reason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Reason: "${ticket.reason}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAccountDeletionDialog(CreatorProfile profile) async {
    final supportRepo = serviceLocator<SupportRepository>();

    final latestTicket =
        await supportRepo.watchLatestDeletionRequest(profile.uid).first;

    if (!mounted) return;

    if (latestTicket != null &&
        latestTicket.requestStatus == 'Pending' &&
        latestTicket.isOpen) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Active Request Pending'),
          content: const Text(
            'You already have an active pending account deletion request under Admin review. Please wait for Admin approval or response.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Request Account Deletion'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitting this request will create an official support ticket for Admin review. Your account will NOT be deleted immediately and will only be executed after Admin approval.',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Why do you want to delete your account? *',
                    hintText: 'Enter reason for requesting account deletion...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Please enter a reason for account deletion.';
                    }
                    if (trimmed.length < 5) {
                      return 'Reason must be at least 5 characters.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text.trim();
                try {
                  await supportRepo.createAccountDeletionRequest(
                    userId: profile.uid,
                    userName: profile.name,
                    reason: reason,
                  );
                  if (mounted) {
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Account deletion request submitted for Admin review.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}
