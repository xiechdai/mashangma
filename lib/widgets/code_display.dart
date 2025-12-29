import 'package:flutter/material.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/code_generator.dart';
import '../services/clipboard_service.dart';
import '../models/code_type.dart';
import '../utils/permissions.dart';
import '../utils/constants.dart';

class CodeDisplay extends StatefulWidget {
  final String content;
  final CodeType? codeType;
  final VoidCallback? onTypeChanged;
  final VoidCallback? onEdit;
  final bool showActions;

  const CodeDisplay({
    super.key,
    required this.content,
    this.codeType,
    this.onTypeChanged,
    this.onEdit,
    this.showActions = true,
  });

  @override
  State<CodeDisplay> createState() => _CodeDisplayState();
}

class _CodeDisplayState extends State<CodeDisplay> {
  CodeType _currentType = CodeType.qrCode;
  bool _isSaving = false;
  bool _isSharing = false;
  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _currentType = widget.codeType ?? CodeType.qrCode;
  }

  @override
  void didUpdateWidget(CodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.codeType != null && widget.codeType != _currentType) {
      setState(() {
        _currentType = widget.codeType!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 编码显示区域
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(Constants.defaultPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.largeBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 顶部信息栏
                _buildInfoBar(),
                
                // 编码显示
                Expanded(
                  child: Center(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CodeGenerator.instance.generateCodeWidget(
                            widget.content,
                            type: _currentType,
                            size: 250,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 内容预览
                _buildContentPreview(),
              ],
            ),
          ),
        ),
        
        // 操作按钮区域
        if (widget.showActions) ...[
          const SizedBox(height: Constants.smallPadding),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            _currentType.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          if (widget.onEdit != null)
            IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑内容',
            ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    final displayContent = widget.content.length > 30
        ? '${widget.content.substring(0, 30)}...'
        : widget.content;

    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '原始内容',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayContent,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (widget.content.length > 30) ...[
                  const SizedBox(height: 8),
                  Text(
                    '共 ${widget.content.length} 个字符',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
      child: Row(
        children: [
          // 剪贴板按钮
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.paste_outlined),
              label: const Text('剪贴板'),
            ),
          ),
          const SizedBox(width: Constants.smallPadding),
          
          // 保存按钮
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToGallery,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_isSaving ? '保存中...' : '保存'),
            ),
          ),
          const SizedBox(width: Constants.smallPadding),
          
          // 分享按钮
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              label: Text(_isSharing ? '分享中...' : '分享'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    try {
      await ClipboardService.instance.copyToClipboard(widget.content);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已复制到剪贴板'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('复制失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    // 检查存储权限
    final hasPermission = await PermissionUtils.hasStoragePermission();
    if (!hasPermission) {
      final granted = await PermissionUtils.requestStoragePermission();
      if (!granted) {
        if (mounted) {
          PermissionUtils.handlePermissionDenied(
            context,
            permission: Permission.photos,
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: 'instant_code_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (result['isSuccess'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('保存成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('保存失败');
        }
      } else {
        throw Exception('生成图片失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _share() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        // 创建临时文件用于分享
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/instant_code_share.png');
        await tempFile.writeAsBytes(imageBytes);

        // 分享图片和文本内容
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: '使用"马上码"生成的内容：${widget.content}',
          subject: Constants.shareSubject,
        );

        // 清理临时文件
        await tempFile.delete();
      } else {
        // 如果截图失败，只分享文本
        await Share.share(
          Constants.shareTextTemplate.replaceAll('{}', widget.content),
          subject: Constants.shareSubject,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}