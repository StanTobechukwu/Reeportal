import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:uuid/uuid.dart';
import '../models/document/document.dart';
import '../repositories/firestore_repository.dart';

class DocumentService with ChangeNotifier {
  final FirestoreRepository _repository;
  final Uuid _uuid = const Uuid();

  Document _currentDocument = Document.empty;
  bool _isLoading = false;
  String? _error;

  DocumentService(this._repository);

  Document get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocument(String id) async {
    _setLoading(true);
    try {
      final doc = await _repository.getDocument(id);
      _currentDocument = doc ?? Document.empty;
      _error = null;
    } catch (e) {
      _handleError('Failed to load document: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveDocument({
    required String title,
    //required List<DocumentElement> elements,
    required List<Map<String, dynamic>> deltaContent,
    String? id,
  }) async {
    _setLoading(true);
    try {
      _currentDocument = _currentDocument.copyWith(
        title: title,
        //elements: elements,
        deltaContent: deltaContent,
        updatedAt: DateTime.now(),
      );

      if (_currentDocument.id.isEmpty) {
        _currentDocument = await _repository.createDocument(_currentDocument);
      } else {
        await _repository.updateDocument(_currentDocument);
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

  Future<void> addImageElement(XFile image, ui.Offset position) async {
    _setLoading(true);
    try {
      final bytes = await image.readAsBytes();
      final imageElement = DocumentElement.image(
        'data:image/${_getFileExtension(image.name)};base64,${base64Encode(bytes)}',
        position,
      ).copyWith(
        properties: {
          'id': _uuid.v4(),
          ...DocumentElement.image(
            '', 
            position,
          ).properties,
        },
      );

      _currentDocument = _currentDocument.copyWith(
        elements: [..._currentDocument.elements, imageElement],
      );
      await _repository.updateDocument(_currentDocument);
      _error = null;
    } catch (e) {
      _handleError('Failed to add image: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateElementPosition(String elementId, ui.Offset newPosition) async {
    _setLoading(true);
    try {
      final updatedElements = _currentDocument.elements.map((element) {
        if (element.properties['id'] == elementId) {
          return element.copyWith(
            properties: {
              ...element.properties,
              'posX': newPosition.dx,
              'posY': newPosition.dy,
            },
          );
        }
        return element;
      }).toList();

      _currentDocument = _currentDocument.copyWith(elements: updatedElements);
      await _repository.updateDocument(_currentDocument);
      _error = null;
    } catch (e) {
      _handleError('Failed to update position: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void clearDocument() {
    _currentDocument = Document.empty;
    _error = null;
    notifyListeners();
  }

  String _getFileExtension(String filename) {
    final extStart = filename.lastIndexOf('.');
    return extStart == -1 ? '' : filename.substring(extStart + 1);
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