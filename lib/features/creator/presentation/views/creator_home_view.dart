import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';

class CreatorHomeView extends StatelessWidget {
  final CreatorProfile profile;
  const CreatorHomeView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationSection(),
          const SizedBox(height: 20),
          _buildStorefrontProminent(context),
          const SizedBox(height: 30),
          _buildVerificationStatus(context),
          const SizedBox(height: 30),
          const Text(
            'Recent Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPerformanceSummary(),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: AppColors.accent),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Creator Studio!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Start by completing your verification to list products.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorefrontProminent(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.storefront,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surface,
                      backgroundImage: profile.profileImage.isNotEmpty
                          ? NetworkImage(profile.profileImage)
                          : null,
                      child: profile.profileImage.isEmpty
                          ? const Icon(Icons.person,
                              size: 30, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profile.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Storefront'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(BuildContext context) {
    final status = profile.verificationStatus;
    final isVerified = status == 'Verified';
    final isInProcess = status == 'In-Process';

    return InkWell(
      onTap: () {
        if (!isVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CreatorVerificationPage(profile: profile)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              isVerified
                  ? Icons.verified
                  : (isInProcess ? Icons.hourglass_top : Icons.error_outline),
              color: isVerified
                  ? Colors.green
                  : (isInProcess ? Colors.orange : Colors.red),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Officially Verified' : 'Verification Status',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isVerified
                        ? 'Your products are live for buyers.'
                        : (isInProcess
                            ? 'Under review by admin.'
                            : 'Required to start selling.'),
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            if (!isVerified && !isInProcess)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Sales',
            value: '₹0',
            icon: Icons.payments_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _SummaryCard(
            label: 'Active Orders',
            value: '0',
            icon: Icons.shopping_bag_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
