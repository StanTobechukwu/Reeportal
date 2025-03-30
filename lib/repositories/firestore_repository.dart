import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/document/document.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE
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

  // UPDATE
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

  // READ SINGLE
  Future<Document?> getDocument(String id) async {
    try {
      final snapshot = await _firestore.collection('documents').doc(id).get();
      if (!snapshot.exists) return null;
      return Document.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>, null);
    } on FirebaseException catch (e) {
      debugPrint('Get document error: $e');
      return null;
    }
  }

  // READ ALL (STREAM)
  Stream<List<Document>> getDocumentsByUser(String userId) {
    return _firestore
        .collection('documents')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Document.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
            .toList());
  }

  // DELETE
  Future<void> deleteDocument(String id) async {
    try {
      await _firestore.collection('documents').doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('Delete document error: $e');
      rethrow;
    }
  }

  // BATCH UPDATE
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
}