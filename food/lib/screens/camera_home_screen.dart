import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';

/// 拍照记录首页
class CameraHomeScreen extends StatelessWidget {
  const CameraHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // 浅青色背景
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 打开设置
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.get('developing'))),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主标题
            Text(
              AppLocalizations.of(context)!.get('camera_home'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 80),

            // 大型圆形相机按钮
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF26a69a),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26a69a).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _takePhoto(context),
                  customBorder: const CircleBorder(),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 提示文字
            Text(
              AppLocalizations.of(context)!.get('take_photo'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            
            const SizedBox(height: 32),

            const SizedBox(height: 16),

            // 从相册选择按钮
            TextButton.icon(
              onPressed: () => _pickImage(context),
              icon: const Icon(Icons.photo_library, color: Color(0xFF00897b)),
              label: Text(
                AppLocalizations.of(context)!.get('select_from_gallery'),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF00897b),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFF00897b), width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 拍照识别食物
  void _takePhoto(BuildContext context) {
    AppRoutes.navigateToCamera(context, (imagePath) {
      _processImage(context, imagePath);
    });
  }

  /// 从相册选择图片
  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _processImage(context, image.path);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, '选择图片失败: $e');
    }
  }

  /// 处理图片
  Future<void> _processImage(BuildContext context, String imagePath) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    try {
      debugPrint('开始处理图片: $imagePath');
      
      // 使用 SnackBar 显示进度，而不是阻塞式 dialog
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(AppLocalizations.of(context)!.get('recognizing_food')),
            ],
          ),
          duration: const Duration(minutes: 2), // 足够长的时间
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 调用API识别（传递当前语言设置）
      debugPrint('调用API识别...');
      final languageCode = Localizations.localeOf(context).languageCode;
      final response = await foodProvider.recognizeFoodFromImage(imagePath, languageCode: languageCode);

      debugPrint('API识别返回，success: ${response.success}');
      
      // 隐藏进度提示
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.success && response.data != null) {
        debugPrint('跳转到结果页面');
        // 跳转到结果页面
        if (!context.mounted) return;
        AppRoutes.navigateToResult(context, {
          'analysis': response.data,
          'imagePath': imagePath,
        });
      } else {
        debugPrint('显示错误: ${response.message}');
        if (!context.mounted) return;
        AppUtils.showErrorSnackBar(context, response.message);
      }
    } catch (e, stackTrace) {
      debugPrint('处理图片异常: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!context.mounted) return;
      AppUtils.showErrorSnackBar(context, '识别失败: $e');
    }
  }
}
