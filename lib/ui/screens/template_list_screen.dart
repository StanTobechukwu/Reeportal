import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({Key? key}) : super(key: key);

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final int _limit = 10;
  bool _isLoadingMore = false;
  List<DocumentSnapshot> _templates = [];
  DocumentSnapshot? _lastDoc;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    Query query = _firestore
        .collection('templates')
        .orderBy('createdAt', descending: true)
        .limit(_limit);
    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _templates.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.last;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _loadTemplates();
    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Template"),
      ),
      body: ListView.builder(
        itemCount: _templates.length + 1,
        itemBuilder: (context, index) {
          if (index < _templates.length) {
            final data = _templates[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Untitled Template';
            return ListTile(
              title: Text(title),
              subtitle: Text("Created on: " +
                  (data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate().toString()
                      : "N/A")),
              onTap: () {
                Navigator.pop(context, data);
              },
            );
          } else {
            return _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _loadMore,
                    child: const Text("Load More"),
                  );
          }
        },
      ),
    );
  }
}
