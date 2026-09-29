import 'package:flutter/material.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';

class SupportCenterPage extends StatelessWidget {
  final UserEntity user;
  final SupportRepository repository;

  const SupportCenterPage({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newTicket(context),
        icon: const Icon(Icons.add),
        label: const Text('Raise ticket'),
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: repository.watchUserTickets(user.uid),
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
            return const Center(
              child: Text(
                'No support tickets yet. Tap “Raise ticket” to begin.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: tickets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    ticket.isOpen ? Icons.help_outline : Icons.check_circle,
                    color: ticket.isOpen ? Colors.orange : Colors.green,
                  ),
                  title: Text(ticket.subject),
                  subtitle: Text(
                    ticket.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(ticket.isOpen ? 'Open' : 'Resolved'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupportConversationPage(
                        ticket: ticket,
                        repository: repository,
                        senderId: user.uid,
                        senderRole: user.role,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _newTicket(BuildContext context) async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Raise a support ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: message,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (subject.text.trim().isNotEmpty &&
                  message.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (submitted != true || !context.mounted) return;
    try {
      await repository.createTicket(
        userId: user.uid,
        userRole: user.role,
        userName: user.name,
        subject: subject.text.trim(),
        message: message.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create ticket: $error')),
        );
      }
    }
  }
}

class SupportConversationPage extends StatefulWidget {
  final SupportTicket ticket;
  final SupportRepository repository;
  final String senderId;
  final String senderRole;
  final bool canResolve;

  const SupportConversationPage({
    super.key,
    required this.ticket,
    required this.repository,
    required this.senderId,
    required this.senderRole,
    this.canResolve = false,
  });

  @override
  State<SupportConversationPage> createState() =>
      _SupportConversationPageState();
}

class _SupportConversationPageState extends State<SupportConversationPage> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject),
        actions: [
          if (widget.canResolve && widget.ticket.isOpen)
            IconButton(
              tooltip: 'Resolve ticket',
              onPressed: () async {
                await widget.repository.resolveTicket(widget.ticket.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.ticket.isAccountDeletionRequest)
            _buildAccountDeletionHeader(),
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: widget.repository.watchMessages(widget.ticket.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    final mine = item.senderRole == widget.senderRole;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        color: mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(item.message),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (widget.ticket.isOpen)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    _message.clear();
    await widget.repository.sendMessage(
      ticketId: widget.ticket.id,
      senderId: widget.senderId,
      senderRole: widget.senderRole,
      message: text,
    );
  }

  Widget _buildAccountDeletionHeader() {
    final ticket = widget.ticket;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Account Deletion Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (ticket.requestStatus == 'Approved'
                          ? Colors.green
                          : (ticket.requestStatus == 'Rejected'
                              ? Colors.red
                              : Colors.orange))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.requestStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: ticket.requestStatus == 'Approved'
                        ? Colors.green
                        : (ticket.requestStatus == 'Rejected'
                            ? Colors.red
                            : Colors.orange.shade800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Creator: ${ticket.userName} (${ticket.userId})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            'Reason for deletion:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ticket.reason.isNotEmpty ? ticket.reason : ticket.lastMessage,
            style: const TextStyle(fontSize: 14),
          ),
          if (widget.canResolve &&
              widget.ticket.isOpen &&
              ticket.requestStatus == 'Pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rejectDeletion,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approveDeletion,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Approve Deletion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _approveDeletion() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Text(
          'Are you sure you want to approve and execute account deletion for "${widget.ticket.userName}"?\n\nThis will deactivate their profile, user role, and all product listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await widget.repository.approveAccountDeletion(
                ticketId: widget.ticket.id,
                creatorUid: widget.ticket.userId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion approved and executed.'),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Deactivate'),
          ),
        ],
      ),
    );
  }

  void _rejectDeletion() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Deletion Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejecting account deletion *',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(dialogCtx);
              await widget.repository.rejectAccountDeletion(
                ticketId: widget.ticket.id,
                creatorUid: widget.ticket.userId,
                rejectionReason: text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion request rejected.'),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
  }
}
