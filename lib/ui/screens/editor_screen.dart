import 'package:flutter/material.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart' as qDelta;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../services/document_service.dart';
import '../../services/report_maker.dart';
import '/services/audit_service.dart';
import 'audit_log_viewer_screen.dart'; // Add audit log screen import

class DocumentEditorScreen extends StatefulWidget {
  final String? documentId;
  const DocumentEditorScreen({this.documentId, Key? key}) : super(key: key);

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late quill.QuillController _controller;
  late ScrollController _scrollController;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeDocument();
  }

  Future<void> _initializeDocument() async {
    final docService = context.read<DocumentService>();
    final auditService = context.read<AuditService>();

    try {
      if (widget.documentId != null) {
        await docService.loadDocument(widget.documentId!);
        _titleController.text = docService.currentDoc.title;
        
        await auditService.logAction(
          documentId: widget.documentId!,
          action: 'document_opened',
          details: 'Document opened by user',
          deltaContent: {'ops': docService.currentDoc.deltaContent ?? []}, // Wrapped in map
        );

        final initialContent = docService.currentDoc.deltaContent != null
            ? quill.Document.fromJson(docService.currentDoc.deltaContent!)
            : quill.Document();
        _controller = quill.QuillController(
          document: initialContent,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _controller = quill.QuillController.basic();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDocument() async {
    final docService = context.read<DocumentService>();
    final auditService = context.read<AuditService>();

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final deltaJson = _controller.document.toDelta().toJson();
      await docService.saveDocument(
        title: _titleController.text,
        deltaContent: deltaJson,
        id: widget.documentId,
      );

      await auditService.logAction(
        documentId: widget.documentId ?? 'new_document',
        action: 'document_saved',
        details: 'Document version saved',
        deltaContent: {'ops': deltaJson}, // Wrapped in map
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

  Future<void> _exportDocument() async {
    final auditService = context.read<AuditService>();

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title before exporting')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final exportedFile = await ReportMaker.generate(
        title: _titleController.text,
        contentBlocks: _convertDeltaToBlocks(_controller.document.toDelta()),
        templatePath: 'assets/templates/default.docx',
      );

      await auditService.logAction(
        documentId: widget.documentId ?? 'new_document',
        action: 'document_exported',
        details: 'Exported to: ${exportedFile.path}',
        deltaContent: {'ops': _controller.document.toDelta().toJson()}, // Wrapped in map
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${exportedFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<Map<String, dynamic>> _convertDeltaToBlocks(qDelta.Delta delta) {
    final doc = quill.Document.fromDelta(delta);
    return [
      {
        'type': 'heading',
        'text': _titleController.text,
        'level': 1,
      },
      {
        'type': 'paragraph',
        'text': doc.toPlainText(),
      },
    ];
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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              if (widget.documentId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuditLogScreen(documentId: widget.documentId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save document first to view history')),
                );
              }
            },
            tooltip: 'View Activity History',
          ),
          IconButton(
            icon: _isExporting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.file_download, color: Colors.white),
            onPressed: _isExporting ? null : _exportDocument,
          ),
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
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: quill.QuillEditor.basic(
                controller: _controller,
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
    _scrollController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}