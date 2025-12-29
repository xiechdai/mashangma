import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_record.dart';
import '../models/code_type.dart';

class HistoryService {
  static Database? _database;
  static const String _tableName = 'history';
  static const int _maxRecords = 100; // 最大保存100条记录

  // 获取数据库实例
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  static Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'instant_code.db');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT NOT NULL,
              codeType TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              label TEXT
            )
          ''');
        },
      );
    } catch (e) {

      rethrow;
    }
  }

  // 添加历史记录
  static Future<int> addHistoryRecord(HistoryRecord record) async {
    final db = await database;
    
    try {
      final id = await db.insert(
        _tableName,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // 检查并清理旧记录
      await _cleanupOldRecords();
      
      return id;
    } catch (e) {
      return -1;
    }
  }

  // 获取所有历史记录
  static Future<List<HistoryRecord>> getAllHistoryRecords() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'createdAt DESC',
        limit: _maxRecords,
      );
      
      final records = List.generate(maps.length, (i) {
        return HistoryRecord.fromMap(maps[i]);
      });
      
      return records;
    } catch (e) {
      return [];
    }
  }

  // 根据ID获取历史记录
  static Future<HistoryRecord?> getHistoryRecordById(int id) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return HistoryRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 更新历史记录
  static Future<int> updateHistoryRecord(HistoryRecord record) async {
    final db = await database;
    
    try {
      return await db.update(
        _tableName,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
    } catch (e) {
      return 0;
    }
  }

  // 删除历史记录
  static Future<int> deleteHistoryRecord(int id) async {
    final db = await database;
    
    try {
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return 0;
    }
  }

  // 清空所有历史记录
  static Future<int> clearAllHistoryRecords() async {
    final db = await database;
    
    try {
      return await db.delete(_tableName);
    } catch (e) {
      return 0;
    }
  }

  // 搜索历史记录
  static Future<List<HistoryRecord>> searchHistoryRecords(String query) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'content LIKE ? OR label LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'createdAt DESC',
        limit: 50,
      );
      
      return List.generate(maps.length, (i) {
        return HistoryRecord.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // 根据码类型获取历史记录
  static Future<List<HistoryRecord>> getHistoryRecordsByType(CodeType codeType) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codeType = ?',
        whereArgs: [codeType.value],
        orderBy: 'createdAt DESC',
        limit: 50,
      );
      
      return List.generate(maps.length, (i) {
        return HistoryRecord.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // 清理旧记录（保持最大记录数限制）
  static Future<void> _cleanupOldRecords() async {
    final db = await database;
    
    try {
      // 获取当前记录数
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final count = result.first['count'] as int;
      
      if (count > _maxRecords) {
        // 删除最旧的记录
        final deleteCount = count - _maxRecords;
        await db.rawDelete('''
          DELETE FROM $_tableName 
          WHERE id IN (
            SELECT id FROM $_tableName 
            ORDER BY createdAt ASC 
            LIMIT ?
          )
        ''', [deleteCount]);
      }
    } catch (e) {
      debugPrint('HistoryService cleanup error: $e');
    }
  }

  // 获取历史记录统计
  static Future<Map<String, int>> getHistoryStats() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('''
        SELECT codeType, COUNT(*) as count 
        FROM $_tableName 
        GROUP BY codeType
      ''');
      
      Map<String, int> stats = {};
      for (final row in result) {
        stats[row['codeType'] as String] = row['count'] as int;
      }
      
      return stats;
    } catch (e) {
      return {};
    }
  }

  // 关闭数据库
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}