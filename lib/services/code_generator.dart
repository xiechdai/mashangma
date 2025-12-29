import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/code_type.dart';
import '../models/encode_record.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class CodeGenerator {
  static final CodeGenerator _instance = CodeGenerator._internal();
  factory CodeGenerator() => _instance;
  CodeGenerator._internal();

  static CodeGenerator get instance => _instance;

  CodeType _currentType = CodeType.qrCode;
  double _resolution = 300.0;

  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final typeString = prefs.getString(Constants.defaultCodeTypeKey) ?? 
                         Constants.defaultCodeType;
      _currentType = CodeType.fromString(typeString);
      
      final resolutionString = prefs.getString(Constants.codeResolutionKey) ?? 
                               Constants.defaultCodeResolution;
      _resolution = Constants.codeResolutionValues[resolutionString] ?? 
                    Constants.codeResolutionValues['medium']!;
    } catch (e) {
      // 加载设置失败
      debugPrint('CodeGenerator load settings error: $e');
    }
  }

  CodeType get currentType => _currentType;
  double get resolution => _resolution;

  Future<void> setCurrentType(CodeType type) async {
    _currentType = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.defaultCodeTypeKey, type.englishName);
    } catch (e) {
      // 保存设置失败
      debugPrint('CodeGenerator save current type error: $e');
    }
  }

  Future<void> setResolution(String resolutionString) async {
    _resolution = Constants.codeResolutionValues[resolutionString] ?? 
                   Constants.codeResolutionValues['medium']!;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.codeResolutionKey, resolutionString);
    } catch (e) {
      // 保存设置失败
      debugPrint('CodeGenerator save resolution error: $e');
    }
  }

  Widget generateCodeWidget(String content, {CodeType? type, double? size}) {
    final targetType = type ?? _currentType;
    final targetSize = size ?? _resolution;

    switch (targetType) {
      case CodeType.qrCode:
        return QrImageView(
          data: content,
          version: QrVersions.auto,
          size: targetSize,
          backgroundColor: Colors.white,
          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
          dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );
        
      case CodeType.code128:
        return BarcodeWidget(
          barcode: Barcode.code128(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.ean13:
        return BarcodeWidget(
          barcode: Barcode.ean13(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.ean8:
        return BarcodeWidget(
          barcode: Barcode.ean8(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.upcA:
        return BarcodeWidget(
          barcode: Barcode.upcA(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.code39:
        return BarcodeWidget(
          barcode: Barcode.code39(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.code93:
        return BarcodeWidget(
          barcode: Barcode.code93(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.itf14:
        return BarcodeWidget(
          barcode: Barcode.itf14(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.codabar:
        return BarcodeWidget(
          barcode: Barcode.codabar(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
          style: const TextStyle(fontSize: 12),
        );
        
      case CodeType.dataMatrix:
        return BarcodeWidget(
          barcode: Barcode.dataMatrix(),
          data: content,
          width: targetSize,
          height: targetSize,
        );
        
      case CodeType.pdf417:
        return BarcodeWidget(
          barcode: Barcode.pdf417(),
          data: content,
          width: targetSize,
          height: targetSize * 0.3,
        );
        
      case CodeType.aztecCode:
        return BarcodeWidget(
          barcode: Barcode.aztec(),
          data: content,
          width: targetSize,
          height: targetSize,
        );
    }
  }

  Future<Uint8List?> generateCodeImage(
    String content, {
    CodeType? type,
    double? size,
    EdgeInsets? padding,
  }) async {
    try {
      final targetType = type ?? _currentType;
      final targetSize = size ?? _resolution;
      final targetPadding = padding ?? const EdgeInsets.all(16);

      // 创建一个 GlobalKey 来捕获 Widget
      final GlobalKey globalKey = GlobalKey();

      // 创建一个离屏的 Widget 树
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              key: globalKey,
              padding: targetPadding,
              child: generateCodeWidget(content, type: targetType, size: targetSize),
            ),
          ),
        ),
      );

      // 等待 Widget 渲染完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 获取 RenderRepaintBoundary
      final RenderRepaintBoundary boundary = globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // 转换为图片
      final ui.Image image = await boundary.toImage();
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      // 生成图片失败
      debugPrint('CodeGenerator generate image error: $e');
    }

    return null;
  }

  Future<EncodeRecord?> generateAndSave(
    String content, {
    CodeType? type,
  }) async {
    try {
      final targetType = type ?? _currentType;
      
      // 验证内容长度
      if (!_validateContent(content, targetType)) {
        throw Exception('内容长度或格式不符合要求');
      }

      // 生成图片
      final imageData = await generateCodeImage(content, type: targetType);
      
      // 保存到数据库
      final record = EncodeRecord(
        content: content,
        codeType: targetType.englishName,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        thumbnail: imageData != null ? 'base64:${imageData.lengthInBytes}' : null,
      );

      final id = await DatabaseService.instance.insertEncodeRecord(record);
      
      // 限制历史记录数量
      final prefs = await SharedPreferences.getInstance();
      final limit = prefs.getInt(Constants.encodeRecordLimitKey) ?? 
                   Constants.defaultEncodeRecordLimit;
      await DatabaseService.instance.limitEncodeRecords(limit);

      return record.copyWith(id: id);
    } catch (e) {
      // 生成并保存编码失败
      debugPrint('CodeGenerator generate and save error: $e');
      return null;
    }
  }

  bool _validateContent(String content, CodeType type) {
    if (content.isEmpty) return false;

    switch (type) {
      case CodeType.qrCode:
        return content.length <= Constants.maxQRCodeLength;
        
      case CodeType.code128:
        return content.length <= Constants.maxBarcodeLength;
        
      case CodeType.ean13:
        return RegExp(r'^\d{13}$').hasMatch(content);
        
      case CodeType.ean8:
        return RegExp(r'^\d{8}$').hasMatch(content);
        
      case CodeType.upcA:
        return RegExp(r'^\d{12}$').hasMatch(content);
        
      case CodeType.code39:
        return RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content);
        
      case CodeType.code93:
        return RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content);
        
      case CodeType.codabar:
        return RegExp(r'^[A-D0-9\-\$:/\.\+]+$').hasMatch(content);
        
      case CodeType.itf14:
        return RegExp(r'^\d{14}$').hasMatch(content);
        
      case CodeType.dataMatrix:
      case CodeType.pdf417:
      case CodeType.aztecCode:
        return content.length <= 1000; // 2D码的合理长度限制
    }
  }

  String? getValidationError(String content, CodeType type) {
    if (content.isEmpty) return '内容不能为空';

    switch (type) {
      case CodeType.qrCode:
        if (content.length > Constants.maxQRCodeLength) {
          return '内容过长，二维码最大支持${Constants.maxQRCodeLength}个字符';
        }
        break;
        
      case CodeType.code128:
        if (content.length > Constants.maxBarcodeLength) {
          return '内容过长，条形码最大支持${Constants.maxBarcodeLength}个字符';
        }
        break;
        
      case CodeType.ean13:
        if (!RegExp(r'^\d{13}$').hasMatch(content)) {
          return 'EAN-13必须是13位数字';
        }
        break;
        
      case CodeType.ean8:
        if (!RegExp(r'^\d{8}$').hasMatch(content)) {
          return 'EAN-8必须是8位数字';
        }
        break;
        
      case CodeType.upcA:
        if (!RegExp(r'^\d{12}$').hasMatch(content)) {
          return 'UPC-A必须是12位数字';
        }
        break;
        
      case CodeType.code39:
        if (!RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content)) {
          return 'Code-39只支持字母、数字和特殊字符(-.\$/+%)';
        }
        break;
        
      case CodeType.code93:
        if (!RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content)) {
          return 'Code-93只支持字母、数字和特殊字符(-.\$/+%)';
        }
        break;
        
      case CodeType.codabar:
        if (!RegExp(r'^[A-D0-9\-\$:/\.\+]+$').hasMatch(content)) {
          return 'Codabar只支持数字和特殊字符(-\$:/\.\+)';
        }
        break;
        
      case CodeType.itf14:
        if (!RegExp(r'^\d{14}$').hasMatch(content)) {
          return 'ITF-14必须是14位数字';
        }
        break;
        
      case CodeType.dataMatrix:
      case CodeType.pdf417:
      case CodeType.aztecCode:
        if (content.length > 1000) {
          return '内容过长，建议不超过1000个字符';
        }
        break;
    }

    return null;
  }

  Future<List<EncodeRecord>> getHistory({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      return await DatabaseService.instance.getEncodeRecords(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      // 获取编码历史失败
      debugPrint('CodeGenerator get history error: $e');
      return [];
    }
  }

  Future<EncodeRecord?> getLatestHistory() async {
    try {
      return await DatabaseService.instance.getLatestEncodeRecord();
    } catch (e) {
      // 获取最新编码记录失败
      debugPrint('CodeGenerator get latest history error: $e');
      return null;
    }
  }

  Future<void> deleteHistoryRecord(int id) async {
    try {
      await DatabaseService.instance.deleteEncodeRecord(id);
    } catch (e) {
      // 删除编码记录失败
      debugPrint('CodeGenerator delete history record error: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await DatabaseService.instance.clearEncodeRecords();
    } catch (e) {
      // 清空编码历史失败
      debugPrint('CodeGenerator clear history error: $e');
    }
  }

  // 获取默认内容（当前日期时间）
  String getDefaultContent() {
    return Constants.getCurrentDateTimeString();
  }

  // 获取编码类型描述
  String getTypeDescription(CodeType type) {
    return type.description;
  }

  // 获取所有支持的编码类型
  List<CodeType> getSupportedTypes() {
    return CodeType.getAllTypes();
  }

  // 检查内容是否适合该编码类型
  bool isContentCompatible(String content, CodeType type) {
    return type.isContentCompatible(content);
  }

  // 智能识别最适合的编码类型
  CodeType detectBestType(String content) {
    return CodeType.detectBestType(content);
  }
}