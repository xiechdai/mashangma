// 简单的历史记录测试脚本
import 'dart:io';

void main() async {

  
  try {
    // 测试文件路径
    final currentDir = Directory.current.path;

    
    final libDir = '$currentDir/lib';

    
    final modelsDir = '$libDir/models';
    final servicesDir = '$libDir/services';
    final widgetsDir = '$libDir/widgets';
    
    
    
    final historyRecordFile = '$modelsDir/history_record.dart';
    final historyServiceFile = '$servicesDir/history_service.dart';
    final codeGeneratorFile = '$widgetsDir/code_generator.dart';
    
    
    
  } catch (e) {

  }
}