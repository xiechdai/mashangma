import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/code_type.dart';

enum WidgetCodeType {
  qrCode('QR_CODE', '二维码'),
  code128('CODE_128', 'Code 128 条形码'),
  code39('CODE_39', 'Code 39 条形码'),
  ean13('EAN_13', 'EAN-13 条形码'),
  ean8('EAN_8', 'EAN-8 条形码'),
  upcA('UPC_A', 'UPC-A 条形码'),
  itf14('ITF_14', 'ITF-14 条形码'),
  dataMatrix('DATA_MATRIX', 'Data Matrix'),
  pdf417('PDF_417', 'PDF 417');

  const WidgetCodeType(this.value, this.displayName);
  
  final String value;
  final String displayName;
}

class CodeGenerator extends StatelessWidget {
  final String data;
  final WidgetCodeType codeType;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const CodeGenerator({
    super.key,
    required this.data,
    this.codeType = WidgetCodeType.qrCode,
    this.size = 200.0,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
  });

  // 从 models 中的 CodeType 转换为 WidgetCodeType
  static WidgetCodeType fromCodeType(CodeType codeType) {
    switch (codeType) {
      case CodeType.qrCode:
        return WidgetCodeType.qrCode;
      case CodeType.code128:
        return WidgetCodeType.code128;
      case CodeType.code39:
        return WidgetCodeType.code39;
      case CodeType.ean13:
        return WidgetCodeType.ean13;
      case CodeType.ean8:
        return WidgetCodeType.ean8;
      case CodeType.upcA:
        return WidgetCodeType.upcA;
      case CodeType.itf14:
        return WidgetCodeType.itf14;
      case CodeType.dataMatrix:
        return WidgetCodeType.dataMatrix;
      case CodeType.pdf417:
        return WidgetCodeType.pdf417;
      default:
        return WidgetCodeType.qrCode;
    }
  }

  // 生成代码widget
  Widget generateCodeWidget() {
    return _buildCode();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildCode(),
    );
  }

  Widget _buildCode() {
    switch (codeType) {
      case WidgetCodeType.qrCode:
        return QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );
      
      case WidgetCodeType.code128:
        return BarcodeWidget(
          barcode: Barcode.code128(),
          data: data,
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.code39:
        return BarcodeWidget(
          barcode: Barcode.code39(),
          data: data,
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.ean13:
        return BarcodeWidget(
          barcode: Barcode.ean13(),
          data: data.padLeft(13, '0').substring(0, 13), // EAN-13需要13位数字
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.ean8:
        return BarcodeWidget(
          barcode: Barcode.ean8(),
          data: data.padLeft(8, '0').substring(0, 8), // EAN-8需要8位数字
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.upcA:
        return BarcodeWidget(
          barcode: Barcode.upcA(),
          data: data.padLeft(12, '0').substring(0, 12), // UPC-A需要12位数字
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.itf14:
        return BarcodeWidget(
          barcode: Barcode.itf14(),
          data: data.padLeft(14, '0').substring(0, 14), // ITF-14需要14位数字
          width: size,
          height: size * 0.4,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.dataMatrix:
        return BarcodeWidget(
          barcode: Barcode.dataMatrix(),
          data: data,
          width: size,
          height: size,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
      
      case WidgetCodeType.pdf417:
        return BarcodeWidget(
          barcode: Barcode.pdf417(),
          data: data,
          width: size,
          height: size * 0.3,
          color: foregroundColor,
          backgroundColor: backgroundColor,
        );
    }
  }

  static bool isValidForBarcode(String data, WidgetCodeType type) {
    if (data.isEmpty) return false;
    
    switch (type) {
      case WidgetCodeType.ean13:
      case WidgetCodeType.upcA:
        return RegExp(r'^\d+$').hasMatch(data);
      case WidgetCodeType.ean8:
        return RegExp(r'^\d+$').hasMatch(data);
      case WidgetCodeType.itf14:
        return RegExp(r'^\d+$').hasMatch(data) && data.length <= 14;
      case WidgetCodeType.code128:
      case WidgetCodeType.code39:
      case WidgetCodeType.qrCode:
      case WidgetCodeType.dataMatrix:
      case WidgetCodeType.pdf417:
        return true; // 这些类型支持大多数字符
    }
  }
}