import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';

class SupportTicketDetailPage extends StatelessWidget {
  final AdminSupportTicket ticket;
  const SupportTicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.id.substring(0, 5)}'),
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
                  message: ticket.lastMessage.isEmpty ? 'No message content.' : ticket.lastMessage,
                  isUser: true,
                  time: 'Recently',
                ),
                const SizedBox(height: 20),
                const Text('Admin Response', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                const SizedBox(height: 10),
                _buildBubble(
                  context,
                  message: 'Hello! Our team is looking into this.',
                  isUser: false,
                  time: 'Just now',
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
        color: ticket.isOpen ? Colors.orange.withAlpha(20) : Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ticket.isOpen ? Colors.orange.withAlpha(50) : Colors.green.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(ticket.isOpen ? Icons.info_outline : Icons.check_circle_outline, color: ticket.isOpen ? Colors.orange : Colors.green),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${ticket.isOpen ? 'Open' : 'Resolved'}', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: ticket.isOpen ? Colors.orange : Colors.green)),
                const Text('Assigned to: Support Team', style: TextStyle(fontSize: 12)),
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
