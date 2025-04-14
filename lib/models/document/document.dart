//lib/models/document/document.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

@immutable
class Document {
  final String id;
  final String title;
  final List<DocumentElement> elements;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorId;
  final List<String> tags;
  final int version;
  final List<Map<String, dynamic>>? deltaContent;

  const Document({
    required this.id,
    required this.title,
    required this.elements,
    required this.createdAt,
    this.updatedAt,
    required this.authorId,
    this.tags = const [],
    this.version = 1,
    this.deltaContent,
  });

  static final empty = Document(
    id: '',
    title: '',
    elements: const [],
    createdAt: DateTime(1970),
    authorId: '',
    version: 0,
    deltaContent: const [],
  );

  factory Document.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data()!;
    return Document(
      deltaContent: (data['delta_content'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      id: snapshot.id,
      title: data['title'] ?? 'Untitled',
      elements: _parseElements(data['elements']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      authorId: data['authorId'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      version: (data['version'] as int?) ?? 1,
    );
  }

  static List<DocumentElement> _parseElements(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => DocumentElement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'elements': elements.map((e) => e.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    'authorId': authorId,
    'tags': tags,
    'version': version,
    'delta_content': deltaContent,
  };

  Document copyWith({
    String? id,
    String? title,
    List<DocumentElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    List<String>? tags,
    int? version,
    List<Map<String, dynamic>>? deltaContent,
  }) => Document(
    id: id ?? this.id,
    title: title ?? this.title,
    elements: elements ?? this.elements,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    authorId: authorId ?? this.authorId,
    tags: tags ?? this.tags,
    version: version ?? this.version,
    deltaContent: deltaContent ?? this.deltaContent,
  );

  Document withUpdate({
    String? title,
    List<DocumentElement>? elements,
    List<String>? tags,
  }) => copyWith(
    title: title,
    elements: elements,
    tags: tags,
    updatedAt: DateTime.now(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          listEquals(elements, other.elements) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          authorId == other.authorId &&
          listEquals(tags, other.tags) &&
          version == other.version;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    elements,
    createdAt,
    updatedAt,
    authorId,
    tags,
    version,
  ]);

  bool get isValid => id.isNotEmpty && title.isNotEmpty;

  String get wordCount => elements
      .where((e) => e.type == 'text')
      .fold<int>(0, (count, e) => count + e.wordCount)
      .toString();
}

@immutable
class DocumentElement {
  final String type;
  final Map<String, dynamic> properties;

  const DocumentElement({
    required this.type,
    required this.properties,
  });

  factory DocumentElement.text(String content, [Offset? position]) => DocumentElement(
    type: 'text',
    properties: {
      'content': content,
      'posX': position?.dx ?? 0.0,
      'posY': position?.dy ?? 0.0,
      'width': 0.0,
      'height': 0.0,
      'wrap': const TextWrapSettings().toJson(),
    },
  );

  factory DocumentElement.image(String url, [Offset? position]) => DocumentElement(
    type: 'image',
    properties: {
      'url': url,
      'posX': position?.dx ?? 0.0,
      'posY': position?.dy ?? 0.0,
      'width': 150.0,
      'height': 150.0,
    },
  );

  factory DocumentElement.fromJson(Map<String, dynamic> json) => DocumentElement(
    type: json['type'] as String,
    properties: Map<String, dynamic>.from(json['properties']),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'properties': properties,
  };

  Offset get position => Offset(
    (properties['posX'] as num).toDouble(),
    (properties['posY'] as num).toDouble(),
  );

  Size get dimensions => Size(
    (properties['width'] as num).toDouble(),
    (properties['height'] as num).toDouble(),
  );

  String get content => properties['content'] as String;
  String get url => properties['url'] as String;

  TextWrapSettings get wrapSettings => TextWrapSettings.fromJson(
    Map<String, dynamic>.from(properties['wrap'] ?? {}),
  );

  DocumentElement copyWith({
    String? type,
    Map<String, dynamic>? properties,
  }) => DocumentElement(
    type: type ?? this.type,
    properties: properties ?? this.properties,
  );

  int get wordCount => type == 'text'
      ? content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length
      : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentElement &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          mapEquals(properties, other.properties);

  @override
  int get hashCode => Object.hash(type, properties);
}

@immutable
class TextWrapSettings {
  final bool wrapLeft;
  final bool wrapRight;
  final double horizontalMargin;
  final double verticalMargin;

  const TextWrapSettings({
    this.wrapLeft = false,
    this.wrapRight = true,
    this.horizontalMargin = 8.0,
    this.verticalMargin = 4.0,
  });

  factory TextWrapSettings.fromJson(Map<String, dynamic> json) => TextWrapSettings(
    wrapLeft: json['wrapLeft'] ?? false,
    wrapRight: json['wrapRight'] ?? true,
    horizontalMargin: (json['hMargin'] as num?)?.toDouble() ?? 8.0,
    verticalMargin: (json['vMargin'] as num?)?.toDouble() ?? 4.0,
  );

  Map<String, dynamic> toJson() => {
    'wrapLeft': wrapLeft,
    'wrapRight': wrapRight,
    'hMargin': horizontalMargin,
    'vMargin': verticalMargin,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextWrapSettings &&
          runtimeType == other.runtimeType &&
          wrapLeft == other.wrapLeft &&
          wrapRight == other.wrapRight &&
          horizontalMargin == other.horizontalMargin &&
          verticalMargin == other.verticalMargin;

  @override
  int get hashCode =>
      Object.hash(wrapLeft, wrapRight, horizontalMargin, verticalMargin);
}