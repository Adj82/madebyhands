import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/creator_profile_review_page.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  @override
  void initState() {
    super.initState();
    context.read<CreatorBloc>().add(CreatorFetchAllProfiles());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      builder: (context, state) {
        List<CreatorProfile> profiles = [];
        bool isLoading = false;

        if (state is CreatorLoading) {
          isLoading = true;
        } else if (state is CreatorAllProfilesLoaded) {
          profiles = state.profiles
              .where((p) => p.verificationStatus != 'Verified')
              .toList();
        }

        return Material(
          color: Colors.transparent,
          child: Column(
            children: [
              if (isLoading) const LinearProgressIndicator(),
              Expanded(
                child: profiles.isEmpty && !isLoading
                    ? const Center(child: Text('No pending verifications'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(15),
                        itemCount: profiles.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => CreatorProfileReviewPage(profile: profile))),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: AppColors.primary,
                                          backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
                                          child: profile.profileImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 15),
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
                                                  style: const TextStyle(color: AppColors.mutedText)),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(profile.verificationStatus, style: const TextStyle(fontSize: 10)),
                                          backgroundColor: const Color(0xFFFFF3E0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showDocumentReview(context, profile),
                                          child: const Text('Review Docs'),
                                        ),
                                        const SizedBox(width: 10),
                                        FilledButton(
                                          onPressed: () {
                                            context.read<CreatorBloc>().add(
                                                CreatorUpdateVerificationStatus(uid: profile.uid, status: 'Verified'));
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentReview(BuildContext context, CreatorProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Verification Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Creator Name: ${profile.name}', style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  const Text('Registered Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
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
                    const Text('No photo uploaded'),
                  const SizedBox(height: 20),
                  const Text('PAN Card / Identity Card:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (profile.idCard.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(profile.idCard, height: 200, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
                    )
                  else
                    const Text('No ID Card photo uploaded'),
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
                      context.read<CreatorBloc>().add(
                            CreatorUpdateVerificationStatus(uid: profile.uid, status: 'Unverified'),
                          );
                      Navigator.pop(sheetContext);
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<CreatorBloc>().add(
                            CreatorUpdateVerificationStatus(uid: profile.uid, status: 'Verified'),
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
