import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class BuyerTermsAndConditionsPage extends StatelessWidget {
  const BuyerTermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Terms & Conditions',
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
                  'MadeByHands Buyer Terms & Conditions',
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
                  title: '1. Account Usage & Registration',
                  content:
                      'By creating a buyer account on MadeByHands, you agree to provide accurate registration information and maintain the security of your account credentials. You are responsible for all activities occurring under your account.',
                ),
                _buildSection(
                  title: '2. Orders & Payment Processing',
                  content:
                      'All orders placed on MadeByHands represent an agreement to purchase handmade items directly from verified independent creators. Prices, shipping fees, and applicable taxes are displayed prior to order confirmation.',
                ),
                _buildSection(
                  title: '3. Product Information & Artisanal Variations',
                  content:
                      'Because products listed on MadeByHands are handcrafted by individual artisans, slight variations in color, texture, dimensions, or finish are natural characteristics of handmade craftsmanship and do not constitute product defects.',
                ),
                _buildSection(
                  title: '4. Intellectual Property & Brand Rights',
                  content:
                      'All platform trademarks, design elements, logos, and original artisan photography displayed on MadeByHands are protected by intellectual property laws and belong to MadeByHands or their respective creator owners.',
                ),
                _buildSection(
                  title: '5. Prohibited Conduct',
                  content:
                      'Buyers are prohibited from attempting fraudulent transactions, submitting abusive or defamatory reviews, manipulating feedback systems, or interfering with platform operations and security.',
                ),
                _buildSection(
                  title: '6. Policy Updates & Contact',
                  content:
                      'MadeByHands reserves the right to modify these terms as platform services evolve. Continued use of the app constitutes acceptance of any updated terms.',
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
