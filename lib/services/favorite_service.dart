import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_record.dart';
import '../models/code_type.dart';

class FavoriteService {
  static const String _favoritesKey = 'instant_code_favorites';
  static const int _maxRecords = 200; // 收藏可以保存更多

  // 保存收藏记录到SharedPreferences
  static Future<int> addFavoriteRecord(FavoriteRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getAllFavoriteRecords();
      
      // 检查是否已存在相同的收藏
      final exists = records.any((r) => 
          r.content == record.content && r.codeType == record.codeType);
      
      if (exists) {
        return -1;
      }
      
      // 添加新记录
      final newRecord = record.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      records.insert(0, newRecord);
      
      // 限制数量
      if (records.length > _maxRecords) {
        records.removeRange(_maxRecords, records.length);
      }
      
      // 保存到SharedPreferences
      final jsonList = records.map((r) => _recordToJson(r)).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      
      return newRecord.id;
    } catch (e) {
      return -1;
    }
  }

  // 获取所有收藏记录
  static Future<List<FavoriteRecord>> getAllFavoriteRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_favoritesKey);
      
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

  // 根据ID获取收藏记录
  static Future<FavoriteRecord?> getFavoriteRecordById(int id) async {
    try {
      final records = await getAllFavoriteRecords();
      return records.firstWhere(
        (record) => record.id == id,
        orElse: () => throw Exception('记录未找到'),
      );
    } catch (e) {
      return null;
    }
  }

  // 更新收藏记录
  static Future<int> updateFavoriteRecord(FavoriteRecord record) async {
    try {
      final records = await getAllFavoriteRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      
      if (index != -1) {
        records[index] = record;
        
        final prefs = await SharedPreferences.getInstance();
        final jsonList = records.map((r) => _recordToJson(r)).toList();
        await prefs.setString(_favoritesKey, jsonEncode(jsonList));
        
        return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // 删除收藏记录
  static Future<int> deleteFavoriteRecord(int id) async {
    try {
      final records = await getAllFavoriteRecords();
      records.removeWhere((record) => record.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = records.map((r) => _recordToJson(r)).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // 检查是否已收藏
  static Future<bool> isFavorite(String content, CodeType codeType) async {
    try {
      final records = await getAllFavoriteRecords();
      return records.any((record) => 
          record.content == content && record.codeType == codeType);
    } catch (e) {
      return false;
    }
  }

  // 搜索收藏记录
  static Future<List<FavoriteRecord>> searchFavoriteRecords(String query) async {
    try {
      final records = await getAllFavoriteRecords();
      final lowerQuery = query.toLowerCase();
      
      return records.where((record) {
        final contentMatch = record.content.toLowerCase().contains(lowerQuery);
        final labelMatch = record.label?.toLowerCase().contains(lowerQuery) ?? false;
        final categoryMatch = record.category?.toLowerCase().contains(lowerQuery) ?? false;
        return contentMatch || labelMatch || categoryMatch;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 根据码类型获取收藏记录
  static Future<List<FavoriteRecord>> getFavoriteRecordsByType(CodeType codeType) async {
    try {
      final records = await getAllFavoriteRecords();
      return records.where((record) => record.codeType == codeType).toList();
    } catch (e) {
      return [];
    }
  }

  // 根据分类获取收藏记录
  static Future<List<FavoriteRecord>> getFavoriteRecordsByCategory(String category) async {
    try {
      final records = await getAllFavoriteRecords();
      return records.where((record) => record.category == category).toList();
    } catch (e) {
      return [];
    }
  }

  // 获取所有分类
  static Future<List<String>> getAllCategories() async {
    try {
      final records = await getAllFavoriteRecords();
      final Set<String> categories = {};
      
      for (final record in records) {
        if (record.category != null && record.category!.isNotEmpty) {
          categories.add(record.category!);
        }
      }
      
      final categoryList = categories.toList();
      categoryList.sort(); // 按字母排序
      return categoryList;
    } catch (e) {
      return [];
    }
  }

  // 清空所有收藏记录
  static Future<int> clearAllFavoriteRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      
      return 1;
    } catch (e) {
      return 0;
    }
  }

  // 获取收藏记录统计
  static Future<Map<String, int>> getFavoriteStats() async {
    try {
      final records = await getAllFavoriteRecords();
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
  static Map<String, dynamic> _recordToJson(FavoriteRecord record) {
    return {
      'id': record.id,
      'content': record.content,
      'codeType': record.codeType.value,
      'createdAt': record.createdAt.millisecondsSinceEpoch,
      'label': record.label,
      'category': record.category,
    };
  }

  // 从JSON创建记录
  static FavoriteRecord _recordFromJson(Map<String, dynamic> json) {
    return FavoriteRecord(
      id: json['id'],
      content: json['content'],
      codeType: CodeType.values.firstWhere(
        (type) => type.value == json['codeType'],
        orElse: () => CodeType.qrCode,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      label: json['label'],
      category: json['category'],
    );
  }
}