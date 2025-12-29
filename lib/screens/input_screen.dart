import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/code_generator.dart';
import '../models/code_type.dart';
import '../utils/constants.dart';
import '../widgets/code_type_selector.dart';
import '../widgets/code_display.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  CodeType _selectedType = CodeType.qrCode;
  String? _errorMessage;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedType = CodeGenerator.instance.currentType;
    
    // 自动聚焦到输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动输入'),
        actions: [
          TextButton(
            onPressed: _errorMessage == null && _textController.text.isNotEmpty
                ? _generateCode
                : null,
            child: const Text('生成'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 输入区域
          _buildInputSection(),
          
          // 编码类型选择器
          _buildTypeSelector(),
          
          // 错误信息
          if (_errorMessage != null) _buildErrorMessage(),
          
          // 编码预览
          if (_canShowPreview()) _buildPreviewSection(),
          
          // 底部操作区域
          if (_canShowPreview()) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.largeBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '输入内容',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '${_textController.text.length}/${Constants.maxTextInputLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _textController.text.length > Constants.maxTextInputLength * 0.9
                      ? Colors.red
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: Constants.smallPadding),
          
          // 输入框
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: 6,
            maxLength: Constants.maxTextInputLength,
            decoration: const InputDecoration(
              hintText: '请输入要生成编码的内容...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            onChanged: _onTextChanged,
            inputFormatters: [
              LengthLimitingTextInputFormatter(Constants.maxTextInputLength),
            ],
          ),
          
          // 快速操作按钮
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _pasteFromClipboard,
          icon: const Icon(Icons.paste, size: 16),
          label: const Text('粘贴'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _clearText,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('清空'),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _useDateTime,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('当前时间'),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
      child: CodeTypeSelector(
        selectedType: _selectedType,
        onTypeChanged: _onTypeChanged,
        showLabel: false,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(Constants.borderRadius),
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Expanded(
      child: CodeDisplay(
        content: _textController.text,
        codeType: _selectedType,
        showActions: false,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(Constants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('取消'),
            ),
          ),
          const SizedBox(width: Constants.smallPadding),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateCode,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isGenerating ? '生成中...' : '生成并保存'),
            ),
          ),
        ],
      ),
    );
  }

  void _onTextChanged(String text) {
    setState(() {
      _errorMessage = null;
    });
    
    // 实时验证
    if (text.isNotEmpty) {
      _validateContent(text);
    }
  }

  void _onTypeChanged(CodeType type) {
    setState(() {
      _selectedType = type;
    });
    
    // 重新验证内容
    if (_textController.text.isNotEmpty) {
      _validateContent(_textController.text);
    }
  }

  void _validateContent(String content) {
    final error = CodeGenerator.instance.getValidationError(content, _selectedType);
    setState(() {
      _errorMessage = error;
    });
  }

  bool _canShowPreview() {
    return _textController.text.isNotEmpty && 
           _errorMessage == null && 
           CodeGenerator.instance.isContentCompatible(_textController.text, _selectedType);
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null && clipboardData.text != null) {
        setState(() {
          _textController.text = clipboardData.text!;
        });
        _validateContent(_textController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('粘贴失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _errorMessage = null;
    });
  }

  void _useDateTime() {
    final dateTimeString = Constants.getCurrentDateTimeString();
    setState(() {
      _textController.text = dateTimeString;
    });
    _validateContent(dateTimeString);
  }

  Future<void> _generateCode() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入内容'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final record = await CodeGenerator.instance.generateAndSave(
        _textController.text.trim(),
        type: _selectedType,
      );

      if (record != null) {
        // 生成成功，返回主界面
        Navigator.pop(context, _textController.text.trim());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('编码生成成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('生成失败');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}