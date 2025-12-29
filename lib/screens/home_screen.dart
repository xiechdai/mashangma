import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/clipboard_service.dart';
import '../services/code_generator.dart';
import '../models/code_type.dart';
import '../utils/permissions.dart';
import '../utils/constants.dart';
import '../widgets/code_display.dart';
import '../widgets/code_type_selector.dart';
import 'input_screen.dart';
import 'settings_screen.dart';
import 'clipboard_history_screen.dart';
import 'encode_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _currentContent = '';
  CodeType _currentType = CodeType.qrCode;
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  StreamSubscription<String>? _clipboardSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 检查是否首次启动
      await _checkFirstLaunch();
      
      // 请求权限
      await _requestPermissions();
      
      // 初始化编码生成器设置
      await CodeGenerator.instance.init();
      _currentType = CodeGenerator.instance.currentType;
      
      // 读取剪贴板内容
      await _loadClipboardContent();
      
      // 监听剪贴板变化
      _setupClipboardListener();
      
    } catch (e) {
      _showErrorDialog('应用初始化失败', '请重启应用或联系开发者');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    // 这里可以检查是否首次启动，显示欢迎页面
    // 简化处理，直接设置不是首次启动
    _isFirstLaunch = false;
  }

  Future<void> _requestPermissions() async {
    try {
      // 检查剪贴板权限
      final hasClipboardPermission = await PermissionUtils.hasClipboardPermission();
      if (!hasClipboardPermission) {
        final granted = await PermissionUtils.requestClipboardPermission();
        if (!granted) {
          _showPermissionRationale('剪贴板权限', '应用需要读取剪贴板内容来自动生成编码');
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadClipboardContent() async {
    try {
      final content = await ClipboardService.instance.getCurrentContent();
      if (content != null && content.isNotEmpty) {
        setState(() {
          _currentContent = content;
          _currentType = CodeGenerator.instance.detectBestType(content);
        });
      } else {
        // 如果剪贴板为空，使用默认内容
        _setDefaultContent();
      }
    } catch (e) {
      _setDefaultContent();
    }
  }

  void _setDefaultContent() {
    final defaultContent = CodeGenerator.instance.getDefaultContent();
    setState(() {
      _currentContent = defaultContent;
      _currentType = CodeType.qrCode;
    });
  }

  void _setupClipboardListener() {
    _clipboardSubscription = ClipboardService.instance.contentStream.listen(
      (content) {
        if (content.isNotEmpty && content != _currentContent) {
          setState(() {
            _currentContent = content;
            _currentType = CodeGenerator.instance.detectBestType(content);
          });
        }
      },
      onError: (error) {
      },
    );
  }

  void _onAppResumed() async {
    // 应用恢复到前台时，重新读取剪贴板内容
    await _loadClipboardContent();
  }

  void _onAppPaused() {
    // 应用进入后台时的处理
  }

  void _onTypeChanged(CodeType type) {
    setState(() {
      _currentType = type;
    });
    
    // 保存到编码历史
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    try {
      await CodeGenerator.instance.generateAndSave(
        _currentContent,
        type: _currentType,
      );
    } catch (e) {
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionRationale(String permission, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('请求$permission'),
          content: Text('$message。\n\n此权限对于应用正常工作至关重要。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: const Text('授权'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              Constants.appName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
      leading: IconButton(
        onPressed: _navigateToEncodeHistory,
        icon: const Icon(Icons.history),
        tooltip: '编码历史',
      ),
      actions: [
        IconButton(
          onPressed: _navigateToInput,
          icon: const Icon(Icons.edit),
          tooltip: '手动输入',
        ),
        IconButton(
          onPressed: _navigateToSettings,
          icon: const Icon(Icons.settings),
          tooltip: '设置',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在初始化...'),
          ],
        ),
      );
    }

    if (_currentContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_paste_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '剪贴板暂无内容',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已为您生成当前日期二维码',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToInput,
              icon: const Icon(Icons.edit),
              label: const Text('手动输入'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 编码类型选择器
        CodeTypeSelector(
          selectedType: _currentType,
          onTypeChanged: _onTypeChanged,
        ),
        
        const SizedBox(height: Constants.smallPadding),
        
        // 编码显示区域
        Expanded(
          child: CodeDisplay(
            content: _currentContent,
            codeType: _currentType,
            onTypeChanged: () {
              // 这里可以处理类型切换逻辑
            },
            onEdit: _navigateToInput,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToClipboardHistory,
      icon: const Icon(Icons.history),
      label: const Text('剪贴板'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  void _navigateToInput() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const InputScreen()),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _currentContent = result;
        _currentType = CodeGenerator.instance.detectBestType(result);
      });
      _saveToHistory();
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToClipboardHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClipboardHistoryScreen()),
    );
  }

  void _navigateToEncodeHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EncodeHistoryScreen()),
    );
  }
}