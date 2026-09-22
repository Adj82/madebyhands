import 'package:flutter/material.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';
import 'package:madebyhands/init_dependencies.dart';

class SupportTicketsView extends StatelessWidget {
  const SupportTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = serviceLocator<SupportRepository>();
    return StreamBuilder<List<SupportTicket>>(
      stream: repository.watchAllTickets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load tickets: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tickets = snapshot.data!;
        if (tickets.isEmpty) {
          return const Center(child: Text('No support tickets found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  ticket.isOpen ? Icons.help_center : Icons.check_circle,
                  color: ticket.isOpen ? Colors.orange : Colors.green,
                ),
                title: Text(ticket.subject),
                subtitle: Text(
                  '${ticket.userName} (${ticket.userRole})\n${ticket.lastMessage}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(ticket.isOpen ? 'Open' : 'Resolved'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupportConversationPage(
                      ticket: ticket,
                      repository: repository,
                      senderId: 'admin',
                      senderRole: 'admin',
                      canResolve: true,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
