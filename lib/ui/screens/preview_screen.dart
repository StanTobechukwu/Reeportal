import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PreviewScreen extends StatelessWidget {
  final String documentId;
  final List<dynamic> deltaContent;
  final List<String> imageColumn;
  final Uint8List? signature;
  
  const PreviewScreen({
    Key? key,
    required this.documentId,
    required this.deltaContent,
    required this.imageColumn,
    this.signature,
  }) : super(key: key);
  
  // Generate PDF using 'pdf' and 'printing' packages.
  Future<Uint8List> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final plainText = quill.Document.fromJson(deltaContent).toPlainText();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          List<pw.Widget> widgets = [];
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text("Report Preview", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
          );
          widgets.add(pw.Paragraph(text: plainText));
          if (imageColumn.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(
              pw.Text("Images:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            );
            for (var dataUri in imageColumn) {
              final imgData = base64Decode(dataUri.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), ''));
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Image(pw.MemoryImage(imgData), height: 100),
                ),
              );
            }
          }
          if (signature != null) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(
              pw.Text("Signature:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            );
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Image(pw.MemoryImage(signature!), height: 80),
              ),
            );
          }
          return widgets;
        },
      ),
    );
    return pdf.save();
  }
  
  void _onGeneratePdf(BuildContext context) async {
    final pdfBytes = await _generatePdf(context);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
  
  // Share functionality implemented in PreviewScreen.
  void _shareReport(BuildContext context) {
    final plainText = quill.Document.fromJson(deltaContent).toPlainText();
    if (plainText.trim().isNotEmpty) {
      Share.share(plainText, subject: 'Check out my report!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to share")),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final quillDoc = quill.Document.fromJson(deltaContent);
    final controller = quill.QuillController(
      document: quillDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.readOnly = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImages = imageColumn.isNotEmpty;
    final textColumnWidth = hasImages ? screenWidth * 0.65 : screenWidth;
    final imageColumnWidth = hasImages ? screenWidth * 0.33 : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Generate PDF",
            onPressed: () => _onGeneratePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Store Template",
            onPressed: () async {
              // Save current preview as a template.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Store Template not fully implemented")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share",
            onPressed: () => _shareReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Back to Edit",
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Two-column layout for text and images.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: textColumnWidth,
                  child: quill.QuillEditor.basic(
                    controller: controller,
                    //readOnly: true,
                  ),
                ),
                if (hasImages) const VerticalDivider(width: 16),
                if (hasImages)
                  Container(
                    width: imageColumnWidth,
                    child: Column(
                      children: imageColumn.map((dataUri) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Image.memory(
                            base64Decode(dataUri.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (signature != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Signature:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Image.memory(signature!, height: 80, fit: BoxFit.contain),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

