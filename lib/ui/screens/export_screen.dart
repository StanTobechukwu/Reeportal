import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../services/document_service.dart';

class DocumentEditorScreen extends StatefulWidget {
  final String? documentId;
  const DocumentEditorScreen({this.documentId, Key? key}) : super(key: key);

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late quill.QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeDocument();
  }

  Future<void> _initializeDocument() async {
    final docService = Provider.of<DocumentService>(
      context,
      listen: false,
    );
    
    if (widget.documentId != null) {
      await docService.loadDocument(widget.documentId!);
      _titleController.text = docService.currentDocument.title;
      final initialContent = docService.currentDocument.deltaContent != null
          ? quill.Document.fromJson(docService.currentDocument.deltaContent!)
          : quill.Document();
      _controller = quill.QuillController(
        document: initialContent,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = quill.QuillController.basic();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final docService = Provider.of<DocumentService>(
        context,
        listen: false,
      );
      await docService.saveDocument(
        title: _titleController.text,
        //elements: docService.currentDocument.elements, // Add elements parameter
        deltaContent: _controller.document.toDelta().toJson(),
        id: widget.documentId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Document Title',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: _saveDocument,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          quill.QuillToolbar.simple(
            configurations: const quill.QuillSimpleToolbarConfigurations(),
            controller: _controller,
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: quill.QuillEditor.basic(
                controller: _controller,
                configurations: const quill.QuillEditorConfigurations(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }
}