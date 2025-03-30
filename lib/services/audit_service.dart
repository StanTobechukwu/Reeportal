import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AuditService(this._firestore, this._auth);

  Future<void> logAction({
    required String action, // 'create', 'edit', 'export'
    required String documentId,
    String? metadata,
  }) async {
    try {
      await _firestore.collection('audit_trail').add({
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'action': action,
        'documentId': documentId,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Audit log failed: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAuditLogs(String documentId) {
    return _firestore
        .collection('audit_trail')
        .where('documentId', isEqualTo: documentId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }
}