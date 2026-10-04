import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_log_entry.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_log_repository.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/init_dependencies.dart';

/// Super-admin activity log: every change an admin or manager made, newest
/// first, with who made it.
class AdminLogsView extends StatelessWidget {
  /// Only for tests: replaces the live Firestore stream.
  final Stream<List<AdminLogEntry>>? logs;

  const AdminLogsView({super.key, this.logs});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthSuccess && authState.user.isSuperAdmin;
    if (!isSuperAdmin) return const _RestrictedNotice();
    return _LogsBody(logs: logs);
  }
}

class _RestrictedNotice extends StatelessWidget {
  const _RestrictedNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 56, color: Colors.orange.shade800),
            const SizedBox(height: 20),
            const Text(
              'Activity logs are restricted to super admins',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Only a super admin can see the record of what admins and managers have changed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsBody extends StatefulWidget {
  final Stream<List<AdminLogEntry>>? logs;

  const _LogsBody({this.logs});

  @override
  State<_LogsBody> createState() => _LogsBodyState();
}

class _LogsBodyState extends State<_LogsBody> {
  // Firestore streams are broadcast without replay, so keep this one in State.
  late final Stream<List<AdminLogEntry>> _logs =
      widget.logs ?? serviceLocator<AdminLogRepository>().watchLogs();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  AdminLogCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search by action, admin or details',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _chip('All', null),
              for (final category in AdminLogCategory.values)
                _chip(category.label, category),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AdminLogEntry>>(
            stream: _logs,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load the activity log: ${friendlyErrorMessage(snapshot.error!)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data!;
              final entries = all
                  .where(
                    (entry) =>
                        (_category == null || entry.category == _category) &&
                        entry.matches(_query),
                  )
                  .toList();
              if (entries.isEmpty) {
                return _EmptyLog(hasEntries: all.isNotEmpty);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final previous = index == 0 ? null : entries[index - 1];
                  final showDay =
                      previous == null ||
                      !_sameDay(previous.createdAt, entry.createdAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDay) _DayHeader(date: entry.createdAt),
                      _LogTile(entry: entry),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, AdminLogCategory? category) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == category,
      onSelected: (_) => setState(() => _category = category),
    ),
  );

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EmptyLog extends StatelessWidget {
  final bool hasEntries;

  const _EmptyLog({required this.hasEntries});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              hasEntries ? 'No matching activity' : 'No activity yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasEntries
                  ? 'Try a different search or category.'
                  : 'Changes made by admins and managers will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime? date;

  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final day = date;
    final now = DateTime.now();
    String label;
    if (day == null) {
      label = 'Just now';
    } else if (day.year == now.year &&
        day.month == now.month &&
        day.day == now.day) {
      label = 'Today';
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      label =
          day.year == yesterday.year &&
              day.month == yesterday.month &&
              day.day == yesterday.day
          ? 'Yesterday'
          : DateFormat('d MMM yyyy').format(day);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppColors.mutedText,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AdminLogEntry entry;

  const _LogTile({required this.entry});

  static IconData _icon(AdminLogCategory category) => switch (category) {
    AdminLogCategory.creator => Icons.verified_user_outlined,
    AdminLogCategory.product => Icons.shopping_bag_outlined,
    AdminLogCategory.order => Icons.receipt_long_outlined,
    AdminLogCategory.payout => Icons.account_balance_wallet_outlined,
    AdminLogCategory.category => Icons.category_outlined,
    AdminLogCategory.user => Icons.people_outline,
    AdminLogCategory.access => Icons.admin_panel_settings_outlined,
    AdminLogCategory.settings => Icons.tune,
  };

  @override
  Widget build(BuildContext context) {
    final time = entry.createdAt == null
        ? 'Just now'
        : DateFormat('h:mm a').format(entry.createdAt!);
    final role = entry.actorRole.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                _icon(entry.category),
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.summary,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${entry.actorLabel}${role.isEmpty ? '' : ' ($role)'}  ·  $time',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
