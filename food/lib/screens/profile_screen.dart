import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../l10n/app_localizations.dart';
import 'privacy_policy_screen.dart';

/// 个人中心页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('profile')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userProvider.nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                              onPressed: () => _showEditNicknameDialog(context, userProvider, l10n),
                            ),
                          ],
                        ),
                        const Text(
                          '坚持记录，保持健康',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 设置选项
          _buildSectionTitle(l10n.get('health_settings')),
          _buildListTile(
            context,
            icon: Icons.local_fire_department_outlined,
            title: l10n.get('daily_target'),
            subtitle: '${userProvider.dailyCalorieGoal} ${l10n.get('kcal')}',
            onTap: () => _showEditCalorieGoalDialog(context, userProvider, l10n),
          ),
          _buildListTile(
            context,
            icon: Icons.straighten,
            title: l10n.get('unit_preference'),
            subtitle: l10n.get(userProvider.unitPreference),
            onTap: () => _showUnitPreferenceDialog(context, userProvider, l10n),
          ),
          _buildListTile(
            context,
            icon: Icons.language,
            title: l10n.get('language'),
            subtitle: userProvider.locale.languageCode == 'zh' 
                ? l10n.get('chinese') 
                : l10n.get('english'),
            onTap: () => _showLanguageDialog(context, userProvider, l10n),
          ),

          const SizedBox(height: 24),

          // 数据管理
          _buildSectionTitle(l10n.get('data_management')),
          _buildListTile(
            context,
            icon: Icons.download_outlined,
            title: l10n.get('export_data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.get('developing'))),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.delete_outline,
            title: l10n.get('clear_data'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _showClearDataDialog(context, l10n),
          ),

          const SizedBox(height: 24),

          // 关于
          _buildSectionTitle(l10n.get('about')),
          _buildListTile(
            context,
            icon: Icons.info_outline,
            title: l10n.get('about_app'),
            onTap: () => _showAboutDialog(context, l10n),
          ),
          _buildListTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: l10n.get('privacy_policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 修改昵称对话框
  void _showEditNicknameDialog(BuildContext context, UserProvider provider, AppLocalizations l10n) {
    final controller = TextEditingController(text: provider.nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('edit_nickname')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.get('enter_nickname'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.updateNickname(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  // 修改热量目标对话框
  void _showEditCalorieGoalDialog(BuildContext context, UserProvider provider, AppLocalizations l10n) {
    final controller = TextEditingController(text: provider.dailyCalorieGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('set_daily_goal')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l10n.get('example_2000'),
            suffixText: l10n.get('kcal'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                provider.updateDailyCalorieGoal(goal);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  // 单位设置对话框
  void _showUnitPreferenceDialog(BuildContext context, UserProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('unit_preference')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.get('kcal_kg')),
              value: 'kcal_kg',
              groupValue: provider.unitPreference,
              onChanged: (value) {
                if (value != null) {
                  provider.updateUnitPreference(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.get('cal_lb')),
              value: 'cal_lb',
              groupValue: provider.unitPreference,
              onChanged: (value) {
                if (value != null) {
                  provider.updateUnitPreference(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 语言设置对话框
  void _showLanguageDialog(BuildContext context, UserProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.get('chinese')),
              value: 'zh',
              groupValue: provider.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  provider.updateLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.get('english')),
              value: 'en',
              groupValue: provider.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  provider.updateLocale(Locale(value));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 清除数据对话框
  void _showClearDataDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('clear_data_title')),
        content: Text(l10n.get('clear_data_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<FoodProvider>(context, listen: false).clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? l10n.get('data_cleared') : l10n.get('clear_failed')),
                  ),
                );
              }
            },
            child: Text(l10n.get('clear_confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.get('app_name'),
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant, size: 32, color: Colors.white),
      ),
      children: const [
        SizedBox(height: 16),
        Text('基于AI技术的食物热量识别应用，帮助您科学管理饮食健康。'),
        SizedBox(height: 8),
        Text('功能特点：'),
        Text('• 拍照识别食物热量与营养'),
        Text('• 智能估算重量与热量密度'),
        Text('• 每日/每周/每月饮食统计'),
        Text('• 数据本地存储，安全隐私'),
      ],
    );
  }
}
