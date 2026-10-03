import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/product_review_page.dart';
import 'package:madebyhands/features/admin/presentation/views/verification_view.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
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
                  const SizedBox(height: 25),
                  const _SectionHeader(title: 'Listed Products'),
                ],
              ),
            ),
            _CreatorProductsSection(creatorUid: profile.uid),
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

/// Products this creator has listed in the app, so an admin reviewing their
/// profile can see their catalogue alongside bio/story/portfolio/documents.
///
/// Products store the owning creator under either `creatorUid` or
/// `creatorId` (both spellings exist in live data — see CLAUDE.md), so this
/// matches against both rather than relying on a single Firestore `where`.
class _CreatorProductsSection extends StatelessWidget {
  final String creatorUid;
  const _CreatorProductsSection({required this.creatorUid});

  @override
  Widget build(BuildContext context) {
    if (creatorUid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Could not load products: ${snapshot.error}',
              style: const TextStyle(color: AppColors.mutedText),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final products = snapshot.data!.docs
            .where((doc) {
              final data = doc.data();
              return data['creatorUid'] == creatorUid ||
                  data['creatorId'] == creatorUid;
            })
            .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No products listed yet.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 230,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _CreatorProductTile(product: products[index]),
        );
      },
    );
  }
}

class _CreatorProductTile extends StatelessWidget {
  final CreatorProduct product;
  const _CreatorProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isApproved = product.status == 'Approved';
    final isRejected = product.status == 'Rejected';
    final statusColor = isApproved
        ? (product.isActive ? Colors.green.shade700 : Colors.orange.shade800)
        : isRejected
        ? Colors.red
        : AppColors.mutedText;
    final statusLabel = isApproved
        ? (product.isActive ? 'LIVE' : 'APPROVED · NOT LIVE')
        : isRejected
        ? 'REJECTED'
        : 'PENDING';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductReviewPage(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.outline,
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, size: 36, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${product.price.round()} · Stock ${product.stock}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
