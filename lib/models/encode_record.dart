class EncodeRecord {
  final int? id;
  final String content;
  final String codeType;
  final int createdAt;
  final String? thumbnail;

  EncodeRecord({
    this.id,
    required this.content,
    required this.codeType,
    required this.createdAt,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'code_type': codeType,
      'created_at': createdAt,
      'thumbnail': thumbnail,
    };
  }

  factory EncodeRecord.fromMap(Map<String, dynamic> map) {
    return EncodeRecord(
      id: map['id']?.toInt(),
      content: map['content'] ?? '',
      codeType: map['code_type'] ?? '',
      createdAt: map['created_at']?.toInt() ?? 0,
      thumbnail: map['thumbnail'],
    );
  }

  EncodeRecord copyWith({
    int? id,
    String? content,
    String? codeType,
    int? createdAt,
    String? thumbnail,
  }) {
    return EncodeRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      codeType: codeType ?? this.codeType,
      createdAt: createdAt ?? this.createdAt,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  @override
  String toString() {
    return 'EncodeRecord(id: $id, content: $content, codeType: $codeType, createdAt: $createdAt, thumbnail: $thumbnail)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncodeRecord &&
        other.id == id &&
        other.content == content &&
        other.codeType == codeType &&
        other.createdAt == createdAt &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        codeType.hashCode ^
        createdAt.hashCode ^
        thumbnail.hashCode;
  }
}