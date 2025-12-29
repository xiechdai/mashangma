import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ClipboardMonitor {
  static final ClipboardMonitor _instance = ClipboardMonitor._internal();
  factory ClipboardMonitor() => _instance;
  ClipboardMonitor._internal();

  static const String _isolateName = 'clipboard_monitor_isolate';
  
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  Isolate? _isolate;
  bool _isRunning = false;
  Timer? _heartbeatTimer;
  
  final StreamController<String> _clipboardStreamController = 
      StreamController<String>.broadcast();
  
  Stream<String> get clipboardStream => _clipboardStreamController.stream;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(Constants.clipboardListeningKey) ?? 
                     Constants.defaultClipboardListening;
      
      if (!enabled) return;

      await _startIsolate();
      _isRunning = true;
      
      // 启动心跳检测
      _startHeartbeat();
      
    } catch (e) {
      debugPrint('ClipboardMonitor start error: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      _heartbeatTimer?.cancel();
      await _stopIsolate();
      _isRunning = false;
    } catch (e) {
      debugPrint('ClipboardMonitor stop error: $e');
    }
  }

  Future<void> _startIsolate() async {
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _clipboardMonitorIsolate,
      _receivePort!.sendPort,
      debugName: _isolateName,
    );

    _receivePort!.listen((message) {
      if (message is String && message != 'heartbeat') {
        _handleClipboardMessage(message);
      } else if (message == 'heartbeat') {
        // 心跳消息，用于检测Isolate是否存活
      }
    });
  }

  Future<void> _stopIsolate() async {
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort = null;
  }

  void _handleClipboardMessage(String message) {
    try {
      // 处理剪贴板内容变化
      if (message.startsWith('clipboard:')) {
        final content = message.substring(10); // 移除 'clipboard:' 前缀
        _clipboardStreamController.add(content);
      }
    } catch (e) {
      debugPrint('ClipboardMonitor handle message error: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkIsolateHealth(),
    );
  }

  Future<void> _checkIsolateHealth() async {
    try {
      // 发送心跳检查
      _sendPort?.send('ping');
    } catch (e) {
      // 如果Isolate已经死亡，尝试重启
      await _restartIsolate();
    }
  }

  Future<void> _restartIsolate() async {
    try {
      await _stopIsolate();
      await _startIsolate();
      _isRunning = true;
    } catch (e) {
      debugPrint('ClipboardMonitor restart isolate error: $e');
    }
  }

  static void _clipboardMonitorIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    String? lastContent;
    Timer? monitorTimer;
    Timer? heartbeatTimer;

    // 启动剪贴板监听定时器
    monitorTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) async {
        try {
          // 这里应该使用平台通道来获取剪贴板内容
          // 由于在Isolate中无法直接访问Flutter的API，
          // 需要通过其他方式实现
          final currentContent = await _getClipboardContentFromNative();
          
          if (currentContent != null && 
              currentContent.isNotEmpty && 
              currentContent != lastContent) {
            lastContent = currentContent;
            sendPort.send('clipboard:$currentContent');
          }
        } catch (e) {
          debugPrint('ClipboardMonitor isolate error: $e');
        }
      },
    );

    // 启动心跳定时器
    heartbeatTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => sendPort.send('heartbeat'),
    );

    receivePort.listen(
      (message) {
        if (message == 'ping') {
          // 响应心跳
          sendPort.send('pong');
        }
      },
      onDone: () {
        // 监听 done 事件来清理资源
        monitorTimer?.cancel();
        heartbeatTimer?.cancel();
      },
    );


  }

  static Future<String?> _getClipboardContentFromNative() async {
    try {
      // 这里应该通过平台通道调用原生代码获取剪贴板内容
      // 由于在Isolate中无法直接使用PlatformChannel，
      // 这里返回null，实际实现需要其他方案
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _stopIsolate();
    _clipboardStreamController.close();
  }
}

// 简化版的剪贴板监听服务
class SimpleClipboardMonitor {
  static final SimpleClipboardMonitor _instance = SimpleClipboardMonitor._internal();
  factory SimpleClipboardMonitor() => _instance;
  SimpleClipboardMonitor._internal();

  Timer? _monitorTimer;
  bool _isRunning = false;
  
  final StreamController<String> _clipboardStreamController = 
      StreamController<String>.broadcast();
  
  Stream<String> get clipboardStream => _clipboardStreamController.stream;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(Constants.clipboardListeningKey) ?? 
                     Constants.defaultClipboardListening;
      
      if (!enabled) return;

      _monitorTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _checkClipboard(),
      );
      
      _isRunning = true;
    } catch (e) {
      debugPrint('SimpleClipboardMonitor start error: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _monitorTimer?.cancel();
    _isRunning = false;
  }

  Future<void> _checkClipboard() async {
    try {
      // 这里需要通过其他方式获取剪贴板内容
      // 由于Flutter的限制，这里使用定时检查的方式
      // 实际项目中可能需要使用原生插件
      
      // 暂时跳过实际检查，等待具体的剪贴板API
    } catch (e) {
      debugPrint('SimpleClipboardMonitor check clipboard error: $e');
    }
  }

  void dispose() {
    _monitorTimer?.cancel();
    _clipboardStreamController.close();
  }
}