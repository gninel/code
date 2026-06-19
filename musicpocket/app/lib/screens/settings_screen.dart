import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultFormat = 'mp3';
  String _defaultBitrate = '192k';
  bool _autoDetectClipboard = true;
  bool _autoDownload = true;
  String _serverUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultFormat = prefs.getString('default_format') ?? 'mp3';
      _defaultBitrate = prefs.getString('default_bitrate') ?? '192k';
      _autoDetectClipboard = prefs.getBool('auto_detect_clipboard') ?? true;
      _autoDownload = prefs.getBool('auto_download') ?? true;
      _serverUrl = prefs.getString('server_url') ?? 'http://localhost:8000';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('转换设置'),
          ListTile(
            title: const Text('默认音频格式'),
            subtitle: Text(_defaultFormat.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFormatPicker(),
          ),
          ListTile(
            title: const Text('默认音质'),
            subtitle: Text(_bitrateLabel(_defaultBitrate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBitratePicker(),
          ),
          const Divider(),

          _buildSectionHeader('自动化'),
          SwitchListTile(
            title: const Text('自动检测剪贴板'),
            subtitle: const Text('App 回到前台时检测是否有支持的链接'),
            value: _autoDetectClipboard,
            onChanged: (v) {
              setState(() => _autoDetectClipboard = v);
              _saveSetting('auto_detect_clipboard', v);
            },
          ),
          SwitchListTile(
            title: const Text('自动下载到本地'),
            subtitle: const Text('转换完成后自动下载音频文件'),
            value: _autoDownload,
            onChanged: (v) {
              setState(() => _autoDownload = v);
              _saveSetting('auto_download', v);
            },
          ),
          const Divider(),

          _buildSectionHeader('服务器'),
          ListTile(
            title: const Text('服务器地址'),
            subtitle: Text(_serverUrl),
            trailing: const Icon(Icons.edit),
            onTap: () => _showServerUrlDialog(),
          ),
          const Divider(),

          _buildSectionHeader('存储'),
          ListTile(
            title: const Text('清除所有缓存'),
            subtitle: const Text('删除临时文件，不影响已保存的音频'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _showClearCacheDialog(),
          ),
          ListTile(
            title: const Text('导出音频库'),
            subtitle: const Text('将所有音频文件导出到系统文件夹'),
            trailing: const Icon(Icons.folder_open),
            onTap: () {},
          ),
          const Divider(),

          _buildSectionHeader('关于'),
          const ListTile(
            title: Text('版本'),
            subtitle: Text('MusicPocket v1.0.0'),
          ),
          const ListTile(
            title: Text('开源协议'),
            subtitle: Text('MIT License'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  String _bitrateLabel(String bitrate) {
    switch (bitrate) {
      case '128k':
        return '128 kbps（标准）';
      case '192k':
        return '192 kbps（推荐）';
      case '320k':
        return '320 kbps（高音质）';
      default:
        return bitrate;
    }
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final fmt in ['mp3', 'm4a', 'aac', 'opus'])
              ListTile(
                title: Text(fmt.toUpperCase()),
                trailing: _defaultFormat == fmt ? const Icon(Icons.check, color: Colors.black) : null,
                onTap: () {
                  setState(() => _defaultFormat = fmt);
                  _saveSetting('default_format', fmt);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showBitratePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final br in ['128k', '192k', '320k'])
              ListTile(
                title: Text(_bitrateLabel(br)),
                trailing: _defaultBitrate == br ? const Icon(Icons.check, color: Colors.black) : null,
                onTap: () {
                  setState(() => _defaultBitrate = br);
                  _saveSetting('default_bitrate', br);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'http://your-server:8000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() => _serverUrl = controller.text.trim());
              _saveSetting('server_url', _serverUrl);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定清除所有临时文件？已保存的音频不会受影响。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              // TODO: 实际清理逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
