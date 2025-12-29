import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class SensitiveFilter {
  static bool isSensitive(String content) {
    if (content.isEmpty) return false;

    for (final pattern in Constants.sensitivePatterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          return true;
        }
      } catch (e) {
        debugPrint('SensitiveFilter regex error: $e, pattern: $pattern');
      }
    }

    return false;
  }

  static String maskSensitiveContent(String content) {
    if (content.isEmpty) return content;

    String masked = content;

    // 银行卡号脱敏
    masked = masked.replaceAllMapped(
      RegExp(r'\b(\d{4})\d{8,12}(\d{4})\b'),
      (match) => '${match.group(1)}****${match.group(2)}',
    );

    // 身份证号脱敏
    masked = masked.replaceAllMapped(
      RegExp(r'\b(\d{6})\d{8}(\d{4})\b'),
      (match) => '${match.group(1)}********${match.group(2)}',
    );

    // 手机号脱敏
    masked = masked.replaceAllMapped(
      RegExp(r'\b(1[3-9]\d{1})\d{4}(\d{4})\b'),
      (match) => '${match.group(1)}****${match.group(2)}',
    );

    // 邮箱脱敏
    masked = masked.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._%+-]{2})[a-zA-Z0-9._%+-]+@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      (match) => '${match.group(1)}****@${match.group(2)}',
    );

    return masked;
  }

  static List<String> getSensitivePatterns() {
    return Constants.sensitivePatterns;
  }

  static bool isPassword(String content) {
    return RegExp(r'password[=:]\s*\S+', caseSensitive: false).hasMatch(content) ||
           RegExp(r'passwd[=:]\s*\S+', caseSensitive: false).hasMatch(content);
  }

  static bool isApiKey(String content) {
    return RegExp(r'api[_-]?key[=:]\s*\S+', caseSensitive: false).hasMatch(content) ||
           RegExp(r'apikey[=:]\s*\S+', caseSensitive: false).hasMatch(content);
  }

  static bool isToken(String content) {
    return RegExp(r'token[=:]\s*\S+', caseSensitive: false).hasMatch(content) ||
           RegExp(r'jwt[=:]\s*\S+', caseSensitive: false).hasMatch(content);
  }

  static bool isSecret(String content) {
    return RegExp(r'secret[=:]\s*\S+', caseSensitive: false).hasMatch(content) ||
           RegExp(r'private[_-]?key[=:]\s*\S+', caseSensitive: false).hasMatch(content);
  }

  static bool isBankCard(String content) {
    return RegExp(r'\b\d{16,19}\b').hasMatch(content);
  }

  static bool isIdCard(String content) {
    return RegExp(r'\b\d{18}\b').hasMatch(content) ||
           RegExp(r'\b\d{17}[Xx]\b').hasMatch(content);
  }

  static bool isPhoneNumber(String content) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(content) ||
           RegExp(r'\b1[3-9]\d{9}\b').hasMatch(content);
  }

  static bool isEmail(String content) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(content);
  }
}