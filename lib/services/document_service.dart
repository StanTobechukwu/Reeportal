import 'package:quill_delta/quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document/document.dart';
import '../repositories/firestore_repository.dart';

class DocumentService with ChangeNotifier {
  final FirestoreRepository _repo;
  Document _currentDoc = Document.empty;
  bool _isLoading = false;
  String? _error;

  DocumentService(this._repo);

  // Getters
  Document get currentDoc => _currentDoc;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocument(String id) async {
    _setLoading(true);
    try {
      _currentDoc = await _repo.getDocument(id) ?? Document.empty;
      _error = null;
    } catch (e) {
      _handleError('Failed to load document: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveDocument({
    required String title,
    required List<dynamic> deltaContent,
    String? id,
  }) async {
    _setLoading(true);
    try {
      // Convert the stored JSON delta into a Quill document.
      final document = quill.Document.fromJson(deltaContent);
      final plainText = document.toPlainText();

      _currentDoc = _currentDoc.copyWith(
        id: id ?? _currentDoc.id,
        title: title,
        content: plainText,
        deltaContent: deltaContent,
        updatedAt: DateTime.now(),
      );

      if (_currentDoc.id.isEmpty) {
        _currentDoc = await _repo.createDocument(_currentDoc);
      } else {
        await _repo.updateDocument(_currentDoc);
      }

      _error = null;
      return true;
    } catch (e) {
      _handleError('Failed to save document: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  static String deltaToPlainText(List<dynamic> delta) {
    final document = quill.Document.fromJson(delta);
    return document.toPlainText();
  }

  void clearDocument() {
    _currentDoc = Document.empty;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool state) {
    _isLoading = state;
    notifyListeners();
  }

  void _handleError(String message) {
    _error = message;
    notifyListeners();
  }
}
