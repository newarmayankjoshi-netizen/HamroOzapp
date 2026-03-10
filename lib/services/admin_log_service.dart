import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLogService {
  /// Log an administrative or moderation action for auditing/telemetry.
  static Future<void> logAction({
    required String actorId,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('admin_actions').add({
        'actorId': actorId,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort: swallow logging failures to avoid interrupting user flows.
    }
  }
}
