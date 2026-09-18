import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/widgets/doc_item.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Artisan Name $index',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Pottery & Ceramics', style: TextStyle(color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    const Chip(label: Text('Pending'), backgroundColor: Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                    'Bio: "Passionate ceramicist with 10 years of experience crafting handmade vases and dinnerware."',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showDocumentReview(context, index),
                      child: const Text('View Documents'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Verify'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDocumentReview(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verification Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Artisan ID: MBH-CRT-00$index', style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                children: [
                  DocItem(title: 'Identity Proof (PAN/Aadhar)', subtitle: 'Uploaded on 12 Sep 2026'),
                  const SizedBox(height: 15),
                  DocItem(title: 'Address Proof', subtitle: 'Utility Bill / Bank Statement'),
                  const SizedBox(height: 15),
                  DocItem(title: 'Portfolio Link', subtitle: 'https://behance.net/artisan$index', isLink: true),
                ],
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Reject Application'))),
                const SizedBox(width: 15),
                Expanded(
                    child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Approve Creator'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
