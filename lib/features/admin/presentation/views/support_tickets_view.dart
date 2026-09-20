import 'package:flutter/material.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/support_ticket_detail_page.dart';

class SupportTicketsView extends StatelessWidget {
  const SupportTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isOpen = index < 3;
        return Card(
          child: ListTile(
            leading: Icon(Icons.help_center, color: isOpen ? Colors.orange : Colors.green),
            title: Text('Support Ticket #78$index'),
            subtitle: Text('Issue: ${index % 2 == 0 ? 'Payment failed' : 'Product damaged'}'),
            trailing: Chip(
              label: Text(isOpen ? 'Open' : 'Resolved', style: const TextStyle(fontSize: 10)),
              backgroundColor: isOpen ? Colors.orange.withAlpha(50) : Colors.green.withAlpha(50),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SupportTicketDetailPage(index: index)),
            ),
          ),
        );
      },
    );
  }
}
