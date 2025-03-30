import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter_quill/flutter_quill.dart';

@immutable
class Document {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorId;
  final List<String> tags;
  final int version;
  final List<dynamic>? deltaContent;

  const Document({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.authorId,
    this.tags = const [],
    this.version = 1,
     this.deltaContent,
  });

  /// Empty/default document
  static final empty = Document(
    id: '',
    title: '',
    content: '',
    createdAt: DateTime(1970),
    authorId: '',
    version: 0,
  );
   

  /// Firestore conversion
  factory Document.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data()!;
    return Document(
      id: snapshot.id,
      title: data['title'] ?? 'Untitled',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      authorId: data['authorId'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      version: (data['version'] as int?) ?? 1,
    );
  }

  /// Firestore serialization
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'content': content,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    'authorId': authorId,
    'tags': tags,
    'version': version,
  };

  /// Immutable updates
  Document copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    List<String>? tags,
    int? version,
    List<dynamic>? deltaContent,
  }) => Document(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    authorId: authorId ?? this.authorId,
    tags: tags ?? this.tags,
    version: version ?? this.version,
    deltaContent: deltaContent ?? this.deltaContent,
  );

  /// Handles both update and timestamp
  Document withUpdate({
    String? title,
    String? content,
    List<String>? tags,
  }) => copyWith(
    title: title,
    content: content,
    tags: tags,
    updatedAt: DateTime.now(),
  );

  /// Manual equality comparison (replaces Equatable)
  @override
  bool operator ==(Object other) => identical(this, other) || other is Document &&
    runtimeType == other.runtimeType &&
    id == other.id &&
    title == other.title &&
    content == other.content &&
    createdAt == other.createdAt &&
    updatedAt == other.updatedAt &&
    authorId == other.authorId &&
    listEquals(tags, other.tags) &&
    version == other.version;

  @override
  int get hashCode => Object.hashAll([
    id, title, content, createdAt, 
    updatedAt, authorId, tags, version
  ]);

  /// Validation
  bool get isValid => id.isNotEmpty && title.isNotEmpty;

  /// Helper
  String get wordCount => 
    content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length.toString();
}