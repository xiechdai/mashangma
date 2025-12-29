import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_record.dart';
import '../models/code_type.dart';

class SimpleHistoryService {
  static const String _historyKey = 'instant_code_history';
  static const int _maxRecords = 50; // 减少记录数

  // 保存历史记录到SharedPreferences
  static Future<int> addHistoryRecord(HistoryRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getAllHistoryRecords();
      
      // 添加新记录
      final newRecord = record.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      records.insert(0, newRecord);
      
      // 限制数量
      if (records.length > _maxRecords) {
        records.removeRange(_maxRecords, records.length);
      }
      
      // 保存到SharedPreferences
      final jsonList = records.map((r) => _recordToJson(r)).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
      
      return newRecord.id;
    } catch (e) {
      return -1;
    }
  }

  // 获取所有历史记录
  static Future<List<HistoryRecord>> getAllHistoryRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_historyKey);
      
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final records = jsonList.map((json) => _recordFromJson(json)).toList();
      
      return records;
    } catch (e) {
      return [];
    }
  }

  // 根据ID获取历史记录
  static Future<HistoryRecord?> getHistoryRecordById(int id) async {
    try {
      final records = await getAllHistoryRecords();
      return records.firstWhere(
        (record) => record.id == id,
        orElse: () => throw Exception('记录未找到'),
      );
    } catch (e) {
      return null;
    }
  }

  // 更新历史记录
  static Future<int> updateHistoryRecord(HistoryRecord record) async {
    try {
      final records = await getAllHistoryRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      
      if (index != -1) {
        records[index] = record;
        
        final prefs = await SharedPreferences.getInstance();
        final jsonList = records.map((r) => _recordToJson(r)).toList();
        await prefs.setString(_historyKey, jsonEncode(jsonList));
        
        return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // 删除历史记录
  static Future<int> deleteHistoryRecord(int id) async {
    try {
      final records = await getAllHistoryRecords();
      records.removeWhere((record) => record.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = records.map((r) => _recordToJson(r)).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
      
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // 清空所有历史记录
  static Future<int> clearAllHistoryRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // 搜索历史记录
  static Future<List<HistoryRecord>> searchHistoryRecords(String query) async {
    try {
      final records = await getAllHistoryRecords();
      final lowerQuery = query.toLowerCase();
      
      return records.where((record) {
        final contentMatch = record.content.toLowerCase().contains(lowerQuery);
        final labelMatch = record.label?.toLowerCase().contains(lowerQuery) ?? false;
        return contentMatch || labelMatch;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 根据码类型获取历史记录
  static Future<List<HistoryRecord>> getHistoryRecordsByType(CodeType codeType) async {
    try {
      final records = await getAllHistoryRecords();
      return records.where((record) => record.codeType == codeType).toList();
    } catch (e) {
      return [];
    }
  }

  // 获取历史记录统计
  static Future<Map<String, int>> getHistoryStats() async {
    try {
      final records = await getAllHistoryRecords();
      Map<String, int> stats = {};
      
      for (final record in records) {
        final type = record.codeType.value;
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      return {};
    }
  }

  // 将记录转换为JSON
  static Map<String, dynamic> _recordToJson(HistoryRecord record) {
    return {
      'id': record.id,
      'content': record.content,
      'codeType': record.codeType.value,
      'createdAt': record.createdAt.millisecondsSinceEpoch,
      'label': record.label,
    };
  }

  // 从JSON创建记录
  static HistoryRecord _recordFromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'],
      content: json['content'],
      codeType: CodeType.values.firstWhere(
        (type) => type.value == json['codeType'],
        orElse: () => CodeType.qrCode,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      label: json['label'],
    );
  }
}