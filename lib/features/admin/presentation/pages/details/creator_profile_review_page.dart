import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class CreatorProfileReviewPage extends StatelessWidget {
  final int index;
  const CreatorProfileReviewPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Profile Review')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 60, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 60, color: Colors.white)),
            const SizedBox(height: 15),
            const Text('Artisan Name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Jaipur, Rajasthan', style: TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Creator Story'),
                  const Text(
                    'I started pottery at the age of 12, learning from my grandfather. My goal is to keep the traditional Rajasthani patterns alive while bringing a modern aesthetic to home decor.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  const _SectionHeader(title: 'Portfolio Showcase'),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (context, i) => Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const _SectionHeader(title: 'Social Presence'),
                  const _SocialItem(icon: Icons.link, label: 'Instagram: @artisan_handcrafts'),
                  const _SocialItem(icon: Icons.link, label: 'Behance: portfolio/artisan'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('NEEDS MORE INFO'))),
              const SizedBox(width: 15),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('APPROVE ARTISAN'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
}

class _SocialItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(icon, size: 16, color: AppColors.mutedText), const SizedBox(width: 10), Text(label)]),
    );
  }
}
