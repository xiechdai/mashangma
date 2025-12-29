import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/favorite_record.dart';
import '../widgets/code_generator.dart';
import '../services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<FavoriteRecord> _favoriteRecords = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadFavoriteRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadFavoriteRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await FavoriteService.getAllFavoriteRecords();
      final categories = await FavoriteService.getAllCategories();

      setState(() {
        _favoriteRecords = records;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载收藏记录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFavoriteRecord(int id) async {
    try {
      final result = await FavoriteService.deleteFavoriteRecord(id);
      if (result > 0) {
        setState(() {
          _favoriteRecords.removeWhere((record) => record.id == id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('取消收藏成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消收藏失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要清空所有收藏吗？此操作不可撤销。'),
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
        final result = await FavoriteService.clearAllFavoriteRecords();
        if (result >= 0) {
          setState(() {
            _favoriteRecords.clear();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('收藏已清空'),
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

  void _useFavoriteRecord(FavoriteRecord record) {
    Navigator.pop(context, {
      'content': record.content,
      'codeType': record.codeType,
    });
  }

  Future<void> _showEditDialog(FavoriteRecord record) async {
    final labelController = TextEditingController(text: record.label);
    final categoryController = TextEditingController(text: record.category);

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑收藏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '为收藏添加一个标签',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '分类',
                hintText: '选择或输入分类',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'label': labelController.text.isEmpty ? null : labelController.text,
                'category': categoryController.text.isEmpty ? null : categoryController.text,
              });
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedRecord = record.copyWith(
        label: result['label'],
        category: result['category'],
      );
      
      await FavoriteService.updateFavoriteRecord(updatedRecord);
      _loadFavoriteRecords(); // 重新加载列表
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_favoriteRecords.isNotEmpty)
            IconButton(
              onPressed: _clearAllFavorites,
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空收藏',
            ),
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
                    hintText: '搜索收藏记录...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _loadFavoriteRecords();
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
                    _loadFavoriteRecords();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // 分类筛选
                if (_categories.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('全部'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? null : _selectedCategory;
                            });
                            _loadFavoriteRecords();
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : _selectedCategory;
                                });
                                _loadFavoriteRecords();
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 收藏记录列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoriteList(),
          ),
        ],
      ),
    );
  }

  List<FavoriteRecord> get _filteredFavorites {
    var records = _favoriteRecords;
    
    // 应用分类筛选
    if (_selectedCategory != null) {
      records = records.where((r) => r.category == _selectedCategory).toList();
    }
    
    // 应用搜索筛选
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      records = records.where((record) {
        final contentMatch = record.content.toLowerCase().contains(query);
        final labelMatch = record.label?.toLowerCase().contains(query) ?? false;
        final categoryMatch = record.category?.toLowerCase().contains(query) ?? false;
        return contentMatch || labelMatch || categoryMatch;
      }).toList();
    }
    
    return records;
  }

  Widget _buildEmptyState() {
    final hasFilter = _searchQuery.isNotEmpty || _selectedCategory != null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? '没有找到匹配的收藏' : '暂无收藏',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter ? '尝试调整搜索条件或筛选器' : '点击爱心按钮收藏常用内容',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteList() {
    return ListView.builder(
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        final record = _filteredFavorites[index];
        return _buildFavoriteItem(record);
      },
    );
  }

  Widget _buildFavoriteItem(FavoriteRecord record) {
    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showEditDialog(record),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (context) => _deleteFavoriteRecord(record.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: CodeGenerator(
              data: record.content,
              codeType: CodeGenerator.fromCodeType(record.codeType),
              size: 32,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.red,
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
              if (record.category != null) ...[
                Text(
                  record.category!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                record.codeType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red[400],
                size: 20,
              ),
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
          onTap: () => _useFavoriteRecord(record),
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
}