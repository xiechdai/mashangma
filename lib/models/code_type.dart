enum CodeType {
  qrCode('QR_CODE', 'QR Code', '二维码', '支持中文、URL、大容量文本'),
  code128('CODE_128', 'Code 128', 'Code 128', '通用商品码'),
  ean13('EAN_13', 'EAN-13', 'EAN-13', '国际商品条码'),
  ean8('EAN_8', 'EAN-8', 'EAN-8', '短商品条码'),
  upcA('UPC_A', 'UPC-A', 'UPC-A', '北美商品码'),
  code39('CODE_39', 'Code 39', 'Code 39', '工业码'),
  code93('CODE_93', 'Code 93', 'Code 93', '物流码'),
  itf14('ITF_14', 'ITF-14', 'ITF-14', '物流包装码'),
  codabar('CODABAR', 'Codabar', 'Codabar', '图书馆/血库'),
  dataMatrix('DATA_MATRIX', 'Data Matrix', 'Data Matrix', '小型高密度二维码'),
  pdf417('PDF_417', 'PDF417', 'PDF417', '证件/车票常用'),
  aztecCode('AZTEC_CODE', 'Aztec Code', 'Aztec Code', '交通票据');

  const CodeType(this.value, this.englishName, this.chineseName, this.description);

  final String value;
  final String englishName;
  final String chineseName;
  final String description;

  String get displayName => chineseName;
  String get fullName => englishName;

  static CodeType fromString(String value) {
    for (CodeType type in CodeType.values) {
      if (type.value == value || type.englishName == value || type.chineseName == value) {
        return type;
      }
    }
    return CodeType.qrCode; // 默认返回二维码
  }

  static List<CodeType> getAllTypes() => CodeType.values;

  static List<String> getDisplayNames() {
    return CodeType.values.map((type) => type.displayName).toList();
  }

  // 判断内容是否适合该编码类型
  bool isContentCompatible(String content) {
    switch (this) {
      case CodeType.ean13:
        // EAN-13必须是13位数字
        return RegExp(r'^\d{13}$').hasMatch(content);
      case CodeType.ean8:
        // EAN-8必须是8位数字
        return RegExp(r'^\d{8}$').hasMatch(content);
      case CodeType.upcA:
        // UPC-A必须是12位数字
        return RegExp(r'^\d{12}$').hasMatch(content);
      case CodeType.code39:
        // Code-39支持字母、数字、空格和部分特殊字符
        return RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content);
      case CodeType.code93:
        // Code-93支持字母、数字和部分特殊字符
        return RegExp(r'^[A-Z0-9\-\.\$\/\+\% ]+$', caseSensitive: false).hasMatch(content);
      case CodeType.codabar:
        // Codabar支持数字和有限特殊字符
        return RegExp(r'^[A-D0-9\-\$:/\.\+]+$').hasMatch(content);
      case CodeType.itf14:
        // ITF-14必须是14位数字
        return RegExp(r'^\d{14}$').hasMatch(content);
      case CodeType.code128:
        // Code-128支持所有ASCII字符
        return true;
      case CodeType.qrCode:
      case CodeType.dataMatrix:
      case CodeType.pdf417:
      case CodeType.aztecCode:
        // 二维码类型支持所有内容
        return true;
    }
  }

  // 智能识别内容最适合的编码类型
  static CodeType detectBestType(String content) {
    if (content.isEmpty) {
      return CodeType.qrCode;
    }

    // 检查是否为纯数字
    if (RegExp(r'^\d+$').hasMatch(content)) {
      int length = content.length;
      if (length == 13) return CodeType.ean13;
      if (length == 8) return CodeType.ean8;
      if (length == 12) return CodeType.upcA;
      if (length == 14) return CodeType.itf14;
      return CodeType.code128; // 其他长度的数字优先使用code128
    }

    // 检查是否为字母+数字或纯字母（优先使用code128）
    if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(content)) {
      return CodeType.code128;
    }

    // 检查是否为URL（确保真正的URL格式）
    if (RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])?$').hasMatch(content) || 
        RegExp(r'^www\.[\w\-]+(\.[\w\-]+)+([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])?$').hasMatch(content)) {
      return CodeType.qrCode;
    }

    // 检查是否包含中文
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(content)) {
      return CodeType.qrCode;
    }

    // 检查是否包含条形码不支持的特殊字符
    // Code128支持所有ASCII字符，所以这里主要检查是否适合其他条形码
    // 但根据需求，优先尝试code128，所以这里放宽检查
    if (RegExp(r'[^\x00-\x7F]').hasMatch(content)) {
      return CodeType.qrCode; // 非ASCII字符使用QR码
    }

    // 默认使用 code128 条形码
    return CodeType.code128;
  }
}