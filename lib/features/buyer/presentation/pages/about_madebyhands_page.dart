import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_privacy_policy_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_terms_and_conditions_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

class AboutMadeByHandsPage extends StatelessWidget {
  const AboutMadeByHandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('About MadeByHands')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              decoration: BoxDecoration(
                color: BuyerColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BuyerColors.line, width: 1.5),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/main_page_elements/mbh_logo.png',
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.palette,
                      size: 48,
                      color: BuyerColors.maroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const BuyerHeading('MadeByHands', size: 22),
                  const SizedBox(height: 2),
                  const Text(
                    'Artisan Marketplace',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: BuyerColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'MadeByHands connects buyers with authentic independent artisans and creators across India. Our mission is to preserve traditional craftsmanship, empower creative entrepreneurship, and deliver unique handmade pieces with a story.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: BuyerColors.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const BuyerHeading('Legal & Information'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms & Conditions'),
                subtitle: const Text(
                  'Read buyer rules, order guidelines & policies',
                ),
                trailing: const Icon(Icons.chevron_right),
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                subtitle: const Text(
                  'View data collection, security & buyer rights',
                ),
                trailing: const Icon(Icons.chevron_right),
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
