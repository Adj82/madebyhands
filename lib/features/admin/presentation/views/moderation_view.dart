import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/widgets/admin_chat_message.dart';

class ModerationView extends StatelessWidget {
  const ModerationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.red),
            title: Text('Report #$index: Contact Info Exchange'),
            subtitle: const Text('Reported by System on Conversation #CRT-BYR-102'),
            trailing: TextButton(
              onPressed: () => _showChatModeration(context, index),
              child: const Text('Review Chat'),
            ),
          ),
        );
      },
    );
  }

  void _showChatModeration(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Moderation Review', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('System flagged potential contact sharing in this chat:',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const Column(
                  children: [
                    AdminChatMessage(sender: 'Artisan', message: 'Hello! Thanks for your order.', isFlagged: false),
                    AdminChatMessage(sender: 'Buyer', message: 'Can we talk on WhatsApp? 9876543210', isFlagged: true),
                    AdminChatMessage(sender: 'Artisan', message: 'I am not sure if that is allowed here.', isFlagged: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ignore')),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning sent to user.')));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Warn User'),
          ),
        ],
      ),
    );
  }
}
