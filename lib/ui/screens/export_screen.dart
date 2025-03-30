// screens/export_config_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/document_service.dart';

class ExportConfigScreen extends StatefulWidget {
  final String documentId;
  const ExportConfigScreen({required this.documentId, super.key});

  @override
  State<ExportConfigScreen> createState() => _ExportConfigScreenState();
}

class _ExportConfigScreenState extends State<ExportConfigScreen> {
  String? _selectedTemplate;
  String? _signaturePath;

  Future<void> _selectTemplate() async {
    final result = await FilePicker.platform.pickFile(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result != null) {
      setState(() => _selectedTemplate = result.path);
    }
  }

  Future<void> _uploadSignature() async {
    final result = await FilePicker.platform.pickFile(
      type: FileType.image,
    );
    if (result != null) {
      setState(() => _signaturePath = result.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _TemplateSelector(
              selectedPath: _selectedTemplate,
              onSelect: _selectTemplate,
            ),
            const SizedBox(height: 20),
            _SignatureUploader(
              signaturePath: _signaturePath,
              onUpload: _uploadSignature,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.read<DocumentService>().setExportConfig(
                  widget.documentId,
                  templatePath: _selectedTemplate,
                  signaturePath: _signaturePath,
                );
                Navigator.pop(context);
              },
              child: const Text('Save Configuration'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  final String? selectedPath;
  final VoidCallback onSelect;
  
  const _TemplateSelector({required this.selectedPath, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description),
        title: const Text('Select DOCX Template'),
        subtitle: Text(selectedPath ?? 'No template selected'),
        trailing: IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: onSelect,
        ),
      ),
    );
  }
}

class _SignatureUploader extends StatelessWidget {
  final String? signaturePath;
  final VoidCallback onUpload;
  
  const _SignatureUploader({required this.signaturePath, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.draw),
        title: const Text('Upload Signature'),
        subtitle: Text(signaturePath ?? 'No signature uploaded'),
        trailing: IconButton(
          icon: const Icon(Icons.upload),
          onPressed: onUpload,
        ),
      ),
    );
  }
}