// lib/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/document/page_data.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coll = FirebaseFirestore.instance.collection('documents');

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: StreamBuilder<QuerySnapshot>(
        stream: coll.orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reports yet. Tap + to create one.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final title = doc['title'] as String? ?? 'Untitled';
              final author = doc['authorName'] as String? ?? 'Unknown';
              final deltaJson = doc['deltaContent'] as List<dynamic>? ?? [];
              final credentials = doc['authorCredentials'] as String? ?? '';

              return ListTile(
                title: Text(title),
                subtitle: Text(author),
                onTap: () {
                  // Open editor for existing report
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportEditorScreen(
                        documentId: doc.id,
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Preview PDF',
                  onPressed: () {
                    // Reconstruct a single-page report for preview
                    final controller = quill.QuillController(
                      document: quill.Document.fromJson(
                        List<Map<String, dynamic>>.from(deltaJson),
                      ),
                      selection: const TextSelection.collapsed(offset: 0),
                    );
                    final page = PageData()
                      ..controller = controller
                      ..name = author
                      ..credentials = credentials;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreviewScreen(pages: [page]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Report',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportEditorScreen()),
          );
        },
      ),
    );
  }
}
