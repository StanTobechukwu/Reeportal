import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/document/document.dart';
import 'dart:ui' as ui;

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Audit log methods
  Future<void> addAuditLog({
    required String documentId,
    required String action,
    required String details,
    required Map<String, dynamic> deltaContent,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'documentId': documentId,
        'action': action,
        'details': details,
        'deltaContent': deltaContent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('Add audit log error: $e');
      rethrow;
    }
  }

  

  Stream<List<Map<String, dynamic>>> getAuditLogs(String documentId) {
    return _firestore
        .collection('audit_logs')
        .where('documentId', isEqualTo: documentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  // Document methods
  Future<Document> createDocument(Document doc) async {
    try {
      final docRef = await _firestore.collection('documents').add({
        ...doc.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      debugPrint('Create document error: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(Document doc) async {
    try {
      await _firestore.collection('documents').doc(doc.id).update({
        ...doc.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('Update document error: $e');
      rethrow;
    }
  }

  Future<Document?> getDocument(String id) async {
    try {
      final snapshot = await _firestore.collection('documents').doc(id).get();
      return snapshot.exists ? Document.fromFirestore(snapshot, null) : null;
    } on FirebaseException catch (e) {
      debugPrint('Get document error: $e');
      return null;
    }
  }

  Stream<List<Document>> getDocumentsByUser(String userId) {
    return _firestore
        .collection('documents')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Document.fromFirestore(doc, null))
            .toList());
  }

  // New method for documents with images
  Stream<List<Document>> getDocumentsWithImages(String userId) {
    return _firestore
        .collection('documents')
        .where('authorId', isEqualTo: userId)
        .where('elementTypes', arrayContains: 'image')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Document.fromFirestore(doc, null))
            .toList());
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _firestore.collection('documents').doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('Delete document error: $e');
      rethrow;
    }
  }

  Future<void> batchUpdateDocuments(List<Document> documents) async {
    final batch = _firestore.batch();
    for (final doc in documents) {
      final docRef = _firestore.collection('documents').doc(doc.id);
      batch.update(docRef, {
        ...doc.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // New image-specific methods
  Future<void> updateImagePosition(String docId, String imageUrl, ui.Offset position) async {
    try {
      await _firestore.collection('documents').doc(docId).update({
        'elements': FieldValue.arrayUnion([
          {
            'type': 'image',
            'content': imageUrl,
            'posX': position.dx,
            'posY': position.dy,
            'width': 150.0,
            'height': 150.0,
            'wrap': {'wrapRight': true}
          }
        ])
      });
    } on FirebaseException catch (e) {
      debugPrint('Update image position error: $e');
      rethrow;
    }
  }

  Future<void> removeImageElement(String docId, String imageUrl) async {
    try {
      final doc = await getDocument(docId);
      if (doc != null) {
        final updatedElements = doc.elements
            .where((element) => element.content != imageUrl)
            .toList();
        
        await _firestore.collection('documents').doc(docId).update({
          'elements': updatedElements.map((e) => e.toJson()).toList(),
          'elementTypes': updatedElements.map((e) => e.type).toList(),
        });
      }
    } on FirebaseException catch (e) {
      debugPrint('Remove image error: $e');
      rethrow;
    }
  }
}