import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/creator_profile_review_page.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('creator_profiles').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading profiles: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final docs = snapshot.data?.docs ?? [];
            final profiles = docs.map((doc) => CreatorProfileModel.fromJson(doc.data(), doc.id)).toList();

            List<CreatorProfile> pending = [];
            List<CreatorProfile> approved = [];
            List<CreatorProfile> rejected = [];

            for (var p in profiles) {
              final status = p.verificationStatus.trim();
              if (status == 'Verified') {
                approved.add(p);
              } else if (status == 'Rejected') {
                rejected.add(p);
              } else {
                pending.add(p);
              }
            }

            return TabBarView(
              children: [
                _buildProfileList(context, pending, 'No pending verifications (In-Process)'),
                _buildProfileList(context, approved, 'No approved creators'),
                _buildProfileList(context, rejected, 'No rejected or unverified creators'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileList(BuildContext context, List<CreatorProfile> profiles, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(AdminLoadDataRequested());
      },
      child: profiles.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 400,
                  alignment: Alignment.center,
                  child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              physics: const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => CreatorProfileReviewPage(profile: profile))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
                                child: profile.profileImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(profile.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(profile.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: profile.verificationStatus == 'Verified'
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : profile.verificationStatus == 'Rejected'
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  profile.verificationStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: profile.verificationStatus == 'Verified'
                                        ? Colors.green
                                        : profile.verificationStatus == 'Rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _showDocumentReview(context, profile),
                                child: const Text('Review Docs'),
                              ),
                              const SizedBox(width: 8),
                              if (profile.verificationStatus != 'Verified')
                                FilledButton(
                                  onPressed: () {
                                    context.read<AdminBloc>().add(
                                        AdminApproveCreatorRequested(profile.uid));
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Verify'),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDocumentReview(BuildContext context, CreatorProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Verification Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('Creator Name: ${profile.name}', style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  const Text('Registered Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(profile.address.isEmpty ? 'No address provided' : profile.address),
                  ),
                  const SizedBox(height: 20),
                  const Text('Latest Portrait Photo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (profile.latestPhoto.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(profile.latestPhoto, height: 200, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
                    )
                  else
                    const Text('No photo uploaded', style: TextStyle(color: AppColors.mutedText)),
                  const SizedBox(height: 20),
                  const Text('PAN Card / Identity Card:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (profile.idCard.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(profile.idCard, height: 200, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
                    )
                  else
                    const Text('No ID Card photo uploaded', style: TextStyle(color: AppColors.mutedText)),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AdminBloc>().add(
                            AdminRejectCreatorRequested(profile.uid),
                          );
                      Navigator.pop(sheetContext);
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<AdminBloc>().add(
                            AdminApproveCreatorRequested(profile.uid),
                          );
                      Navigator.pop(sheetContext);
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Approve & Verify'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
