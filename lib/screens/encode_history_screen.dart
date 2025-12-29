import 'package:flutter/material.dart';
import '../services/code_generator.dart';
import '../models/encode_record.dart';
import '../models/code_type.dart';
import '../utils/constants.dart';

class EncodeHistoryScreen extends StatefulWidget {
  const EncodeHistoryScreen({super.key});

  @override
  State<EncodeHistoryScreen> createState() => _EncodeHistoryScreenState();
}

class _EncodeHistoryScreenState extends State<EncodeHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EncodeRecord> _records = [];
  List<EncodeRecord> _filteredRecords = [];
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
      final records = await CodeGenerator.instance.getHistory(limit: 100);
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
          return record.content.toLowerCase().contains(query.toLowerCase()) ||
                 record.codeType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteRecord(int id) async {
    try {
      await CodeGenerator.instance.deleteHistoryRecord(id);
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
          content: const Text('确定要清空所有编码历史吗？此操作不可撤销。'),
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
        await CodeGenerator.instance.clearHistory();
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

  void _showRecordDetail(EncodeRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Row(
                  children: [
                    Text(
                      '编码详情',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 编码显示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: CodeGenerator.instance.generateCodeWidget(
                    record.content,
                    type: CodeType.fromString(record.codeType),
                    size: 200,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 内容信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('编码类型', record.codeType),
                      const SizedBox(height: 8),
                      _buildInfoRow('内容长度', '${record.content.length} 个字符'),
                      const SizedBox(height: 8),
                      _buildInfoRow('生成时间', _formatDateTime(record.createdAt)),
                      const SizedBox(height: 8),
                      _buildInfoRow('内容预览', 
                          record.content.length > 100 
                              ? '${record.content.substring(0, 100)}...'
                              : record.content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编码历史'),
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
          hintText: '搜索编码内容或类型...',
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
            Icons.history_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无编码历史' : '未找到匹配的记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
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

  Widget _buildRecordItem(EncodeRecord record, int index) {
    final displayContent = record.content.length > 30
        ? '${record.content.substring(0, 30)}...'
        : record.content;
    
    final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
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
          onTap: () => _showRecordDetail(record),
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Row(
              children: [
                // 小图标预览
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Icon(
                      _getCodeTypeIcon(record.codeType),
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 内容信息
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.codeType,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
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

  IconData _getCodeTypeIcon(String codeType) {
    switch (codeType) {
      case 'QR Code':
        return Icons.qr_code_2;
      case 'Code 128':
      case 'Code 39':
      case 'Code 93':
        return Icons.view_week;
      case 'EAN-13':
      case 'EAN-8':
      case 'UPC-A':
      case 'ITF-14':
        return Icons.inventory_2;
      case 'Codabar':
        return Icons.inventory;
      case 'Data Matrix':
      case 'PDF417':
      case 'Aztec Code':
        return Icons.grid_view;
      default:
        return Icons.qr_code_2;
    }
  }
}