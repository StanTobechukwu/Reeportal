import 'dart:io';
import 'package:docx_template/docx_template.dart' as docx;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ReportMaker {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Main document generation method
  static Future<File> generate({
    required String title,
    required List<Map<String, dynamic>> contentBlocks,
    required String templatePath,
    String? signaturePath,
    String? outputFileName,
    bool includeDate = true,
  }) async {
    try {
      // Verify template exists
      final templateFile = File(templatePath);
      if (!await templateFile.exists()) {
        throw Exception('Template file not found at $templatePath');
      }

      // Load template
      final templateBytes = await templateFile.readAsBytes();
      final docxGenerator = await docx.DocxTemplate.fromBytes(templateBytes);
      
      // Prepare content
      final content = docx.Content()
        ..add(docx.TextContent('title', title));

      // Add content blocks
      for (final block in contentBlocks) {
        await _addContentBlock(content, block);
      }

      // Add optional signature
      if (signaturePath != null) {
        await _addSignature(content, signaturePath);
      }

      // Add date if requested
      if (includeDate) {
        content.add(docx.TextContent(
          'date',
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
        ));
      }

      // Generate document
      final generated = await docxGenerator.generate(content);
      if (generated == null) {
        throw Exception('Document generation failed');
      }

      // Save output
      final outputFile = await _getOutputFile(
        outputFileName ?? '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.docx'
      );
      await outputFile.writeAsBytes(generated);
      
      return outputFile;
    } catch (e) {
      throw Exception('Report generation failed: $e');
    }
  }

  /// Adds content blocks based on type
  static Future<void> _addContentBlock(
    docx.Content content,
    Map<String, dynamic> block,
  ) async {
    try {
      switch (block['type']) {
        case 'heading':
          _addHeading(content, block);
          break;
        case 'paragraph':
          _addParagraph(content, block);
          break;
        case 'image':
          await _addImage(content, block);
          break;
        case 'table':
          _addTable(content, block);
          break;
        case 'bullets':
          _addBullets(content, block);
          break;
        default:
          throw ArgumentError('Unsupported block type: ${block['type']}');
      }
    } catch (e) {
      print('Error processing ${block['type']} block: $e');
      rethrow;
    }
  }

  /// Table implementation
  static void _addTable(docx.Content content, Map<String, dynamic> block) {
    final rows = block['rows'] as List<List<String>>?;
    if (rows == null || rows.isEmpty) return;

    final List<docx.RowContent> tableRows = [];

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final rowMap = <String, docx.TextContent>{};

      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        rowMap['cell$colIndex'] = docx.TextContent(
          'cell$colIndex',
          row[colIndex],
        );
      }

      tableRows.add(docx.RowContent(rowMap));
    }

    content.add(docx.TableContent('table', tableRows));
  }

  static void _addHeading(docx.Content content, Map<String, dynamic> block) {
    content.add(docx.TextContent(
      'heading_${block['level']}',
      '${_getHeadingPrefix(block['level'])} ${block['text']}'
    ));
  }

  static void _addParagraph(docx.Content content, Map<String, dynamic> block) {
    content.add(docx.TextContent(
      'paragraph',
      _formatText(
        block['text'],
        indent: block['indent'] ?? 0,
        isBold: block['isBold'] ?? false,
        isItalic: block['isItalic'] ?? false,
      ),
    ));
  }

  static Future<void> _addImage(
    docx.Content content,
    Map<String, dynamic> block,
  ) async {
    if (block['path'] != null) {
      final imageFile = File(block['path']);
      if (await imageFile.exists()) {
        content.add(docx.ImageContent(
          'image_${block['key']}',
          await imageFile.readAsBytes(),
        ));
      }
    }
  }

  static void _addBullets(docx.Content content, Map<String, dynamic> block) {
    final items = block['items'] as List<String>;
    content.add(docx.TextContent(
      'bullets',
      items.map((item) => '• $item').join('\n'),
    ));
  }

  static Future<void> _addSignature(
    docx.Content content,
    String signaturePath,
  ) async {
    final signatureFile = File(signaturePath);
    if (await signatureFile.exists()) {
      content.add(docx.ImageContent(
        'signature',
        await signatureFile.readAsBytes(),
      ));
    }
  }

  /// Helper methods
  static String _getHeadingPrefix(int level) => 
    List.generate(level.clamp(1, 3), (_) => '#').join();

  static String _formatText(
    String text, {
    int indent = 0,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return '${'  ' * indent}${isBold ? '**' : ''}${isItalic ? '*' : ''}$text${isItalic ? '*' : ''}${isBold ? '**' : ''}';
  }

  static Future<File> _getOutputFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${_sanitizeFileName(fileName)}');
  }

  static String _sanitizeFileName(String input) => 
    input.replaceAll(RegExp(r'[^\w-.]'), '_');

  /// Image picker utility
  static Future<File?> pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      print('Image picker error: $e');
      return null;
    }
  }
}