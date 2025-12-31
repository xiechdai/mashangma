import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

// 只导入Web平台需要的包
import 'dart:html' as html;

// 其他平台的包在需要时通过条件编译使用

// Models
import 'models/code_type.dart';
import 'models/favorite_record.dart';

// Services
import 'services/favorite_service.dart';
import 'services/clipboard_service.dart';
import 'services/code_generator.dart';
import 'services/simple_history_service.dart';
import 'models/history_record.dart'; // 导入HistoryRecord模型

// Screens
import 'screens/menu_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorite_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '马上码',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
      routes: {
        '/history': (context) => const HistoryScreen(),
        '/favorite': (context) => const FavoriteScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final String? initialContent;
  final CodeType? initialCodeType;

  const HomePage({
    super.key,
    this.initialContent,
    this.initialCodeType,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  String _currentText = '';
  CodeType _selectedCodeType = CodeType.qrCode;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    
    // 如果提供了初始内容和编码类型，则使用它们
    if (widget.initialContent != null) {
      _currentText = widget.initialContent!;
      _textController.text = widget.initialContent!;
      _selectedCodeType = widget.initialCodeType ?? CodeType.detectBestType(widget.initialContent!);
    } else {
      _loadClipboardContent();
    }
    
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadClipboardContent() async {
    try {
      final clipboardData = await ClipboardService().getCurrentContent();
      if (clipboardData != null && clipboardData.isNotEmpty) {
        setState(() {
          _currentText = clipboardData;
          _textController.text = clipboardData;
          _selectedCodeType = CodeType.detectBestType(clipboardData);
        });
        _checkFavoriteStatus();
        _saveToHistory();
      }
    } catch (e) {
      debugPrint('Failed to load clipboard content: $e');
    }
  }

  void _onTextChanged() {
    final newText = _textController.text;
    if (newText != _currentText) {
      setState(() {
        _currentText = newText;
        _selectedCodeType = CodeType.detectBestType(newText);
      });
      _checkFavoriteStatus();
      _saveToHistory();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (_currentText.isEmpty) return;
    
    try {
      final records = await FavoriteService.getAllFavoriteRecords();
      final isFav = records.any((record) => 
          record.content == _currentText && record.codeType == _selectedCodeType);
      
      if (mounted && isFav != _isFavorite) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      debugPrint('Failed to check favorite status: $e');
    }
  }

  Future<void> _saveToHistory() async {
    if (_currentText.isEmpty) return;
    
    try {
      final record = HistoryRecord(
        id: DateTime.now().millisecondsSinceEpoch,
        content: _currentText,
        codeType: _selectedCodeType,
        createdAt: DateTime.now(),
        // 不设置label字段，让历史记录屏幕默认显示content字段
      );
      
      await SimpleHistoryService.addHistoryRecord(record);
      debugPrint('历史记录保存成功');
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentText.isEmpty) return;

    try {
      if (_isFavorite) {
        final records = await FavoriteService.getAllFavoriteRecords();
        final targetRecord = records.firstWhere(
          (record) => record.content == _currentText && record.codeType == _selectedCodeType,
          orElse: () => throw Exception('未找到收藏记录'),
        );
        
        await FavoriteService.deleteFavoriteRecord(targetRecord.id);
        
        setState(() {
          _isFavorite = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消收藏'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final record = FavoriteRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          content: _currentText,
          codeType: _selectedCodeType,
          createdAt: DateTime.now(),
        );
        
        await FavoriteService.addFavoriteRecord(record);
        
        setState(() {
          _isFavorite = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已添加到收藏'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareCode() async {
    try {
      // 暂时移除截图功能，直接分享文本
      await Share.share(_currentText, subject: '马上码生成');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      if (kIsWeb) {
        // Web平台：显示提示，告知用户手动截图
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请使用浏览器截图功能保存')),
          );
        }
      } else {
        // 非Web平台：直接分享文本
        await Share.share(_currentText, subject: '马上码生成');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Widget _buildFavoriteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _toggleFavorite,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey[600],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _shareCode,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.share,
              color: Colors.blue,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _saveToGallery,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.download,
              color: Colors.green,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeDisplay() {
    if (_currentText.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                '输入内容后将自动生成编码',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 编码显示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CodeGenerator().generateCodeWidget(
              _currentText,
              type: _selectedCodeType,
              size: 300,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 内容信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_selectedCodeType.displayName} • ${_currentText.length} 字符',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // 操作按钮
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildShareButton(),
              const SizedBox(width: 8),
              _buildExportButton(),
              const SizedBox(width: 8),
              _buildFavoriteButton(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('马上码'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // 刷新剪贴板按钮 - 增加背景色和内边距使其更突出
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _loadClipboardContent,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('刷新', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
          // Show menu按钮 - 使用更清晰的图标并增加大小
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              iconSize: 28,
              onSelected: (value) {
                switch (value) {
                  case 'history':
                    Navigator.pushNamed(context, '/history');
                    break;
                  case 'favorite':
                    Navigator.pushNamed(context, '/favorite');
                    break;
                  case 'menu':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MenuScreen()),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'home',
                  child: Row(
                    children: [
                      Icon(Icons.home),
                      SizedBox(width: 8),
                      Text('主页'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('历史记录'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(Icons.favorite),
                      SizedBox(width: 8),
                      Text('我的收藏'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'menu',
                  child: Row(
                    children: [
                      Icon(Icons.menu),
                      SizedBox(width: 8),
                      Text('更多功能'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 编码显示区域
            _buildCodeDisplay(),
            
            const SizedBox(height: 16),
            
            // 输入区域
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '内容输入',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: '请输入要生成编码的内容...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  
                  // 编码类型选择
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '编码类型',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: CodeType.values.map((type) {
                            final isSelected = _selectedCodeType == type;
                            return FilterChip(
                              label: Text(type.displayName),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCodeType = type;
                                  });
                                }
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Colors.blue[100],
                              checkmarkColor: Colors.blue[700],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('关于'),
              content: const Text('马上码1.1.0 - 轻量级编码生成工具\n快速将文本转换为各种编码格式\nBy:XieCHaoDai(xiechaodai@163.com)'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.info),
      ),
    );
  }
}

