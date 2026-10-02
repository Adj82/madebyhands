import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/creator_profile_review_page.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _profiles =
      FirebaseFirestore.instance.collection('creator_profiles').snapshots();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _profiles,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Could not load creators: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final profiles = snapshot.data!.docs
                .map((doc) => CreatorProfileModel.fromJson(doc.data(), doc.id))
                .toList();
            List<CreatorProfile> withStatus(bool Function(String) test) =>
                profiles.where((p) => test(p.verificationStatus.trim())).toList();

            return TabBarView(
              children: [
                _ProfileList(
                  profiles: withStatus((s) => s == 'In-Process'),
                  emptyMessage: 'No verification requests waiting.',
                ),
                _ProfileList(
                  profiles: withStatus((s) => s == 'Verified'),
                  emptyMessage: 'No verified creators yet.',
                ),
                _ProfileList(
                  profiles: withStatus((s) => s == 'Rejected'),
                  emptyMessage: 'No rejected verifications.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  final List<CreatorProfile> profiles;
  final String emptyMessage;

  const _ProfileList({required this.profiles, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ProfileCard(profile: profiles[index]),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final CreatorProfile profile;

  const _ProfileCard({required this.profile});

  Color get _statusColor => switch (profile.verificationStatus) {
    'Verified' => Colors.green,
    'Rejected' => Colors.red,
    'In-Process' => Colors.orange,
    _ => AppColors.mutedText,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatorProfileReviewPage(profile: profile),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    backgroundImage: profile.profileImage.isNotEmpty
                        ? NetworkImage(profile.profileImage)
                        : null,
                    child: profile.profileImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          profile.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile.verificationStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => showVerificationDocuments(context, profile),
                    child: const Text('Review documents'),
                  ),
                  if (profile.verificationStatus != 'Rejected')
                    OutlinedButton(
                      onPressed: () => rejectCreatorWithReason(context, profile),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text(profile.isVerified ? 'Revoke' : 'Reject'),
                    ),
                  if (!profile.isVerified)
                    FilledButton(
                      onPressed: () => verifyCreator(context, profile),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Verify'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the creator's private verification documents with approve/reject
/// actions. Documents live in `creator_verifications/{uid}`; older profiles
/// stored them on the public profile, which is used as a fallback.
Future<void> showVerificationDocuments(BuildContext context, CreatorProfile profile) {
  final adminBloc = context.read<AdminBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.85,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('creator_verifications')
            .doc(profile.uid)
            .get(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          String field(String key, String fallback) {
            final value = data[key] as String?;
            return value == null || value.trim().isEmpty ? fallback : value;
          }

          final businessName = field('businessName', profile.businessName);
          final address = field('address', profile.address);
          final photo = field('latestPhoto', profile.latestPhoto);
          final idCard = field('idCard', profile.idCard);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.name,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            _DocSection(
                              title: 'Business / storefront name',
                              child: Text(businessName.isEmpty ? 'Not provided' : businessName),
                            ),
                            _DocSection(
                              title: 'Registered address',
                              child: Text(address.isEmpty ? 'Not provided' : address),
                            ),
                            _DocSection(title: 'Current photo', child: _DocImage(url: photo)),
                            _DocSection(title: 'PAN / identity card', child: _DocImage(url: idCard)),
                          ],
                        ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (profile.verificationStatus != 'Rejected')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final reason = await _askRejectionReason(
                              sheetContext,
                              revoking: profile.isVerified,
                            );
                            if (reason == null) return;
                            adminBloc.add(AdminRejectCreatorRequested(profile.uid, reason));
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: Text(profile.isVerified ? 'Revoke verification' : 'Reject'),
                        ),
                      ),
                    if (profile.verificationStatus != 'Rejected' && !profile.isVerified)
                      const SizedBox(width: 12),
                    if (!profile.isVerified)
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            adminBloc.add(AdminApproveCreatorRequested(profile.uid));
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Verify'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Verifies [profile] (also used to reverse an earlier rejection).
void verifyCreator(BuildContext context, CreatorProfile profile) =>
    context.read<AdminBloc>().add(AdminApproveCreatorRequested(profile.uid));

/// Rejects a pending request or revokes an existing verification. Revoking
/// also hides the creator's products until they are verified again.
Future<void> rejectCreatorWithReason(BuildContext context, CreatorProfile profile) async {
  final adminBloc = context.read<AdminBloc>();
  final reason = await _askRejectionReason(context, revoking: profile.isVerified);
  if (reason != null) adminBloc.add(AdminRejectCreatorRequested(profile.uid, reason));
}

Future<String?> _askRejectionReason(BuildContext context, {bool revoking = false}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(revoking ? 'Revoke verification' : 'Reject verification'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Reason shown to the creator *',
          hintText: 'e.g. ID photo is blurry, please re-upload',
          helperText: revoking
              ? 'Their products will be hidden from buyers.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.length >= 3) Navigator.pop(dialogContext, reason);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text(revoking ? 'Revoke' : 'Reject'),
        ),
      ],
    ),
  );
}

class _DocSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DocSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _DocImage extends StatelessWidget {
  final String url;

  const _DocImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Text('Not uploaded', style: TextStyle(color: AppColors.mutedText));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 50),
      ),
    );
  }
}
