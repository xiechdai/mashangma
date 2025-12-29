import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clipboard_record.dart';
import '../models/code_type.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/sensitive_filter.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  static ClipboardService get instance => _instance;

  bool _isListening = false;
  String? _lastContent;
  Timer? _debounceTimer;
  
  final StreamController<ClipboardRecord> _clipboardStreamController = 
      StreamController<ClipboardRecord>.broadcast();
  
  final StreamController<String> _contentStreamController = 
      StreamController<String>.broadcast();

  Stream<ClipboardRecord> get clipboardStream => _clipboardStreamController.stream;
  Stream<String> get contentStream => _contentStreamController.stream;

  String? get lastContent => _lastContent;

  Future<void> init() async {
    // 读取用户设置
    final prefs = await SharedPreferences.getInstance();
    _isListening = prefs.getBool(Constants.clipboardListeningKey) ?? 
                   Constants.defaultClipboardListening;

    // 如果开启了剪贴板监听，则启动监听
    if (_isListening) {
      _startListening();
    }

    // 读取初始剪贴板内容
    await _readCurrentClipboard();
  }

  Future<void> _readCurrentClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      String? content = clipboardData?.text;
      if (content != null && content.isNotEmpty && content != _lastContent) {
        _lastContent = content;
        _contentStreamController.add(content);
        
        // 保存到数据库
        await _saveToHistory(content);
      }
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  void _startListening() {
    if (_isListening) return;
    // 简化处理，不使用第三方监听库
    _isListening = true;
  }

  void _stopListening() {
    _isListening = false;
  }

  Future<void> _processClipboardChange(String content) async {
    try {
      _lastContent = content;
      _contentStreamController.add(content);
      
      // 保存到历史记录
      await _saveToHistory(content);
      
      // 通知监听者
      final record = ClipboardRecord(
        content: content,
        contentType: _detectContentType(content),
        copiedAt: DateTime.now().millisecondsSinceEpoch,
        isSensitive: SensitiveFilter.isSensitive(content) ? 1 : 0,
      );
      
      _clipboardStreamController.add(record);
      
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  Future<void> _saveToHistory(String content) async {
    try {
      // 检查是否为敏感内容
      final isSensitive = SensitiveFilter.isSensitive(content);
      
      // 过滤敏感内容（如果开启了敏感词过滤）
      final prefs = await SharedPreferences.getInstance();
      final filterEnabled = prefs.getBool(Constants.sensitiveFilterKey) ?? 
                           Constants.defaultSensitiveFilter;
      
      if (isSensitive && filterEnabled) {
        return; // 不保存敏感内容
      }

      final record = ClipboardRecord(
        content: content,
        contentType: _detectContentType(content),
        copiedAt: DateTime.now().millisecondsSinceEpoch,
        isSensitive: isSensitive ? 1 : 0,
      );

      await DatabaseService.instance.insertClipboardRecord(record);
      
      // 限制历史记录数量
      final limit = prefs.getInt(Constants.clipboardRecordLimitKey) ?? 
                   Constants.defaultClipboardRecordLimit;
      await DatabaseService.instance.limitClipboardRecords(limit);
      
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  String _detectContentType(String content) {
    if (content.isEmpty) return Constants.contentTypeText;

    // 检查是否为URL
    if (RegExp(r'^https?://').hasMatch(content) || 
        RegExp(r'^www\.').hasMatch(content) ||
        RegExp(r'\.com$|\.cn$|\.org$|\.net$').hasMatch(content)) {
      return Constants.contentTypeUrl;
    }

    // 检查是否为邮箱
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(content)) {
      return Constants.contentTypeEmail;
    }

    // 检查是否为手机号
    if (RegExp(r'^1[3-9]\d{9}$').hasMatch(content)) {
      return Constants.contentTypePhone;
    }

    // 检查是否为纯数字
    if (RegExp(r'^\d+$').hasMatch(content)) {
      return Constants.contentTypeNumber;
    }

    return Constants.contentTypeText;
  }

  Future<String?> getCurrentContent() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      return clipboardData?.text;
    } catch (e) {
      return null;
    }
  }

  Future<void> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      _lastContent = content;
      _contentStreamController.add(content);
      
      // 保存到历史记录
      await _saveToHistory(content);
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  Future<List<ClipboardRecord>> getHistory({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      return await DatabaseService.instance.getClipboardRecords(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      return [];
    }
  }

  Future<ClipboardRecord?> getLatestHistory() async {
    try {
      return await DatabaseService.instance.getLatestClipboardRecord();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteHistoryRecord(int id) async {
    try {
      await DatabaseService.instance.deleteClipboardRecord(id);
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await DatabaseService.instance.clearClipboardRecords();
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  Future<bool> isListeningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.clipboardListeningKey) ?? 
           Constants.defaultClipboardListening;
  }

  Future<void> setListeningEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(Constants.clipboardListeningKey, enabled);
      
      if (enabled && !_isListening) {
        _startListening();
      } else if (!enabled && _isListening) {
        _stopListening();
      }
    } catch (e) {
      debugPrint('ClipboardService error: $e');
    }
  }

  Future<void> toggleListening() async {
    final current = await isListeningEnabled();
    await setListeningEnabled(!current);
  }

  // 智能识别最适合的编码类型
  CodeType detectBestCodeType(String content) {
    return CodeType.detectBestType(content);
  }

  // 获取剪贴板统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = DatabaseService.instance;
      final totalRecords = await db.getClipboardRecordsCount();
      final recentRecords = await db.getClipboardRecords(limit: 10);
      
      // 统计内容类型分布
      Map<String, int> typeDistribution = {};
      for (final record in recentRecords) {
        typeDistribution[record.contentType] = 
            (typeDistribution[record.contentType] ?? 0) + 1;
      }
      
      return {
        'total_records': totalRecords,
        'type_distribution': typeDistribution,
        'latest_content': _lastContent,
        'is_listening': _isListening,
      };
    } catch (e) {
      return {};
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _stopListening();
    _clipboardStreamController.close();
    _contentStreamController.close();
  }
}