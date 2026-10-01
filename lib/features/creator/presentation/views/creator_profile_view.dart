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
                  title: 'Delete Account',
                  subtitle:
                      'Permanently delete your creator account, products, and studio data',
                  badgeColor: Colors.red,
                  onTap: () => _confirmAccountDeletion(profile),
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

  Future<void> _confirmAccountDeletion(CreatorProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Permanently Delete Account?',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your creator account? Your studio profile, products, bank details, and all associated data will be immediately and permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(AuthDeleteAccountRequested(profile.uid));
    }
  }
}
