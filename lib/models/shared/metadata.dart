class DocumentMetadata {
  final DateTime createdAt;
  final String createdBy;
  final DateTime lastModified;
  final String modifiedBy;

  DocumentMetadata({
    DateTime? createdAt,
    this.createdBy = 'system',
    DateTime? lastModified,
    this.modifiedBy = 'system',
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastModified = lastModified ?? DateTime.now();

  DocumentMetadata copyWith() {
    return DocumentMetadata(
      createdAt: createdAt,
      createdBy: createdBy,
      modifiedBy: modifiedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'lastModified': lastModified.toIso8601String(),
    'modifiedBy': modifiedBy,
  };

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) => DocumentMetadata(
    createdAt: DateTime.parse(json['createdAt']),
    createdBy: json['createdBy'],
    lastModified: DateTime.parse(json['lastModified']),
    modifiedBy: json['modifiedBy'],
  );
}