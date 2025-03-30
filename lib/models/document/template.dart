import 'dart:io';
import 'package:docx_template/docx_template.dart' as docx;
import 'package:path_provider/path_provider.dart';

class DocxTemplateService {
  /// Generates a DOCX report with advanced features
  static Future<File> generateAdvancedReport({
    required String title,
    required List<Map<String, dynamic>> contentBlocks,
    required String? signaturePath,
    required String templatePath,
    String? outputFileName,
  }) async {
    try {
      // 1. Load template
      final templateBytes = await File(templatePath).readAsBytes();
      final docxGenerator = await docx.DocxTemplate.fromBytes(templateBytes);
      
      // 2. Prepare content
      final content = docx.Content()
        ..add(docx.TextContent('{{TITLE}}', title));
      
      // 3. Add content blocks
      for (final block in contentBlocks) {
        switch (block['type']) {
          case 'text':
            content.add(docx.TextContent(
              '{{CONTENT}}', 
              _formatText(
                block['text'], 
                indent: block['indent'] ?? 0,
                isBold: block['isBold'] ?? false,
                isItalic: block['isItalic'] ?? false,
              ),
            ));
            break;
          case 'image':
            content.add(docx.ImageContent(
              '{{IMAGE}}',
              File(block['imagePath']).readAsBytesSync(),
            ));
            break;
        }
      }
      
      // 4. Add signature if exists
      if (signaturePath != null) {
        content.add(docx.ImageContent(
          '{{SIGNATURE}}',
          File(signaturePath).readAsBytesSync(),
        ));
      }
      
      // 5. Add date
      content.add(docx.TextContent('{{DATE}}', DateTime.now().toString()));
      
      // 6. Generate and save
      final processed = await docxGenerator.generate(content);
      final outputPath = await _getOutputPath(
        outputFileName ?? 'generated_report_${DateTime.now().millisecondsSinceEpoch}.docx',
      );
      await outputPath.writeAsBytes(processed!);
      
      return outputPath;
    } catch (e) {
      throw Exception('Failed to generate document: $e');
    }
  }

  /// Helper to format text with indentation and styling
  static String _formatText(String text, {
    required int indent,
    bool isBold = false,
    bool isItalic = false,
  }) {
    final buffer = StringBuffer();
    // Add indentation (2 spaces per level)
    buffer.write('  ' * indent);
    
    // Add formatting
    if (isBold) buffer.write('**');
    if (isItalic) buffer.write('*');
    buffer.write(text);
    if (isItalic) buffer.write('*');
    if (isBold) buffer.write('**');
    
    return buffer.toString();
  }

  static Future<File> _getOutputPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}