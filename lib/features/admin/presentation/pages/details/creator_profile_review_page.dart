import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/views/verification_view.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class CreatorProfileReviewPage extends StatelessWidget {
  final CreatorProfile profile;
  const CreatorProfileReviewPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Profile Review')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
              child: profile.profileImage.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                profile.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Text(profile.location, style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 6),
            Text(
              'Verification: ${profile.verificationStatus}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.bio.isNotEmpty) ...[
                    const _SectionHeader(title: 'Bio'),
                    Text(profile.bio, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 25),
                  ],
                  const _SectionHeader(title: 'Creator Story'),
                  Text(
                    profile.story.isEmpty ? 'No story provided.' : profile.story,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  const _SectionHeader(title: 'Portfolio Showcase'),
                  if (profile.portfolio.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.portfolio.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              profile.portfolio[i],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 150,
                                color: AppColors.outline,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('No portfolio images uploaded.'),
                  const SizedBox(height: 25),
                  const _SectionHeader(title: 'Social Presence'),
                  if (profile.socialLinks.isNotEmpty)
                    ...profile.socialLinks.map((link) => _SocialItem(icon: Icons.link, label: link))
                  else
                    const Text('No social links provided.'),
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
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => showVerificationDocuments(context, profile),
                  child: const Text('Documents'),
                ),
              ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(label)),
        ],
      ),
    );
  }
}
