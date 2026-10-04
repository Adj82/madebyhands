import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

class BuyerTermsAndConditionsPage extends StatelessWidget {
  const BuyerTermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('Terms & Conditions')),
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
                  'MadeByHands Buyer Terms & Conditions',
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
