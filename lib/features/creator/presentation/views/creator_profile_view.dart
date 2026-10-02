import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_onboarding_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/manage_bank_account_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/privacy_policy_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/terms_and_conditions_page.dart';

class CreatorProfileView extends StatefulWidget {
  final CreatorProfile profile;
  final UserEntity user;

  const CreatorProfileView({super.key, required this.profile, required this.user});

  @override
  State<CreatorProfileView> createState() => _CreatorProfileViewState();
}

class _CreatorProfileViewState extends State<CreatorProfileView> {
  void _push(Widget page) {
    final bloc = context.read<CreatorBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      builder: (context, state) {
        final profile = state.profile ?? widget.profile;
        return ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const SizedBox(height: 10),
            _buildProfileCard(profile),
            const SizedBox(height: 24),
            _buildActionItem(
              icon: Icons.edit_outlined,
              title: 'Edit creator profile',
              subtitle: 'Update bio, craft category, story, links and portfolio',
              onTap: () => _push(
                CreatorOnboardingPage(user: widget.user, existingProfile: profile),
              ),
            ),
            _buildVerificationActionItem(profile),
            _buildActionItem(
              icon: Icons.account_balance_outlined,
              title: 'Payout details',
              subtitle: 'Bank account and UPI used for your earnings',
              onTap: () => _push(ManageBankAccountPage(profile: profile)),
            ),
            _buildActionItem(
              icon: Icons.description_outlined,
              title: 'Terms & conditions',
              subtitle: 'Read artisan platform terms and rules',
              onTap: () => _push(const TermsAndConditionsPage()),
            ),
            _buildActionItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              subtitle: 'How we protect your data',
              onTap: () => _push(const PrivacyPolicyPage()),
            ),
            _buildActionItem(
              icon: Icons.delete_forever_outlined,
              title: 'Delete account',
              subtitle: 'Permanently delete your creator account, products and studio data',
              badgeColor: Colors.red,
              onTap: () => _confirmAccountDeletion(profile),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildVerificationActionItem(CreatorProfile profile) {
    if (profile.isVerified) {
      return _buildActionItem(
        icon: Icons.verified_outlined,
        title: 'Creator Verification',
        subtitle: 'Verified Artisan Account Active',
        badgeColor: Colors.green,
        onTap: () => _push(CreatorVerificationPage(profile: profile)),
      );
    } else if (profile.isUnderReview) {
      return _buildActionItem(
        icon: Icons.hourglass_top_outlined,
        title: 'Verification Under Review',
        subtitle: 'Documents submitted. An admin is reviewing your application.',
        badgeColor: Colors.orange,
        onTap: () => _push(CreatorVerificationPage(profile: profile)),
      );
    } else if (profile.isVerificationRejected) {
      return _buildActionItem(
        icon: Icons.error_outline,
        title: 'Verification Needs Attention',
        subtitle: profile.verificationNote.isNotEmpty
            ? 'Rejected: ${profile.verificationNote}'
            : 'Tap to update documents and resubmit',
        badgeColor: Colors.red,
        onTap: () => _push(CreatorVerificationPage(profile: profile)),
      );
    } else {
      return _buildActionItem(
        icon: Icons.verified_user_outlined,
        title: 'Get Verified',
        subtitle: 'Submit government ID & photo to start listing products',
        badgeColor: AppColors.primary,
        onTap: () => _push(CreatorVerificationPage(profile: profile)),
      );
    }
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            profile.category,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 6),
          _VerificationBadge(profile: profile),
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
          'Your studio profile, products, payout details and notifications will be permanently deleted. '
          'Finish or reject any open orders first. This cannot be undone.\n\n'
          'For security you may be asked to sign in again before deleting.',
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

class _VerificationBadge extends StatelessWidget {
  final CreatorProfile profile;

  const _VerificationBadge({required this.profile});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = profile.isVerified
        ? ('Verified', Colors.green.shade700)
        : profile.isUnderReview
        ? ('Under review', Colors.orange.shade800)
        : profile.isVerificationRejected
        ? ('Verification rejected', Colors.red)
        : ('Not verified', Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
