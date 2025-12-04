import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '引言',
              '欢迎使用识食君（以下简称"本应用"）。我们非常重视您的隐私保护和个人信息安全。本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. 信息收集',
              '''我们收集的信息仅限于：

• 相机权限：用于拍摄食物照片进行热量识别
• 存储权限：用于保存食物照片和历史记录
• 网络权限：用于调用 AI 模型进行食物识别

我们不会收集您的以下信息：
• 个人身份信息（姓名、身份证号等）
• 位置信息
• 联系方式
• 设备标识符''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '2. 信息使用',
              '''我们使用收集的信息仅用于：

• 食物照片识别和热量分析
• 本地存储您的饮食记录
• 提供个性化的健康建议

我们承诺：
• 不会将您的数据分享给第三方
• 不会用于商业广告用途
• 不会进行数据分析和画像''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '3. 数据存储',
              '''• 所有数据均存储在您的设备本地
• 食物照片存储在应用私有目录
• 历史记录存储在本地数据库
• 如启用云备份，数据将通过系统备份服务同步''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '4. 数据安全',
              '''我们采取以下措施保护您的数据：

• 应用沙盒隔离，防止其他应用访问
• 不上传任何个人信息到云端
• 提供数据清除功能，您可随时删除所有数据''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '5. 第三方服务',
              '''本应用使用以下第三方服务：

• Doubao AI 模型（字节跳动）：用于食物识别
  - 仅上传食物照片
  - 不包含任何个人信息
  - 符合字节跳动隐私政策''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '6. 您的权利',
              '''您有权：

• 随时查看和管理您的数据
• 导出您的饮食记录
• 清除所有历史数据
• 卸载应用（将删除所有本地数据）''',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '7. 儿童隐私',
              '本应用适用于所有年龄段用户。我们不会主动收集儿童的个人信息。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '8. 政策更新',
              '我们可能会不时更新本隐私政策。重大变更将在应用内通知您。',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '9. 联系我们',
              '''如您对本隐私政策有任何疑问，请通过以下方式联系我们：

邮箱：support@foodcalorie.app

生效日期：2025年12月3日''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
