import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../models/clipboard_record.dart';
import '../utils/constants.dart';

class ClipboardHistoryScreen extends StatefulWidget {
  const ClipboardHistoryScreen({super.key});

  @override
  State<ClipboardHistoryScreen> createState() => _ClipboardHistoryScreenState();
}

class _ClipboardHistoryScreenState extends State<ClipboardHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClipboardRecord> _records = [];
  List<ClipboardRecord> _filteredRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await ClipboardService.instance.getHistory(limit: 200);
      setState(() {
        _records = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRecords(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((record) {
          return record.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteRecord(int id) async {
    try {
      await ClipboardService.instance.deleteHistoryRecord(id);
      await _loadRecords();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('记录已删除'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有剪贴板记录吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ClipboardService.instance.clearHistory();
        await _loadRecords();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所有记录已清空'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('清空失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectContent(String content) {
    Navigator.pop(context, content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('剪贴板历史'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              onPressed: _clearAllRecords,
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空全部',
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBox(),
          
          // 记录列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.all(Constants.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索剪贴板内容...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterRecords('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.borderRadius),
          ),
        ),
        onChanged: _filterRecords,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无剪贴板记录' : '未找到匹配的记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.paste),
              label: const Text('复制内容'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Constants.defaultPadding),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return _buildRecordItem(record, index);
      },
    );
  }

  Widget _buildRecordItem(ClipboardRecord record, int index) {
    final displayContent = record.content.length > 50
        ? '${record.content.substring(0, 50)}...'
        : record.content;
    
    final time = DateTime.fromMillisecondsSinceEpoch(record.copiedAt);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final dateString = '${time.month}/${time.day}';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Constants.defaultPadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Constants.borderRadius),
          onTap: () => _selectContent(record.content),
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getContentIcon(record.contentType),
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayContent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getContentTypeName(record.contentType),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$dateString $timeString',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 操作按钮
                IconButton(
                  onPressed: () => _deleteRecord(record.id!),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: '删除',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getContentIcon(String contentType) {
    switch (contentType) {
      case Constants.contentTypeUrl:
        return Icons.link;
      case Constants.contentTypeEmail:
        return Icons.email;
      case Constants.contentTypePhone:
        return Icons.phone;
      case Constants.contentTypeNumber:
        return Icons.tag;
      default:
        return Icons.text_fields;
    }
  }

  String _getContentTypeName(String contentType) {
    switch (contentType) {
      case Constants.contentTypeUrl:
        return '链接';
      case Constants.contentTypeEmail:
        return '邮箱';
      case Constants.contentTypePhone:
        return '电话';
      case Constants.contentTypeNumber:
        return '数字';
      default:
        return '文本';
    }
  }
}