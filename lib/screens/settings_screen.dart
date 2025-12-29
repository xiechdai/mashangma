import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  late SharedPreferences _prefs;

  // 设置状态
  bool _clipboardListening = Constants.defaultClipboardListening;
  bool _sensitiveFilter = Constants.defaultSensitiveFilter;
  int _clipboardRecordLimit = Constants.defaultClipboardRecordLimit;
  bool _autoSaveEncodeHistory = Constants.defaultAutoSaveEncodeHistory;
  int _encodeRecordLimit = Constants.defaultEncodeRecordLimit;
  bool _smartBrightness = Constants.defaultSmartBrightness;
  String _defaultCodeType = Constants.defaultCodeType;
  String _codeResolution = Constants.defaultCodeResolution;
  String _themeMode = Constants.defaultThemeMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _clipboardListening = _prefs.getBool(Constants.clipboardListeningKey) ?? 
                             Constants.defaultClipboardListening;
        _sensitiveFilter = _prefs.getBool(Constants.sensitiveFilterKey) ?? 
                          Constants.defaultSensitiveFilter;
        _clipboardRecordLimit = _prefs.getInt(Constants.clipboardRecordLimitKey) ?? 
                               Constants.defaultClipboardRecordLimit;
        _autoSaveEncodeHistory = _prefs.getBool(Constants.autoSaveEncodeHistoryKey) ?? 
                                Constants.defaultAutoSaveEncodeHistory;
        _encodeRecordLimit = _prefs.getInt(Constants.encodeRecordLimitKey) ?? 
                             Constants.defaultEncodeRecordLimit;
        _smartBrightness = _prefs.getBool(Constants.smartBrightnessKey) ?? 
                          Constants.defaultSmartBrightness;
        _defaultCodeType = _prefs.getString(Constants.defaultCodeTypeKey) ?? 
                           Constants.defaultCodeType;
        _codeResolution = _prefs.getString(Constants.codeResolutionKey) ?? 
                         Constants.defaultCodeResolution;
        _themeMode = _prefs.getString(Constants.themeModeKey) ?? 
                      Constants.defaultThemeMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prefs.setBool(Constants.clipboardListeningKey, _clipboardListening);
      await _prefs.setBool(Constants.sensitiveFilterKey, _sensitiveFilter);
      await _prefs.setInt(Constants.clipboardRecordLimitKey, _clipboardRecordLimit);
      await _prefs.setBool(Constants.autoSaveEncodeHistoryKey, _autoSaveEncodeHistory);
      await _prefs.setInt(Constants.encodeRecordLimitKey, _encodeRecordLimit);
      await _prefs.setBool(Constants.smartBrightnessKey, _smartBrightness);
      await _prefs.setString(Constants.defaultCodeTypeKey, _defaultCodeType);
      await _prefs.setString(Constants.codeResolutionKey, _codeResolution);
      await _prefs.setString(Constants.themeModeKey, _themeMode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存设置失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection('剪贴板设置'),
                _buildSwitchSetting(
                  '剪贴板监听',
                  '自动监听剪贴板变化',
                  _clipboardListening,
                  (value) => setState(() => _clipboardListening = value),
                ),
                _buildSwitchSetting(
                  '敏感词过滤',
                  '过滤密码、银行卡号等敏感内容',
                  _sensitiveFilter,
                  (value) => setState(() => _sensitiveFilter = value),
                ),
                _buildChoiceSetting(
                  '剪贴板记录上限',
                  _clipboardRecordLimit.toString(),
                  Constants.clipboardRecordLimits.map((e) => e.toString()).toList(),
                  (value) => setState(() => _clipboardRecordLimit = int.parse(value)),
                ),

                _buildSection('编码历史'),
                _buildSwitchSetting(
                  '自动保存编码历史',
                  '生成编码时自动保存到历史',
                  _autoSaveEncodeHistory,
                  (value) => setState(() => _autoSaveEncodeHistory = value),
                ),
                _buildChoiceSetting(
                  '编码历史记录上限',
                  _encodeRecordLimit.toString(),
                  Constants.encodeRecordLimits.map((e) => e.toString()).toList(),
                  (value) => setState(() => _encodeRecordLimit = int.parse(value)),
                ),

                _buildSection('显示设置'),
                _buildChoiceSetting(
                  '默认编码类型',
                  _defaultCodeType,
                  ['QR Code', 'Code 128', 'EAN-13', 'EAN-8', 'UPC-A', 'Code 39', 'Code 93', 'ITF-14', 'Codabar', 'Data Matrix', 'PDF417', 'Aztec Code'],
                  (value) => setState(() => _defaultCodeType = value),
                ),
                _buildChoiceSetting(
                  '码图分辨率',
                  _codeResolution,
                  ['low', 'medium', 'high'],
                  (value) => setState(() => _codeResolution = value),
                ),
                _buildChoiceSetting(
                  '主题模式',
                  _themeMode,
                  Constants.themeModes,
                  (value) => setState(() => _themeMode = value),
                ),

                _buildSection('系统设置'),
                _buildSwitchSetting(
                  '智能亮度调节',
                  '根据环境光自动调节屏幕亮度',
                  _smartBrightness,
                  (value) => setState(() => _smartBrightness = value),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildChoiceSetting(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showChoiceDialog(title, value, options, onChanged),
    );
  }

  void _showChoiceDialog(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final isSelected = option == currentValue;
              return RadioListTile<String>(
                title: Text(_getOptionDisplayName(option)),
                value: option,
                groupValue: currentValue,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                    Navigator.of(context).pop();
                  }
                },
                selected: isSelected,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  String _getOptionDisplayName(String option) {
    switch (option) {
      case 'low':
        return '低';
      case 'medium':
        return '中';
      case 'high':
        return '高';
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      case 'system':
        return '跟随系统';
      default:
        return option;
    }
  }
}