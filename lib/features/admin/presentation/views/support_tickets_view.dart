import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final tickets = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: tickets.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: 400,
                      alignment: Alignment.center,
                      child: const Text('No support tickets found in database.'),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: ticket.isOpen ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                          child: Icon(
                            ticket.isOpen ? Icons.help_center_outlined : Icons.check_circle_outline,
                            color: ticket.isOpen ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Text(
                          ticket.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${ticket.userName} (${ticket.userRole})\n${ticket.lastMessage}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ticket.isOpen ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ticket.isOpen ? Colors.orange : Colors.green),
                          ),
                          child: Text(
                            ticket.isOpen ? 'Open' : 'Resolved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ticket.isOpen ? Colors.orange : Colors.green,
                            ),
                          ),
                        ),
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
                ),
        );
      },
    );
  }
}
