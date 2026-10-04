import 'package:madebyhands/features/admin/domain/entities/admin_log_entry.dart';

/// The admin activity log. Writing an entry is deliberately best-effort: a
/// failure to log must never undo or block the admin action itself.
abstract interface class AdminLogRepository {
  /// Records that the signed-in admin did something. Never throws.
  Future<void> log({
    required AdminLogCategory category,
    required String action,
    required String summary,
    String targetId = '',
  });

  /// Newest entries first.
  Stream<List<AdminLogEntry>> watchLogs({int limit = 300});
}
