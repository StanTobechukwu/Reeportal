// services/pdf_export_handler.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '/models/document/document.dart';

class PDFExportHandler {
  Future<Uint8List> generatePDF(Document document) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4;

    // Build all elements first
    final elements = await Future.wait(
      document.elements.map((e) => _buildPdfElement(e)),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) => pw.Stack(
          children: elements,
        ),
      ),
    );

    return pdf.save();
  }

  Future<pw.Widget> _buildPdfElement(DocumentElement element) async {
    switch (element.type) {
      case 'image':
        final imageData = await _fetchImageData(element.properties['url']);
        return pw.Positioned(
          left: element.properties['posX']?.toDouble() ?? 0,
          top: element.properties['posY']?.toDouble() ?? 0,
          child: pw.Image(
            pw.MemoryImage(imageData),
            width: element.properties['width']?.toDouble() ?? 150,
            height: element.properties['height']?.toDouble() ?? 150,
          ),
        );
      case 'text':
        return pw.Positioned(
          left: element.properties['posX']?.toDouble() ?? 0,
          top: element.properties['posY']?.toDouble() ?? 0,
          child: pw.Text(
            element.properties['content'] ?? '',
            style: pw.TextStyle(
              fontSize: element.properties['fontSize']?.toDouble() ?? 12,
            ),
          ),
        );
      default:
        return pw.Container();
    }
  }

  Future<Uint8List> _fetchImageData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to load image: ${response.statusCode}');
  }
}