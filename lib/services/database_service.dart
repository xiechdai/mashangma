import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/clipboard_record.dart';
import '../models/encode_record.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  static DatabaseService get instance => _instance;

  Future<void> init() async {
    if (_database != null) return;
    
    String path = join(await getDatabasesPath(), Constants.databaseName);
    
    _database = await openDatabase(
      path,
      version: Constants.databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 创建剪贴板记录表
    await db.execute('''
      CREATE TABLE ${Constants.clipboardTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        content_type TEXT NOT NULL,
        copied_at INTEGER NOT NULL,
        is_sensitive INTEGER DEFAULT 0
      )
    ''');

    // 创建编码历史表
    await db.execute('''
      CREATE TABLE ${Constants.encodeTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        code_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        thumbnail TEXT
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_clipboard_copied_at ON ${Constants.clipboardTable}(copied_at DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_clipboard_content ON ${Constants.clipboardTable}(content)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_encode_created_at ON ${Constants.encodeTable}(created_at DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_encode_content ON ${Constants.encodeTable}(content)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    if (oldVersion < 2) {
      // 添加新字段或表
    }
  }

  // 剪贴板记录相关操作
  Future<int> insertClipboardRecord(ClipboardRecord record) async {
    final db = _database!;
    return await db.insert(
      Constants.clipboardTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ClipboardRecord>> getClipboardRecords({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = _database!;
    
    String query = '''
      SELECT * FROM ${Constants.clipboardTable}
      WHERE is_sensitive = 0
    ''';
    
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND content LIKE ?';
      args.add('%$searchQuery%');
    }
    
    query += ' ORDER BY copied_at DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    
    return List.generate(maps.length, (i) {
      return ClipboardRecord.fromMap(maps[i]);
    });
  }

  Future<ClipboardRecord?> getLatestClipboardRecord() async {
    final db = _database!;
    
    final List<Map<String, dynamic>> maps = await db.query(
      Constants.clipboardTable,
      where: 'is_sensitive = 0',
      orderBy: 'copied_at DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return ClipboardRecord.fromMap(maps.first);
    }
    
    return null;
  }

  Future<int> deleteClipboardRecord(int id) async {
    final db = _database!;
    return await db.delete(
      Constants.clipboardTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearClipboardRecords() async {
    final db = _database!;
    return await db.delete(Constants.clipboardTable);
  }

  Future<int> getClipboardRecordsCount() async {
    final db = _database!;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${Constants.clipboardTable} WHERE is_sensitive = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 限制剪贴板记录数量
  Future<void> limitClipboardRecords(int maxRecords) async {
    final db = _database!;
    final count = await getClipboardRecordsCount();
    
    if (count > maxRecords) {
      final toDelete = count - maxRecords;
      await db.rawDelete('''
        DELETE FROM ${Constants.clipboardTable}
        WHERE id IN (
          SELECT id FROM ${Constants.clipboardTable}
          ORDER BY copied_at ASC
          LIMIT ?
        )
      ''', [toDelete]);
    }
  }

  // 编码历史记录相关操作
  Future<int> insertEncodeRecord(EncodeRecord record) async {
    final db = _database!;
    return await db.insert(
      Constants.encodeTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EncodeRecord>> getEncodeRecords({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = _database!;
    
    String query = '''
      SELECT * FROM ${Constants.encodeTable}
    ''';
    
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' WHERE content LIKE ?';
      args.add('%$searchQuery%');
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    
    return List.generate(maps.length, (i) {
      return EncodeRecord.fromMap(maps[i]);
    });
  }

  Future<EncodeRecord?> getLatestEncodeRecord() async {
    final db = _database!;
    
    final List<Map<String, dynamic>> maps = await db.query(
      Constants.encodeTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return EncodeRecord.fromMap(maps.first);
    }
    
    return null;
  }

  Future<int> deleteEncodeRecord(int id) async {
    final db = _database!;
    return await db.delete(
      Constants.encodeTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearEncodeRecords() async {
    final db = _database!;
    return await db.delete(Constants.encodeTable);
  }

  Future<int> getEncodeRecordsCount() async {
    final db = _database!;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${Constants.encodeTable}'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 限制编码历史记录数量
  Future<void> limitEncodeRecords(int maxRecords) async {
    final db = _database!;
    final count = await getEncodeRecordsCount();
    
    if (count > maxRecords) {
      final toDelete = count - maxRecords;
      await db.rawDelete('''
        DELETE FROM ${Constants.encodeTable}
        WHERE id IN (
          SELECT id FROM ${Constants.encodeTable}
          ORDER BY created_at ASC
          LIMIT ?
        )
      ''', [toDelete]);
    }
  }

  // 数据库维护
  Future<void> optimizeDatabase() async {
    final db = _database!;
    await db.execute('VACUUM');
    await db.execute('ANALYZE');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final clipboardCount = await getClipboardRecordsCount();
    final encodeCount = await getEncodeRecordsCount();
    
    // 获取数据库文件大小
    // String path = join(await getDatabasesPath(), Constants.databaseName);
    // File dbFile = File(path);
    // int fileSize = await dbFile.length();
    
    return {
      'clipboard_records': clipboardCount,
      'encode_records': encodeCount,
      'total_records': clipboardCount + encodeCount,
      // 'file_size_bytes': fileSize,
    };
  }
}