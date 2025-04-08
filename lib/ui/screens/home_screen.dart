import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../repositories/auth_repository.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthRepository>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditorScreen(
              // Pass user ID for new document creation
              documentId: null,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userId != null 
            ? FirebaseFirestore.instance
                .collection('documents')
                .where('authorId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots()
            : Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading documents: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No reports found\nTap + to create a new one',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _DocumentListItem(
                title: data['title'] ?? 'Untitled Report',
                date: data['createdAt']?.toDate(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(
                      documentId: doc.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DocumentListItem extends StatelessWidget {
  final String title;
  final DateTime? date;
  final VoidCallback onTap;

  const _DocumentListItem({
    required this.title,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: const Icon(Icons.description),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        date != null 
            ? DateFormat('MMM dd, yyyy - hh:mm a').format(date!)
            : 'Unknown date',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}