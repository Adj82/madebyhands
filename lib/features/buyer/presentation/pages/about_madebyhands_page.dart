import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_privacy_policy_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_terms_and_conditions_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class AboutMadeByHandsPage extends StatelessWidget {
  const AboutMadeByHandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'About MadeByHands',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B261D),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B261D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.back_hand_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MadeByHands',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B261D),
                              ),
                            ),
                            Text(
                              'Artisan Marketplace',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'MadeByHands connects buyers with authentic independent artisans and creators across India. Our mission is to preserve traditional craftsmanship, empower creative entrepreneurship, and deliver unique handmade pieces with a story.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Legal & Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B261D),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              color: const Color(0xFFFAF6EE).withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF8B261D),
                ),
                title: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B261D),
                  ),
                ),
                subtitle: const Text(
                  'Read buyer rules, order guidelines & policies',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8B261D),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BuyerTermsAndConditionsPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              color: const Color(0xFFFAF6EE).withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF8B261D),
                ),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B261D),
                  ),
                ),
                subtitle: const Text(
                  'View data collection, security & buyer rights',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8B261D),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BuyerPrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
