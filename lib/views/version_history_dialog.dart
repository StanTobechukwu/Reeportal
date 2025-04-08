import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/version_service.dart';
import '../../services/document_service.dart';

class VersionHistoryDialog extends StatelessWidget {
  final String documentId;

  const VersionHistoryDialog({required this.documentId, super.key});

  @override
  Widget build(BuildContext context) {
    final versionService = Provider.of<VersionService>(context, listen: false);
    final docService = Provider.of<DocumentService>(context, listen: false);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: FutureBuilder<List<VersionModel>>(
        future: versionService.getVersions(documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error loading versions: ${snapshot.error}'),
                ],
              ),
            );
          }

          final versions = snapshot.data!;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Version History'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return _VersionTile(
                      version: version,
                      onRestore: () async {
                        await versionService.restoreVersion(
                          documentId: documentId,
                          deltaContent: version.deltaContent,
                          context: context,
                        );
                        docService.loadDocument(documentId);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  final VersionModel version;
  final VoidCallback onRestore;

  const _VersionTile({required this.version, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text('#${version.versionNumber}'),
        title: Text(
          DateFormat('MMM dd, yyyy - hh:mm a').format(version.timestamp.toDate()),
        ),
        subtitle: Text('Modified by: ${version.userId}'),
        trailing: IconButton(
          icon: const Icon(Icons.restore),
          onPressed: onRestore,
          tooltip: 'Restore this version',
        ),
      ),
    );
  }
}