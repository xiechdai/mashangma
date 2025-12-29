class Constants {
  // 数据库相关
  static const String databaseName = 'instant_code.db';
  static const int databaseVersion = 1;
  static const String clipboardTable = 'clipboard_history';
  static const String encodeTable = 'encode_history';

  // 设置相关
  static const String clipboardListeningKey = 'clipboard_listening';
  static const String sensitiveFilterKey = 'sensitive_filter';
  static const String clipboardRecordLimitKey = 'clipboard_record_limit';
  static const String autoSaveEncodeHistoryKey = 'auto_save_encode_history';
  static const String encodeRecordLimitKey = 'encode_record_limit';
  static const String smartBrightnessKey = 'smart_brightness';
  static const String defaultCodeTypeKey = 'default_code_type';
  static const String codeResolutionKey = 'code_resolution';
  static const String themeModeKey = 'theme_mode';

  // 默认值
  static const bool defaultClipboardListening = true;
  static const bool defaultSensitiveFilter = false;
  static const int defaultClipboardRecordLimit = 200;
  static const bool defaultAutoSaveEncodeHistory = true;
  static const int defaultEncodeRecordLimit = 100;
  static const bool defaultSmartBrightness = true;
  static const String defaultCodeType = 'QR Code';
  static const String defaultCodeResolution = 'medium';
  static const String defaultThemeMode = 'system';

  // 记录限制选项
  static const List<int> clipboardRecordLimits = [100, 200, 500];
  static const List<int> encodeRecordLimits = [50, 100, 200];

  // 码图分辨率选项
  static const List<String> codeResolutions = ['low', 'medium', 'high'];
  static const Map<String, double> codeResolutionValues = {
    'low': 200.0,
    'medium': 300.0,
    'high': 400.0,
  };

  // 主题模式选项
  static const List<String> themeModes = ['light', 'dark', 'system'];

  // 敏感词过滤规则
  static const List<String> sensitivePatterns = [
    r'\b\d{16,19}\b', // 银行卡号
    r'\b\d{18}\b', // 身份证号
    r'\b\d{6}\s?\d{4,6}\s?\d{4,6}\b', // 手机号
    r'password[=:]\s*\S+', // 密码
    r'token[=:]\s*\S+', // 令牌
    r'api[_-]?key[=:]\s*\S+', // API密钥
    r'secret[=:]\s*\S+', // 密钥
  ];

  // 内容类型
  static const String contentTypeText = 'text';
  static const String contentTypeUrl = 'url';
  static const String contentTypeNumber = 'number';
  static const String contentTypeEmail = 'email';
  static const String contentTypePhone = 'phone';

  // 错误消息
  static const String clipboardPermissionDenied = '剪贴板权限被拒绝，请在设置中开启权限';
  static const String cameraPermissionDenied = '相机权限被拒绝，请在设置中开启权限';
  static const String storagePermissionDenied = '存储权限被拒绝，请在设置中开启权限';
  static const String contentTooLong = '内容过长，无法生成编码';
  static const String invalidCodeType = '不支持的编码类型';
  static const String networkError = '网络连接失败';
  static const String unknownError = '未知错误';

  // 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // 布局常量
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 12.0;

  // 颜色常量
  static const int primaryColorValue = 0xFF2196F3;
  static const int primaryDarkColorValue = 0xFF1976D2;
  static const int accentColorValue = 0xFF4CAF50;
  static const int errorColorValue = 0xFFF44336;
  static const int warningColorValue = 0xFFFF9800;

  // 字符串长度限制
  static const int maxQRCodeLength = 2953; // QR码最大容量
  static const int maxBarcodeLength = 48; // 条形码最大长度
  static const int maxTextInputLength = 1000; // 文本输入最大长度

  // 文件路径
  static const String assetsImagesPath = 'assets/images/';
  static const String assetsIconsPath = 'assets/icons/';

  // 应用信息
  static const String appName = '马上码';
  static const String appVersion = '1.0.0';
  static const String appDescription = '轻量级工具应用，快速将剪贴板内容转换为各类编码格式';

  // 分享相关
  static const String shareSubject = '马上码分享';
  static const String shareTextTemplate = '使用"马上码"生成的内容：{}';

  // 默认内容
  static String getCurrentDateTimeString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}