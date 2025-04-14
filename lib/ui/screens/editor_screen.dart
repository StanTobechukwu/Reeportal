import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
// Use Delta from dart_quill_delta to avoid version conflicts.
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:image_picker/image_picker.dart';
import 'image_blank_page_screen.dart';
import 'preview_screen.dart';
import 'signature_screen.dart';
import 'template_list_screen.dart';
// Adjust the import path to match your project structure.
import '/repositories/structured_template_editor.dart';

enum FormType { plain, previousTemplate, structured }

class EditorScreen extends StatefulWidget {
  final String? documentId;
  const EditorScreen({Key? key, this.documentId}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _title = '';

  // For plain form, use a Quill editor.
  final quill.QuillController _controller = quill.QuillController.basic();

  // For structured form, use our custom structured editor.
  List<SectionData> _sections = [];

  // Image column: store images as base64 data URIs.
  List<String> _imageColumn = [];
  final ImagePicker _picker = ImagePicker();

  // Signature image.
  Uint8List? _signatureImage;

  FormType? _selectedFormType;

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('documents')
          .doc(widget.documentId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _title = data['title'] ?? '';
          _controller.document =
              quill.Document.fromJson(data['deltaContent'] ?? [{'insert': '\n'}]);
          if (data['imageColumn'] != null && data['imageColumn'] is List) {
            _imageColumn = List<String>.from(data['imageColumn']);
          }
          // Optionally load structured sections & signature if saved.
        });
      }
    } catch (e) {
      debugPrint("Error loading document: $e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Show dialog to choose form type.
  void _chooseFormType() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Form Type"),
          content: const Text("Select how you want to start the report:"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFormType = FormType.plain;
                  _controller.document = quill.Document();
                  _sections.clear();
                  _imageColumn.clear();
                });
              },
              child: const Text("Plain Form"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedFormType = FormType.structured;
                  if (_sections.isEmpty) {
                    _sections.add(SectionData());
                  }
                });
              },
              child: const Text("Structured Form"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _selectedFormType = FormType.previousTemplate;
                });
                final templateData = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TemplateListScreen()),
                );
                if (templateData != null && templateData is Map<String, dynamic>) {
                  setState(() {
                    _title = templateData['title'] ?? '';
                    _controller.document = quill.Document.fromJson(
                        templateData['deltaContent'] ?? [{'insert': '\n'}]);
                    if (templateData['imageColumn'] != null &&
                        templateData['imageColumn'] is List) {
                      _imageColumn = List<String>.from(templateData['imageColumn']);
                    }
                    // Optionally, load structured sections if available.
                  });
                }
              },
              child: const Text("Previous Template"),
            ),
          ],
        );
      },
    );
  }

  // Add an image to the image column.
  Future<void> _addImageToColumn() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final extension = pickedFile.path.split('.').last;
        final dataUri = 'data:image/$extension;base64,$base64Str';
        setState(() {
          if (_imageColumn.length < 4) {
            _imageColumn.add(dataUri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Maximum 4 images allowed")),
            );
          }
        });
      } catch (e) {
        debugPrint("Error processing image: $e");
      }
    }
  }

  void _clearImageColumn() {
    setState(() {
      _imageColumn.clear();
    });
  }

  // Open the blank page images screen.
  void _openBlankPageImages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageBlankPageScreen()),
    );
  }

  // Navigate to SignatureScreen.
  Future<void> _addSignature() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignatureScreen()),
    );
    if (result is Uint8List) {
      setState(() {
        _signatureImage = result;
      });
    }
  }

  // Convert structured sections to plain text.
  String _convertSectionsToText(List<SectionData> sections, [int level = 0]) {
    String result = "";
    for (var section in sections) {
      result += "${'  ' * level}${section.name}\n";
      result += "${'  ' * (level + 1)}${section.content}\n\n";
      result += _convertSectionsToText(section.subSections, level + 1);
    }
    return result;
  }

  // Save the report to Firestore.
  Future<void> _saveReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");
      final userId = currentUser.uid;
      List<dynamic> deltaJson;
      if (_selectedFormType == FormType.structured) {
        final text = _convertSectionsToText(_sections, 0);
        // Use Delta() from dart_quill_delta.
        deltaJson = quill.Document.fromDelta(Delta()..insert(text + "\n"))
            .toDelta()
            .toJson();
      } else {
        deltaJson = _controller.document.toDelta().toJson();
      }
      final documentData = {
        'title': _title,
        'deltaContent': deltaJson,
        'imageColumn': _imageColumn,
        'signature': _signatureImage != null ? base64Encode(_signatureImage!) : null,
        'authorId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final coll = FirebaseFirestore.instance.collection('documents');
      if (widget.documentId != null)
        await coll.doc(widget.documentId).update(documentData);
      else
        await coll.add(documentData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report Saved")),
      );
    }
  }

  // Navigate to the PreviewScreen.
  void _previewReport() {
    List<dynamic> deltaJson;
    if (_selectedFormType == FormType.structured) {
      final text = _convertSectionsToText(_sections, 0);
      deltaJson = quill.Document.fromDelta(Delta()..insert(text + "\n"))
          .toDelta()
          .toJson();
    } else {
      deltaJson = _controller.document.toDelta().toJson();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          documentId: '',
          deltaContent: deltaJson,
          imageColumn: _imageColumn,
          signature: _signatureImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImages = _imageColumn.isNotEmpty;
    final textColumnWidth = hasImages ? screenWidth * 0.65 : screenWidth;
    final imageColumnWidth = hasImages ? screenWidth * 0.33 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: "Choose Form Type",
            onPressed: _chooseFormType,
          ),
          // Share button removed from EditorScreen.
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save as Template",
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) return;
              final userId = currentUser.uid;
              List<dynamic> deltaJson;
              if (_selectedFormType == FormType.structured) {
                final text = _convertSectionsToText(_sections, 0);
                deltaJson = quill.Document.fromDelta(Delta()..insert(text + "\n"))
                    .toDelta()
                    .toJson();
              } else {
                deltaJson = _controller.document.toDelta().toJson();
              }
              final templateData = {
                'title': _title,
                'deltaContent': deltaJson,
                'imageColumn': _imageColumn,
                'authorId': userId,
                'createdAt': FieldValue.serverTimestamp(),
              };
              await FirebaseFirestore.instance.collection('templates').add(templateData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Template Saved")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: "Report Title"),
                onChanged: (val) {
                  setState(() {
                    _title = val;
                  });
                },
                validator: (val) => (val == null || val.isEmpty) ? "Enter a title" : null,
              ),
              const SizedBox(height: 16),
              _selectedFormType == FormType.structured
                  ? StructuredTemplateEditor(
                      sections: _sections.isEmpty ? (_sections..add(SectionData())) : _sections,
                    )
                  : Container(
                      width: textColumnWidth,
                      height: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _controller,
                        // Do not pass readOnly here.
                        //readOnly: false,
                      ),
                    ),
              const SizedBox(height: 16),
              if (_selectedFormType != FormType.structured)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImages) const VerticalDivider(width: 16),
                    if (hasImages)
                      Container(
                        width: imageColumnWidth,
                        child: Column(
                          children: [
                            for (var dataUri in _imageColumn)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Image.memory(
                                  base64Decode(dataUri.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _addImageToColumn,
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text("Add"),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _clearImageColumn,
                                  icon: const Icon(Icons.clear),
                                  label: const Text("Clear"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Add Image"),
                            content: const Text("Choose where to add the image:"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _addImageToColumn();
                                },
                                child: const Text("To Text Page"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openBlankPageImages();
                                },
                                child: const Text("Blank Page Images"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Add Image"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSignature,
                    icon: const Icon(Icons.edit),
                    label: const Text("Add Signature"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _previewReport,
                icon: const Icon(Icons.visibility),
                label: const Text("Preview"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveReport,
                child: Text(widget.documentId != null ? "Update Report" : "Save Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

