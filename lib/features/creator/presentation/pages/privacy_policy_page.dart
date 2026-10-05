import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B261D).withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MadeByHands Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B261D),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Last updated: September 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8F82),
                  ),
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
              ],
            ),
          ),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF2D3128),
            ),
          ),
        ],
      ),
    );
  }
}
