import 'package:flutter/foundation.dart';
import '../shared/enums.dart';
import '../shared/metadata.dart';

class DocumentSection {
  final String id;
  final SectionType type;
  final String? content;
  final String? imagePath; // Store path instead of File for serialization
  final int indentLevel;
  final HeadingStyle headingStyle;
  final DocumentMetadata metadata;
  final List<String> tags;

  DocumentSection({
    required this.type,
    this.content,
    this.imagePath,
    this.indentLevel = 0,
    this.headingStyle = HeadingStyle.h2,
    this.tags = const [],
    String? id,
    DocumentMetadata? metadata,
  }) : 
    id = id ?? '',
    metadata = metadata ?? DocumentMetadata();

  // === Core Methods ===
  DocumentSection copyWith({
    SectionType? type,
    String? content,
    String? imagePath,
    int? indentLevel,
    HeadingStyle? headingStyle,
    List<String>? tags,
  }) {
    return DocumentSection(
      type: type ?? this.type,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      indentLevel: indentLevel ?? this.indentLevel,
      headingStyle: headingStyle ?? this.headingStyle,
      tags: tags ?? this.tags,
      id: id, // Preserve original ID
      metadata: metadata.copyWith(), // Updates lastModified
    );
  }

  // === Serialization ===
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'content': content,
    'imagePath': imagePath,
    'indentLevel': indentLevel,
    'headingStyle': headingStyle.index,
    'tags': tags,
    'metadata': metadata.toJson(),
  };

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      type: SectionType.values[json['type']],
      content: json['content'],
      imagePath: json['imagePath'],
      id: json['id'],
      indentLevel: json['indentLevel'],
      headingStyle: HeadingStyle.values[json['headingStyle']],
      tags: List<String>.from(json['tags']),
      metadata: DocumentMetadata.fromJson(json['metadata']),
    );
  }

  // === Utility Methods ===
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  bool get isHeader => type == SectionType.header;

  double get suggestedHeight {
    switch (type) {
      case SectionType.header:
        return 60.0;
      case SectionType.image:
        return 200.0;
      default:
        return 120.0;
    }
  }
}