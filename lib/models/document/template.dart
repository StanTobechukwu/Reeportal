//lib/models/document/template.dart
// File: lib/services/docx_template_service.dart

import 'dart:io';
import 'package:docx_template/docx_template.dart' as docx;
import 'package:path_provider/path_provider.dart';

class DocxTemplateService {
  /// Generates a DOCX report with advanced features.
  ///
  /// [title] is used for the report title.
  /// [contentBlocks] is a list where each block is a Map with keys:
  ///   - type: 'text' or 'image'
  ///   - For text blocks:
  ///       - 'sectionName': (optional) The name of this section.
  ///       - 'text': The content text.
  ///       - 'indent': The indentation level (0, 1, 2, ...).
  ///   - For image blocks: provide 'imagePath'.
  /// [signaturePath] is an optional path to a signature image.
  /// [templatePath] is the path to the DOCX template file.
  /// [outputFileName] is an optional output name for the generated file.
  static Future<File> generateAdvancedReport({
    required String title,
    required List<Map<String, dynamic>> contentBlocks,
    required String? signaturePath,
    required String templatePath,
    String? outputFileName,
  }) async {
    try {
      // 1. Load DOCX Template
      final templateBytes = await File(templatePath).readAsBytes();
      final docxGenerator = await docx.DocxTemplate.fromBytes(templateBytes);

      // 2. Prepare content
      final content = docx.Content()
        ..add(docx.TextContent('{{TITLE}}', title))
        // Merge all text-type blocks into one nested content placeholder.
        ..add(docx.TextContent('{{CONTENT}}', _buildNestedContent(contentBlocks)));

      // 3. Process any image blocks separately, if needed.
      // For example, if your template has a placeholder for a representative image.
      // This sample assumes that if a block is of type 'image' (and only one is expected),
      // it will fill the '{{IMAGE}}' placeholder.
      final imageBlock = contentBlocks.firstWhere(
          (block) => block['type'] == 'image',
          orElse: () => {}); // empty if none found
      if (imageBlock.isNotEmpty && imageBlock['imagePath'] != null) {
        content.add(docx.ImageContent(
          '{{IMAGE}}',
          File(imageBlock['imagePath']).readAsBytesSync(),
        ));
      }

      // 4. Add signature if provided.
      if (signaturePath != null) {
        content.add(docx.ImageContent(
          '{{SIGNATURE}}',
          File(signaturePath).readAsBytesSync(),
        ));
      }

      // 5. Add date.
      content.add(docx.TextContent('{{DATE}}', DateTime.now().toString()));

      // 6. Generate the report.
      final processed = await docxGenerator.generate(content);
      final outputFile = await _getOutputPath(
        outputFileName ??
            'generated_report_${DateTime.now().millisecondsSinceEpoch}.docx',
      );
      await outputFile.writeAsBytes(processed!);

      return outputFile;
    } catch (e) {
      throw Exception('Failed to generate document: $e');
    }
  }

  /// Builds a single nested content string from the contentBlocks.
  ///
  /// For each block with type 'text', it adds the section name (if provided)
  /// and the text with appropriate indentation.
  static String _buildNestedContent(List<Map<String, dynamic>> blocks) {
    final buffer = StringBuffer();

    for (var block in blocks) {
      if (block['type'] == 'text') {
        // Indentation level (0 means no indent).
        int indent = (block['indent'] ?? 0) as int;
        // Optional section name.
        String sectionName = block['sectionName'] ?? '';
        if (sectionName.isNotEmpty) {
          buffer.writeln('${'  ' * indent}$sectionName:');
        }
        // The text itself is indented one more level.
        buffer.writeln('${'  ' * (indent + 1)}${block['text']}');
        buffer.writeln(); // Empty line for separation.
      }
    }
    return buffer.toString();
  }

  // Gets the output file path in the application documents directory.
  static Future<File> _getOutputPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}
