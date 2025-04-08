import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VersionModel>> getVersions(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .doc(documentId)
          .collection('audit_logs')
          .where('action', isEqualTo: 'document_saved')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .asMap()
          .map((index, doc) {
            final data = doc.data();
            return MapEntry(
              index,
              VersionModel(
                id: doc.id,
                versionNumber: snapshot.docs.length - index,
                timestamp: data['timestamp'] as Timestamp,
                userId: data['userId'] ?? 'system',
                deltaContent: (data['delta_content'] as List<dynamic>)
                    .cast<Map<String, dynamic>>(),
              ),
            );
          })
          .values
          .toList();
    } catch (e) {
      throw Exception('Failed to load versions: ${e.toString()}');
    }
  }

  Future<void> restoreVersion({
    required String documentId,
    required List<Map<String, dynamic>> deltaContent,
    required BuildContext context,
  }) async {
    try {
      await _firestore
          .collection('documents')
          .doc(documentId)
          .update({'delta_content': deltaContent});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
      );
    }
  }
}

class VersionModel {
  final String id;
  final int versionNumber;
  final Timestamp timestamp;
  final String userId;
  final List<Map<String, dynamic>> deltaContent;

  VersionModel({
    required this.id,
    required this.versionNumber,
    required this.timestamp,
    required this.userId,
    required this.deltaContent,
  });
}