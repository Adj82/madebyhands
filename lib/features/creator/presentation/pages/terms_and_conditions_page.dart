import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
            'Terms & Conditions',
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
                  'MadeByHands Creator Terms & Conditions',
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
                  title: '1. Creator Verification & Eligibility',
                  content:
                      'All artisans and creators must complete identity and business verification before listing products on MadeByHands. Verification ensures authenticity and protects buyers and genuine craftspeople.',
                ),
                _buildSection(
                  title: '2. Product Listings & Authenticity',
                  content:
                      'Products listed must be genuine handmade, artisanal, or creative goods crafted or designed by you. Reselling mass-produced commercial goods is strictly prohibited.',
                ),
                _buildSection(
                  title: '3. Order Fulfillment & Shipping',
                  content:
                      'Creators agree to process and ship orders within promised timeframes. Tracking/consignment details must be updated accurately upon dispatch.',
                ),
                _buildSection(
                  title: '4. Platform Economics & Payouts',
                  content:
                      'Platform commission and transaction fees are applied according to agreed platform economics. Net proceeds are credited upon order delivery completion.',
                ),
                _buildSection(
                  title: '5. Account Modifications & Re-Verification',
                  content:
                      'Updating critical business details or profile credentials may require administrative re-verification to maintain platform integrity.',
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
