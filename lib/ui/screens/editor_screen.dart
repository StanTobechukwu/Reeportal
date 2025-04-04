import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/document/document.dart';
import '../../services/document_service.dart';
import '../../repositories/storage_repository.dart';

/// Extension to add an 'unset' getter to quill.Attribute.
extension AttributeExtension on quill.Attribute {
  quill.Attribute get unset => quill.Attribute(key, scope, null);
}

class EditorScreen extends StatefulWidget {
  final String documentId;
  const EditorScreen({super.key, required this.documentId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late quill.QuillController _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    final service = context.read<DocumentService>();
    await service.loadDocument(widget.documentId);
    
    _controller = quill.QuillController(
      document: service.currentDoc.deltaContent != null
          ? quill.Document.fromJson(service.currentDoc.deltaContent!)
          : quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return _buildLoading();

    final service = context.watch<DocumentService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(service.currentDoc.title),
        actions: [_buildSaveButton(service)],
      ),
      body: Column(
        children: [
          Expanded(
            child: quill.QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
            ),
          ),
          _buildToolbar(context),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildSaveButton(DocumentService service) {
    return IconButton(
      icon: const Icon(Icons.save),
      onPressed: () => _saveDocument(service),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildStyleButton(Icons.format_bold, quill.Attribute.bold),
          _buildStyleButton(Icons.format_italic, quill.Attribute.italic),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () => _addImage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleButton(IconData icon, quill.Attribute attribute) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _toggleStyle(attribute),
    );
  }

  // Updated _toggleStyle method using the 'unset' extension.
  void _toggleStyle(quill.Attribute attribute) {
    final formats = _controller.getSelectionStyle().attributes;
    if (formats.containsKey(attribute.key)) {
      _controller.formatSelection(attribute.unset);
    } else {
      _controller.formatSelection(attribute);
    }
  }

  Future<void> _addImage(BuildContext context) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final storage = context.read<StorageRepository>();
    final imageFile = File(pickedFile.path);
    final imageUrl = await storage.uploadImage(imageFile, 'images');

    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - index;

    _controller.document.replace(
      index,
      length,
      quill.BlockEmbed.image(imageUrl),
    );
  }

  Future<void> _saveDocument(DocumentService service) async {
    final currentDoc = service.currentDoc;
    await service.saveDocument(
      title: currentDoc.title,
      elements: currentDoc.elements,
      pages: currentDoc.pages,
      deltaContent: _controller.document.toDelta().toJson(),
      id: currentDoc.id,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
