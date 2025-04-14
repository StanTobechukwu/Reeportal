//lib/repositories/storage_repository.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository({FirebaseStorage? storage}) 
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile({
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      await ref.putData(fileBytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  Future<Uint8List?> downloadFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getData();
    } catch (e) {
      debugPrint('Download error: $e');
      rethrow;
    }
  }
}