import 'package:flutter/material.dart';
import '../models/code_type.dart';
import '../services/code_generator.dart';
import '../utils/constants.dart';

class CodeTypeSelector extends StatefulWidget {
  final CodeType? selectedType;
  final ValueChanged<CodeType>? onTypeChanged;
  final bool showLabel;

  const CodeTypeSelector({
    super.key,
    this.selectedType,
    this.onTypeChanged,
    this.showLabel = true,
  });

  @override
  State<CodeTypeSelector> createState() => _CodeTypeSelectorState();
}

class _CodeTypeSelectorState extends State<CodeTypeSelector> {
  late CodeType _selectedType;
  late ScrollController _scrollController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType ?? CodeType.qrCode;
    _scrollController = ScrollController();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(CodeTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedType != null && widget.selectedType != _selectedType) {
      setState(() {
        _selectedType = widget.selectedType!;
      });
      _updateSelectedIndex();
      _scrollToSelected();
    }
  }

  void _updateSelectedIndex() {
    final types = CodeType.getAllTypes();
    _selectedIndex = types.indexOf(_selectedType);
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemWidth = 100.0; // 估算的item宽度
        final offset = _selectedIndex * itemWidth - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: Constants.shortAnimationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = CodeType.getAllTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '编码类型',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showTypeDialog,
                  child: const Text('查看详情'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Constants.smallPadding),
        ],
        
        // 横向滚动的类型选择器
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: Constants.smallPadding),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = type == _selectedType;
              
              return GestureDetector(
                onTap: () => _selectType(type),
                child: AnimatedContainer(
                  duration: Constants.shortAnimationDuration,
                  margin: const EdgeInsets.only(right: Constants.smallPadding),
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(Constants.borderRadius),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withAlpha((0.3 * 255).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.05 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 图标
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withAlpha((0.2 * 255).round()) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getTypeIcon(type),
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 18,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 名称
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // 选中类型的描述
        if (widget.showLabel) ...[
          const SizedBox(height: Constants.smallPadding),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(Constants.borderRadius),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedType.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _selectType(CodeType type) {
    setState(() {
      _selectedType = type;
      _selectedIndex = CodeType.getAllTypes().indexOf(type);
    });
    
    widget.onTypeChanged?.call(type);
    CodeGenerator.instance.setCurrentType(type);
    
    _scrollToSelected();
  }

  IconData _getTypeIcon(CodeType type) {
    switch (type) {
      case CodeType.qrCode:
        return Icons.qr_code_2;
      case CodeType.code128:
      case CodeType.code39:
      case CodeType.code93:
        return Icons.view_week;
      case CodeType.ean13:
      case CodeType.ean8:
      case CodeType.upcA:
      case CodeType.itf14:
        return Icons.inventory_2;
      case CodeType.codabar:
        return Icons.inventory;
      case CodeType.dataMatrix:
      case CodeType.pdf417:
      case CodeType.aztecCode:
        return Icons.grid_view;
    }
  }

  void _showTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编码类型说明'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: CodeType.getAllTypes().length,
              itemBuilder: (context, index) {
                final type = CodeType.getAllTypes()[index];
                return ListTile(
                  leading: Icon(
                    _getTypeIcon(type),
                    color: type == _selectedType 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  trailing: type == _selectedType
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    _selectType(type);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}