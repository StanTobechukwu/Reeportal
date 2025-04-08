import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getAuditLogs(String documentId) {
    return _firestore
        .collection('documents')
        .doc(documentId)
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  Future<void> logAction({
    required String documentId,
    required String action,
    required String userId,
    String details = '',
  }) async {
    await _firestore
        .collection('documents')
        .doc(documentId)
        .collection('audit_logs')
        .add({
      'action': action,
      'userId': userId,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}