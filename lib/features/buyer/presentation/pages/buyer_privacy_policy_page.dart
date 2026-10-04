import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

class BuyerPrivacyPolicyPage extends StatelessWidget {
  const BuyerPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Privacy Policy')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
            decoration: BoxDecoration(
              color: BuyerColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BuyerColors.line, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BuyerHeading(
                  'MadeByHands Buyer Privacy Policy',
                  size: 19,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Effective Date: September 2026',
                  style: TextStyle(fontSize: 12, color: BuyerColors.muted),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 18),
                _buildSection(
                  title: '1. Data Collection',
                  content:
                      'We collect personal information necessary to deliver handmade orders, including your name, email address, phone number, saved delivery addresses, cart selections, and wishlist favorites.',
                ),
                _buildSection(
                  title: '2. Data Storage & Security',
                  content:
                      'Your data is securely stored on encrypted Google Cloud & Firebase Firestore databases with industry-standard access controls and transport security protocols.',
                ),
                _buildSection(
                  title: '3. Third-Party Services & Fulfillment',
                  content:
                      'Necessary order details (recipient name, shipping address, contact phone) are shared securely with assigned creators and authorized delivery logistics partners solely for order fulfillment.',
                ),
                _buildSection(
                  title: '4. Security Measures',
                  content:
                      'We implement rigorous physical, technical, and managerial safeguards to protect your personal information against unauthorized access, loss, or alteration.',
                ),
                _buildSection(
                  title: '5. Policy Updates & Your Rights',
                  content:
                      'You may access, update, or request deletion of your account and saved address records at any time through the Account Settings screen.',
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuyerHeading(title, size: 15),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: BuyerColors.body,
            ),
          ),
        ],
      ),
    );
  }
}
