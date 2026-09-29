import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class BuyerPrivacyPolicyPage extends StatelessWidget {
  const BuyerPrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B261D),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MadeByHands Buyer Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B261D),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Effective Date: September 2026',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
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
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
