import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../utils/constants.dart';

class PermissionUtils {
  static Future<bool> requestClipboardPermission() async {
    try {
      // Android不需要剪贴板权限，iOS 14+需要
      if (Platform.isIOS) {
        // iOS剪贴板权限在使用时自动请求，这里返回true
        return true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    try {
      // Android 13+使用新的照片选择器API
      if (Platform.isAndroid) {
        // 检查Android版本
        // 这里简化处理，实际应该检查SDK版本
        return await permission_handler.Permission.photos.request().isGranted ||
               await permission_handler.Permission.storage.request().isGranted;
      } else {
        // iOS需要照片库权限
        return await permission_handler.Permission.photos.request().isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      return await permission_handler.Permission.camera.request().isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasClipboardPermission() async {
    try {
      // 剪贴板权限通常在需要时请求
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasStoragePermission() async {
    try {
      final photosStatus = await permission_handler.Permission.photos.status;
      final storageStatus = await permission_handler.Permission.storage.status;
      
      return photosStatus.isGranted || storageStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasCameraPermission() async {
    try {
      return await permission_handler.Permission.camera.status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      // 直接使用permission_handler包的openAppSettings函数
      await permission_handler.openAppSettings();
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
    }
  }

  static Future<bool> shouldShowPermissionRationale(permission_handler.Permission permission) async {
    try {
      return await permission.shouldShowRequestRationale;
    } catch (e) {
      return false;
    }
  }

  static String getPermissionDeniedMessage(permission_handler.Permission permission) {
    switch (permission) {
      // 移除不存在的clipboard权限枚举
      // case Permission.clipboard:
      //   return Constants.clipboardPermissionDenied;
      case permission_handler.Permission.camera:
        return Constants.cameraPermissionDenied;
      case permission_handler.Permission.photos:
      case permission_handler.Permission.storage:
        return Constants.storagePermissionDenied;
      default:
        return '权限被拒绝，请在设置中开启相关权限';
    }
  }

  static Future<bool> isFirstTimeRequestPermission(String permissionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'first_time_${permissionKey}_permission';
      return prefs.getBool(key) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> markPermissionRequested(String permissionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'first_time_${permissionKey}_permission';
      await prefs.setBool(key, false);
    } catch (e) {
      debugPrint('Failed to mark permission as requested: $e');
    }
  }

  static Future<permission_handler.PermissionStatus> checkPermissionStatus(permission_handler.Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      return permission_handler.PermissionStatus.denied;
    }
  }

  static Future<Map<permission_handler.Permission, bool>> requestMultiplePermissions(
    List<permission_handler.Permission> permissions,
  ) async {
    try {
      final Map<permission_handler.Permission, bool> results = {};
      
      for (final permission in permissions) {
        results[permission] = await permission.request().isGranted;
      }
      
      return results;
    } catch (e) {
      return {};
    }
  }

  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onSettingsPressed,
    VoidCallback? onCancel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSettingsPressed();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                '此权限对于应用正常工作至关重要，请允许授权。',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('允许'),
            ),
          ],
        );
      },
    );
  }

  static void handlePermissionDenied(
    BuildContext context, {
    required permission_handler.Permission permission,
    VoidCallback? onRetry,
  }) {
    final message = getPermissionDeniedMessage(permission);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '去设置',
          onPressed: () {
            openAppSettings();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}