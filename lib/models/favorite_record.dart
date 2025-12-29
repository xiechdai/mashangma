import '../models/code_type.dart';

class FavoriteRecord {
  final int id;
  final String content;
  final CodeType codeType;
  final DateTime createdAt;
  final String? label;
  final String? category; // 收藏分类

  const FavoriteRecord({
    required this.id,
    required this.content,
    required this.codeType,
    required this.createdAt,
    this.label,
    this.category,
  });

  // 创建数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'codeType': codeType.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'label': label,
      'category': category,
    };
  }

  // 从数据库映射创建对象
  factory FavoriteRecord.fromMap(Map<String, dynamic> map) {
    return FavoriteRecord(
      id: map['id'],
      content: map['content'],
      codeType: CodeType.values.firstWhere(
        (type) => type.value == map['codeType'],
        orElse: () => CodeType.qrCode,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      label: map['label'],
      category: map['category'],
    );
  }

  // 创建副本（用于修改）
  FavoriteRecord copyWith({
    int? id,
    String? content,
    CodeType? codeType,
    DateTime? createdAt,
    String? label,
    String? category,
  }) {
    return FavoriteRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      codeType: codeType ?? this.codeType,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteRecord &&
        other.id == id &&
        other.content == content &&
        other.codeType == codeType &&
        other.createdAt == createdAt &&
        other.label == label &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        codeType.hashCode ^
        createdAt.hashCode ^
        label.hashCode ^
        category.hashCode;
  }

  @override
  String toString() {
    return 'FavoriteRecord(id: $id, content: $content, codeType: $codeType, createdAt: $createdAt, label: $label, category: $category)';
  }
}