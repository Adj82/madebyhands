import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';
import 'package:madebyhands/init_dependencies.dart';

class SupportTicketsView extends StatefulWidget {
  const SupportTicketsView({super.key});

  @override
  State<SupportTicketsView> createState() => _SupportTicketsViewState();
}

class _SupportTicketsViewState extends State<SupportTicketsView> {
  final SupportRepository _repository = serviceLocator<SupportRepository>();
  late final Stream<List<SupportTicket>> _tickets = _repository.watchAllTickets();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupportTicket>>(
      stream: _tickets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load tickets: ${friendlyErrorMessage(snapshot.error!)}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final tickets = [...snapshot.data!]
          ..sort((a, b) {
            if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
        if (tickets.isEmpty) {
          return const Center(
            child: Text('No support tickets yet.', style: TextStyle(color: AppColors.mutedText)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(15),
          itemCount: tickets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return SupportTicketTile(
              ticket: ticket,
              showRequester: true,
              onTap: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthSuccess) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupportConversationPage(
                      ticket: ticket,
                      repository: _repository,
                      senderId: authState.user.uid,
                      senderRole: 'admin',
                      canResolve: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
