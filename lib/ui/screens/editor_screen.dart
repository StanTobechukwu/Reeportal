import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/document/document.dart';
import '../../services/document_service.dart';
import '../../repositories/storage_repository.dart';

extension AttributeUnsetExtension on quill.Attribute {
  quill.Attribute get unset => quill.Attribute(key, scope, null);
}

class EditorScreen extends StatefulWidget {
  final String? documentId;
  const EditorScreen({super.key, this.documentId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  bool _isInitialized = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    final service = context.read<DocumentService>();
    
    if (widget.documentId != null) {
      await service.loadDocument(widget.documentId!);
      _titleController.text = service.currentDocument.title;
    }

    _controller = quill.QuillController(
      document: service.currentDocument.deltaContent != null
          ? quill.Document.fromJson(service.currentDocument.deltaContent!)
          : quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final service = context.watch<DocumentService>();
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Document Title',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
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

  void _toggleStyle(quill.Attribute attribute) {
    final currentFormat = _controller.getSelectionStyle().attributes;
    _controller.formatSelection(
      currentFormat.containsKey(attribute.key) 
          ? attribute.unset 
          : attribute
    );
  }

  Future<void> _addImage(BuildContext context) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final storage = context.read<StorageRepository>();
     final fileBytes = await pickedFile.readAsBytes();
      final path = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
       final imageUrl = await storage.uploadFile(
    path: path,
    fileBytes: fileBytes,
    contentType: 'image/jpeg', // Adjust the content type if needed
  );
   // final imageUrl = await storage.uploadImage(File(pickedFile.path), 'images');
    
    final index = _controller.selection.baseOffset;
    _controller.document.insert(index, quill.BlockEmbed.image(imageUrl));
  }

  Future<void> _saveDocument(DocumentService service) async {
    final deltaContent = _controller.document.toDelta().toJson().cast<Map<String, dynamic>>();
    
    await service.saveDocument(
      title: _titleController.text,
      //elements: service.currentDocument.elements,
      deltaContent: deltaContent,
      id: widget.documentId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}