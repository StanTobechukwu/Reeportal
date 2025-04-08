// Ensure proper imports exist
import 'dart:io';
class ImageValidator {
  static bool isValid(File file) {
    return file.lengthSync() < 5 * 1024 * 1024; // 5MB limit
  }
}