import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../models/document/document.dart';
import '../../services/document_service.dart';

class PreviewScreen extends StatelessWidget {
  final String documentId;

  const PreviewScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DocumentService>(context, listen: false);
    final focusNode = FocusNode();
    final scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(title: const Text('Document Preview')),
      body: FutureBuilder<void>(
        future: service.loadDocument(documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return _buildPreview(
            service.currentDocument,
            focusNode,
            scrollController,
          );
        },
      ),
    );
  }

  Widget _buildPreview(
    Document document,
    FocusNode focusNode,
    ScrollController scrollController,
  ) {
    final deltaContent = document.deltaContent ?? [];
    final quillDoc = quill.Document.fromJson(deltaContent);

    // Create the controller for the editor.
    final controller = quill.QuillController(
      document: quillDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Set the controller to read-only.
    controller.readOnly = true;
    // Or: controller.getQuill().enable(false);

    return Stack(
      children: [
        SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: quill.QuillEditor(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              // Remove readOnly from here:
              configurations: const quill.QuillEditorConfigurations(
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        ..._buildPreviewImages(document),
      ],
    );
  }

  List<Widget> _buildPreviewImages(Document document) {
    return document.elements
        .where((e) => e.type == 'image')
        .map((element) => Positioned(
              left: element.position.dx,
              top: element.position.dy,
              child: Image.network(
                element.url,
                width: element.dimensions.width,
                height: element.dimensions.height,
                fit: BoxFit.contain,
              ),
            ))
        .toList();
  }
}
