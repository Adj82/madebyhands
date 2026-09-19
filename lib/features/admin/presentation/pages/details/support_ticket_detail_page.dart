import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class SupportTicketDetailPage extends StatelessWidget {
  final int index;
  const SupportTicketDetailPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #78$index'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.check_circle_outline, color: Colors.green)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 30),
                const Text('User Message', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                const SizedBox(height: 10),
                _buildBubble(
                  context,
                  message: 'I made a payment for the ceramic pot but the order still shows as pending. Can you please check?',
                  isUser: true,
                  time: '10:30 AM',
                ),
                const SizedBox(height: 20),
                const Text('Admin Response', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                const SizedBox(height: 10),
                _buildBubble(
                  context,
                  message: 'Hello! I am looking into your transaction. It seems there is a delay from the payment gateway side.',
                  isUser: false,
                  time: '11:15 AM',
                ),
              ],
            ),
          ),
          _buildReplyBar(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withAlpha(50)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: Open', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('Assigned to: Support Agent #4', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, {required String message, required bool isUser, required String time}) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: isUser ? Border.all(color: AppColors.outline) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: isUser ? AppColors.text : Colors.white, height: 1.4),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(color: isUser ? AppColors.mutedText : Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
