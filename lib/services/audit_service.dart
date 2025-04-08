import 'package:flutter/foundation.dart';
import '../models/document/document.dart';
import '../repositories/firestore_repository.dart';

class DocumentService with ChangeNotifier {
  final FirestoreRepository _repo;
  Document _currentDoc = Document.empty;
  bool _isLoading = false;

  DocumentService(this._repo);

  Document get currentDoc => _currentDoc;
  bool get isLoading => _isLoading;

  Future<void> loadDocument(String id) async {
    _setLoading(true);
    try {
      final doc = await _repo.getDocument(id);
      _currentDoc = doc ?? Document.empty;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveDocument({
    required String title,
    required List<Map<String, dynamic>> deltaContent,
  }) async {
    _setLoading(true);
    try {
      _currentDoc = _currentDoc.copyWith(
        title: title,
        deltaContent: deltaContent,
        updatedAt: DateTime.now(),
      );

      if (_currentDoc.id.isEmpty) {
        _currentDoc = await _repo.createDocument(_currentDoc);
      } else {
        await _repo.updateDocument(_currentDoc);
      }
      return true;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool state) {
    _isLoading = state;
    notifyListeners();
  }
}