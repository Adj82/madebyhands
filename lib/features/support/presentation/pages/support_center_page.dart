import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';

class SupportCenterPage extends StatefulWidget {
  final UserEntity user;
  final SupportRepository repository;

  /// Wraps the conversation page this screen pushes, so a panel with its own
  /// look (the buyer's parchment theme) carries it onto that route too.
  final Widget Function(Widget page)? pageWrapper;

  const SupportCenterPage({
    super.key,
    required this.user,
    required this.repository,
    this.pageWrapper,
  });

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  late final Stream<List<SupportTicket>> _tickets = widget.repository
      .watchUserTickets(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _newTicket,
        icon: const Icon(Icons.add),
        label: const Text('Raise ticket'),
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: _tickets,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load tickets: ${friendlyErrorMessage(snapshot.error!)}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data!;
          if (tickets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No support tickets yet. Tap “Raise ticket” to get help.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            itemCount: tickets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => SupportTicketTile(
              ticket: tickets[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) {
                    final page = SupportConversationPage(
                      ticket: tickets[index],
                      repository: widget.repository,
                      senderId: widget.user.uid,
                      senderRole: widget.user.role,
                    );
                    return widget.pageWrapper?.call(page) ?? page;
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _newTicket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Raise a support ticket'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: subject,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter a subject.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: message,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Describe the issue.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.createTicket(
        userId: widget.user.uid,
        userRole: widget.user.role,
        userName: widget.user.name,
        subject: subject.text.trim(),
        message: message.text.trim(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Support ticket created.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }
}

/// A ticket row shared by the user and admin ticket lists.
class SupportTicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  final bool showRequester;

  const SupportTicketTile({
    super.key,
    required this.ticket,
    required this.onTap,
    this.showRequester = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ticket.isOpen ? Colors.orange : Colors.green;
    final requester = '${ticket.userName} (${ticket.userRole})';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            ticket.isOpen ? Icons.help_outline : Icons.check_circle_outline,
            color: color,
          ),
        ),
        title: Text(
          ticket.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          showRequester
              ? '$requester\n${ticket.lastMessage}'
              : ticket.lastMessage,
          maxLines: showRequester ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        trailing: Text(
          ticket.isOpen ? 'Open' : 'Resolved',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
      ),
    );
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
  late final Stream<List<SupportMessage>> _messages = widget.repository
      .watchMessages(widget.ticket.id);
  late bool _isOpen = widget.ticket.isOpen;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool _isMine(SupportMessage message) {
    if (message.senderId == widget.senderId) return true;
    // Older admin replies were stored with a placeholder sender id.
    return widget.canResolve && message.senderRole == 'admin';
  }

  Future<void> _resolve() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.resolveTicket(widget.ticket.id);
      if (!mounted) return;
      setState(() => _isOpen = false);
      messenger.showSnackBar(const SnackBar(content: Text('Ticket resolved.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.sendMessage(
        ticketId: widget.ticket.id,
        senderId: widget.senderId,
        senderRole: widget.senderRole,
        message: text,
      );
      _message.clear();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ticket.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.canResolve && _isOpen)
            IconButton(
              tooltip: 'Mark as resolved',
              onPressed: _resolve,
              icon: const Icon(Icons.check_circle_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(friendlyErrorMessage(snapshot.error!)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final item = messages[messages.length - 1 - index];
                    final mine = _isMine(item);
                    final colors = Theme.of(context).colorScheme;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        child: Card(
                          color: mine
                              ? Color.alphaBlend(
                                  colors.primary.withValues(alpha: 0.12),
                                  colors.surface,
                                )
                              : colors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    item.senderRole == 'admin'
                                        ? 'MadeByHands support'
                                        : widget.ticket.userName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                Text(item.message),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(item.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isOpen)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: _sending ? null : _send,
                      // Explicit, because an ambient IconTheme colour (the
                      // buyer theme sets one) otherwise replaces the filled
                      // button's default foreground.
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            )
          else
            const SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This ticket is resolved.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
