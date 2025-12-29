import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_record.dart';
import '../models/code_type.dart';
import '../widgets/code_generator.dart';
import '../services/simple_history_service.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryRecord> _historyRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  CodeType? _filterType;
  Set<int> _selectedRecords = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadHistoryRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadHistoryRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<HistoryRecord> records;
      
      if (_filterType != null) {
        records = await SimpleHistoryService.getHistoryRecordsByType(_filterType!);
      } else if (_searchQuery.isNotEmpty) {
        records = await SimpleHistoryService.searchHistoryRecords(_searchQuery);
      } else {
        records = await SimpleHistoryService.getAllHistoryRecords();
      }

      setState(() {
        _historyRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载历史记录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteHistoryRecord(int id) async {
    try {
      final result = await SimpleHistoryService.deleteHistoryRecord(id);
      if (result > 0) {
        setState(() {
          _historyRecords.removeWhere((record) => record.id == id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await SimpleHistoryService.clearAllHistoryRecords();
        if (result >= 0) {
          setState(() {
            _historyRecords.clear();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('历史记录已清空'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清空失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _useHistoryRecord(HistoryRecord record) {
    // 直接返回到主页面，传递选中的历史记录数据
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          initialContent: record.content,
          initialCodeType: record.codeType,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '已选择 ${_selectedRecords.length} 项' : '历史记录'),
        leading: _isSelectionMode
            ? IconButton(
                onPressed: _exitSelectionMode,
                icon: const Icon(Icons.close),
                tooltip: '取消选择',
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedRecords.isNotEmpty)
              IconButton(
                onPressed: _shareSelectedRecords,
                icon: const Icon(Icons.share),
                tooltip: '分享选中项',
              ),
            if (_selectedRecords.isNotEmpty)
              IconButton(
                onPressed: _deleteSelectedRecords,
                icon: const Icon(Icons.delete),
                tooltip: '删除选中项',
              ),
          ] else ...[
            if (_historyRecords.isNotEmpty)
              IconButton(
                onPressed: _enterSelectionMode,
                icon: const Icon(Icons.checklist),
                tooltip: '批量操作',
              ),
            if (_historyRecords.isNotEmpty)
              IconButton(
                onPressed: _clearAllHistory,
                icon: const Icon(Icons.delete_sweep),
                tooltip: '清空历史',
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索历史记录...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _loadHistoryRecords();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _loadHistoryRecords();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // 码类型筛选
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: _filterType == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? null : _filterType;
                          });
                          _loadHistoryRecords();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...CodeType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type.displayName),
                            selected: _filterType == type,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? type : null;
                              });
                              _loadHistoryRecords();
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 历史记录列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _searchQuery.isNotEmpty || _filterType != null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? '没有找到匹配的记录' : '暂无历史记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter ? '尝试调整搜索条件或筛选器' : '生成二维码后会自动保存到这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _historyRecords.length,
      itemBuilder: (context, index) {
        final record = _historyRecords[index];
        return _buildHistoryItem(record);
      },
    );
  }

  Widget _buildHistoryItem(HistoryRecord record) {
    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _deleteHistoryRecord(record.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: _selectedRecords.contains(record.id) 
            ? Colors.blue.withOpacity(0.1) 
            : null,
        child: ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: _selectedRecords.contains(record.id),
                  onChanged: (value) => _toggleRecordSelection(record.id),
                )
              : Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CodeGenerator(
                    data: record.content,
                    codeType: CodeGenerator.fromCodeType(record.codeType),
                    size: 32,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black87,
                  ),
                ),
          title: Text(
            record.label ?? record.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.codeType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(record.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.content.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '字符',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // 添加使用按钮
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _isSelectionMode ? _toggleRecordSelection(record.id) : _useHistoryRecord(record),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '使用',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          onTap: () => _isSelectionMode ? _toggleRecordSelection(record.id) : _useHistoryRecord(record),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return '${date.month}/${date.day}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 进入选择模式
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedRecords.clear();
    });
  }

  // 退出选择模式
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRecords.clear();
    });
  }

  // 切换记录选择状态
  void _toggleRecordSelection(int recordId) {
    setState(() {
      if (_selectedRecords.contains(recordId)) {
        _selectedRecords.remove(recordId);
      } else {
        _selectedRecords.add(recordId);
      }
    });
  }

  // 分享选中的记录
  Future<void> _shareSelectedRecords() async {
    if (_selectedRecords.isEmpty) return;

    final selectedRecords = _historyRecords
        .where((record) => _selectedRecords.contains(record.id))
        .toList();

    final content = selectedRecords
        .map((record) => '${record.codeType.displayName}: ${record.content}')
        .join('\n\n');

    try {
      await Share.share(
        content,
        subject: '马上码 - ${selectedRecords.length}条历史记录',
      );
      _exitSelectionMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 删除选中的记录
  Future<void> _deleteSelectedRecords() async {
    if (_selectedRecords.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除选中的 ${_selectedRecords.length} 条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        int deletedCount = 0;
        for (final recordId in _selectedRecords) {
          final result = await SimpleHistoryService.deleteHistoryRecord(recordId);
          if (result > 0) deletedCount++;
        }

        setState(() {
          _historyRecords.removeWhere((record) => _selectedRecords.contains(record.id));
          _selectedRecords.clear();
          _isSelectionMode = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除 $deletedCount 条记录'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}