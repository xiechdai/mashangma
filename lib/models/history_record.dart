import '../models/code_type.dart';

class HistoryRecord {
  final int id;
  final String content;
  final CodeType codeType;
  final DateTime createdAt;
  final String? label;

  const HistoryRecord({
    required this.id,
    required this.content,
    required this.codeType,
    required this.createdAt,
    this.label,
  });

  // 创建数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'codeType': codeType.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'label': label,
    };
  }

  // 从数据库映射创建对象
  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      id: map['id'],
      content: map['content'],
      codeType: CodeType.values.firstWhere(
        (type) => type.value == map['codeType'],
        orElse: () => CodeType.qrCode,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      label: map['label'],
    );
  }

  // 创建副本（用于修改）
  HistoryRecord copyWith({
    int? id,
    String? content,
    CodeType? codeType,
    DateTime? createdAt,
    String? label,
  }) {
    return HistoryRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      codeType: codeType ?? this.codeType,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryRecord &&
        other.id == id &&
        other.content == content &&
        other.codeType == codeType &&
        other.createdAt == createdAt &&
        other.label == label;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        codeType.hashCode ^
        createdAt.hashCode ^
        label.hashCode;
  }

  @override
  String toString() {
    return 'HistoryRecord(id: $id, content: $content, codeType: $codeType, createdAt: $createdAt, label: $label)';
  }
}