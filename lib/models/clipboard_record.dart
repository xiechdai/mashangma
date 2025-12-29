class ClipboardRecord {
  final int? id;
  final String content;
  final String contentType;
  final int copiedAt;
  final int isSensitive;

  ClipboardRecord({
    this.id,
    required this.content,
    required this.contentType,
    required this.copiedAt,
    this.isSensitive = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'content_type': contentType,
      'copied_at': copiedAt,
      'is_sensitive': isSensitive,
    };
  }

  factory ClipboardRecord.fromMap(Map<String, dynamic> map) {
    return ClipboardRecord(
      id: map['id']?.toInt(),
      content: map['content'] ?? '',
      contentType: map['content_type'] ?? '',
      copiedAt: map['copied_at']?.toInt() ?? 0,
      isSensitive: map['is_sensitive']?.toInt() ?? 0,
    );
  }

  ClipboardRecord copyWith({
    int? id,
    String? content,
    String? contentType,
    int? copiedAt,
    int? isSensitive,
  }) {
    return ClipboardRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      copiedAt: copiedAt ?? this.copiedAt,
      isSensitive: isSensitive ?? this.isSensitive,
    );
  }

  @override
  String toString() {
    return 'ClipboardRecord(id: $id, content: $content, contentType: $contentType, copiedAt: $copiedAt, isSensitive: $isSensitive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipboardRecord &&
        other.id == id &&
        other.content == content &&
        other.contentType == contentType &&
        other.copiedAt == copiedAt &&
        other.isSensitive == isSensitive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        contentType.hashCode ^
        copiedAt.hashCode ^
        isSensitive.hashCode;
  }
}