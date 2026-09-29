import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MadeByHands Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: September 2026',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. Information We Collect',
              content:
                  'We collect information necessary for creator onboarding, verification documents (Government ID, business address, contact photos), portfolio images, and bank/payout credentials.',
            ),
            _buildSection(
              title: '2. How We Use Your Data',
              content:
                  'Your profile data powers your public storefront. Verification files are reviewed strictly by authorized administrators and are never shared publicly.',
            ),
            _buildSection(
              title: '3. Data Security & Storage',
              content:
                  'All creator records are securely stored on Firebase Firestore and Cloud Storage with encrypted transit and granular access controls.',
            ),
            _buildSection(
              title: '4. Rights & Account Deletion',
              content:
                  'Creators may request account deactivation or export of their data by contacting support or initiating account settings requests.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
