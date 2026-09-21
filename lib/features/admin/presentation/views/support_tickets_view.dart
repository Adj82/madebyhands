import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/support_ticket_detail_page.dart';

class SupportTicketsView extends StatelessWidget {
  const SupportTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final tickets = state.supportTickets;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminBloc>().add(AdminLoadDataRequested());
          },
          child: tickets.isEmpty
              ? const Center(child: Text('No support tickets found.'))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(15),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.help_center, color: ticket.isOpen ? Colors.orange : Colors.green),
                        title: Text(ticket.subject),
                        subtitle: Text(ticket.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Chip(
                          label: Text(ticket.isOpen ? 'Open' : 'Resolved', style: const TextStyle(fontSize: 10)),
                          backgroundColor: ticket.isOpen ? Colors.orange.withAlpha(50) : Colors.green.withAlpha(50),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SupportTicketDetailPage(ticket: ticket)),
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
