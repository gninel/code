import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/api_response.dart';
import '../models/food_item.dart';
import '../app.dart';
import '../widgets/food_analysis_card.dart';
import '../l10n/app_localizations.dart';

/// 识别结果界面
class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  FoodAnalysis? _analysis;
  String? _imagePath;
  String _selectedMealType = 'lunch';
  bool _isSaving = false;

  int? _recordId; // 记录ID（如果是编辑模式）
  bool _isLoaded = false;
  DateTime? _originalCreatedAt; // 原始创建时间

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _loadArguments();
      _isLoaded = true;
    }
  }

  /// 加载路由参数
  void _loadArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      _analysis = arguments['analysis'] as FoodAnalysis?;
      _imagePath = arguments['imagePath'] as String?;
      _recordId = arguments['id'] as int?; // 获取记录ID
      _originalCreatedAt = arguments['createdAt'] as DateTime?; // 获取原始创建时间

      // 如果有记录ID，说明是编辑模式，使用记录中的餐次
      if (_recordId != null && _analysis != null) {
        _selectedMealType = _analysis!.mealType;
      } else {
        // 否则根据时间自动选择餐次
        _selectedMealType = _getDefaultMealType();
      }
    }
  }

  /// 根据当前时间获取默认餐次
  String _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) {
      return 'breakfast';
    } else if (hour >= 10 && hour < 14) {
      return 'lunch';
    } else if (hour >= 14 && hour < 20) {
      return 'dinner';
    } else {
      return 'other';
    }
  }

  /// 保存食物记录
  Future<void> _saveFoodRecord() async {
    if (_analysis == null || _imagePath == null) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    try {
      setState(() {
        _isSaving = true;
      });

      bool success;
      if (_recordId != null) {
        // 更新现有记录
        success = await foodProvider.updateFoodRecord(FoodItem(
          id: _recordId,
          foodName: _analysis!.foodName,
          ingredients: _analysis!.ingredients,
          calories: _analysis!.calories,
          imagePath: _imagePath!,
          createdAt: _originalCreatedAt ?? DateTime.now(), // 使用原始时间，如果为空则使用当前时间
          mealType: _selectedMealType,
          weight: _analysis!.weight,
        ));
      } else {
        // 创建新记录
        success = await foodProvider.saveFoodRecord(
          foodName: _analysis!.foodName,
          foodNameEn: _analysis!.foodNameEn,
          ingredients: _analysis!.ingredients,
          ingredientsEn: _analysis!.ingredientsEn,
          calories: _analysis!.calories,
          imagePath: _imagePath!,
          mealType: _selectedMealType,
          weight: _analysis!.weight,
          nutritionInfo: _analysis!.nutritionInfo,
          confidence: _analysis!.confidence,
          tags: _analysis!.tags,
          tagsEn: _analysis!.tagsEn,
        );
      }

      if (success) {
        final l10n = AppLocalizations.of(context)!;
        AppUtils.showSuccessSnackBar(context, _recordId != null ? l10n.get('record_updated') : l10n.get('record_saved'));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final l10n = AppLocalizations.of(context)!;
        AppUtils.showErrorSnackBar(context, _recordId != null ? l10n.get('update_failed') : l10n.get('save_failed'));
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      AppUtils.showErrorSnackBar(context, '${l10n.get('operation_failed')}: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// 重新识别
  void _reRecognize() {
    Navigator.of(context).pop();
  }

  /// 编辑食物信息
  void _editFoodInfo() {
    _showEditDialog();
  }

  /// 显示编辑对话框
  void _showEditDialog() {
    if (_analysis == null) return;

    final foodNameController = TextEditingController(text: _analysis!.foodName);
    final caloriesController = TextEditingController(text: _analysis!.calories.toString());
    final weightController = TextEditingController(text: _analysis!.weight.toString());

    // 保存初始热量密度
    final initialDensity = _analysis!.calorieDensity;

    // 监听重量变化，自动更新热量
    weightController.addListener(() {
      final newWeight = double.tryParse(weightController.text);
      if (newWeight != null && newWeight > 0) {
        final newCalories = (newWeight * initialDensity / 100).round();
        // 只有当计算出的热量与当前输入框不同时才更新，避免光标跳动问题
        if (caloriesController.text != newCalories.toString()) {
          caloriesController.text = newCalories.toString();
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final isEnglish = Localizations.localeOf(context).languageCode == 'en';
        final initialFoodName = isEnglish && _analysis!.foodNameEn.isNotEmpty
            ? _analysis!.foodNameEn
            : _analysis!.foodName;
        
        // 如果控制器还没有被初始化或者内容为空，则设置初始值
        if (foodNameController.text.isEmpty) {
          foodNameController.text = initialFoodName;
        }

        return AlertDialog(
          title: Text(l10n.get('edit_food_info')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: foodNameController,
                  decoration: InputDecoration(
                    labelText: l10n.get('food_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: '${l10n.get('weight')} (${l10n.get('gram')})',
                    border: const OutlineInputBorder(),
                    helperText: l10n.get('weight_calc_hint'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(
                    labelText: '${l10n.get('calories')} (${l10n.get('kcal')})',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
              final newCalories = int.tryParse(caloriesController.text) ?? _analysis!.calories;
              final newWeight = double.tryParse(weightController.text) ?? _analysis!.weight;

              final isEnglish = Localizations.localeOf(context).languageCode == 'en';
              
              setState(() {
                _analysis = _analysis!.copyWith(
                  foodName: isEnglish ? _analysis!.foodName : foodNameController.text, // 如果是英文环境，保持中文名不变
                  foodNameEn: isEnglish ? foodNameController.text : _analysis!.foodNameEn, // 更新英文名
                  calories: newCalories,
                  weight: newWeight,
                );
                
                // 如果在非英文环境修改了名称，同时也更新 foodName
                if (!isEnglish) {
                   _analysis = _analysis!.copyWith(foodName: foodNameController.text);
                }
              });
              
              AppUtils.showSuccessSnackBar(context, l10n.get('info_updated'));

              Navigator.of(context).pop();
            },
            child: Text(l10n.get('confirm')),
          ),
        ],
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_analysis == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('recognition_result')),
        ),
        body: Center(
          child: Text(l10n.get('no_result')),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('recognition_result')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editFoodInfo,
            tooltip: l10n.get('edit_food_info'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片预览
                  _buildImagePreview(),
                  const SizedBox(height: 24),

                  // 识别结果卡片
                  FoodAnalysisCard(analysis: _analysis!),
                  const SizedBox(height: 24),

                  // 餐次选择
                  _buildMealTypeSelector(),
                  const SizedBox(height: 24),

                  // 详细信息
                  _buildDetailedInfo(),
                ],
              ),
            ),
          ),

          // 底部操作按钮
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _imagePath != null && File(_imagePath!).existsSync()
            ? Image.file(
                File(_imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 48),
                          Text(l10n.get('image_load_failed')),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 48),
                      Text(l10n.get('no_image')),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('select_meal'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMealTypeOption(l10n.get('breakfast'), 'breakfast', Icons.wb_sunny),
                const SizedBox(width: 12),
                _buildMealTypeOption(l10n.get('lunch'), 'lunch', Icons.wb_cloudy),
                const SizedBox(width: 12),
                _buildMealTypeOption(l10n.get('dinner'), 'dinner', Icons.nights_stay),
                const SizedBox(width: 12),
                _buildMealTypeOption(l10n.get('other'), 'other', Icons.restaurant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(String label, String value, IconData icon) {
    final isSelected = _selectedMealType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMealType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('detail_info'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 成分信息
            if (_analysis!.ingredients.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                  final ingredients = isEnglish && _analysis!.ingredientsEn.isNotEmpty
                      ? _analysis!.ingredientsEn
                      : _analysis!.ingredients;
                  return _buildInfoRow(l10n.get('ingredients'), ingredients.join(', '));
                }
              ),
              const SizedBox(height: 8),
            ],

            // 重量信息（带编辑按钮）
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(l10n.get('weight'), '${_analysis!.weight.toStringAsFixed(1)} ${l10n.get('gram')}'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _editWeight,
                  tooltip: l10n.get('edit_weight'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 热量密度（带调整提示）
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    l10n.get('calorie_density'),
                    '${_analysis!.calorieDensity.toStringAsFixed(1)} ${l10n.get('kcal_per_100g')}',
                  ),
                ),
                if (_analysis!.isAdjusted) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.get('density_abnormal_adjusted').replaceAll('{weight}', _analysis!.originalWeight?.toStringAsFixed(1) ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            l10n.get('adjusted'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // 置信度
            _buildInfoRow(l10n.get('confidence'), '${(_analysis!.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),

            // 营养信息
            if (_analysis!.nutritionInfo.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                  final nutritionInfo = isEnglish && _analysis!.nutritionInfoEn.isNotEmpty
                      ? _analysis!.nutritionInfoEn
                      : _analysis!.nutritionInfo;
                  return _buildInfoRow(l10n.get('nutrition_info'), nutritionInfo);
                }
              ),
              const SizedBox(height: 8),
            ],

            // 标签
            if (_analysis!.tags.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                  final tags = isEnglish && _analysis!.tagsEn.isNotEmpty
                      ? _analysis!.tagsEn
                      : _analysis!.tags;
                  return _buildInfoRow(l10n.get('tags'), tags.join(', '));
                }
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_recordId == null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.get('rerecognize')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_recordId == null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveFoodRecord,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? l10n.get('saving') : (_recordId != null ? l10n.get('update_record') : l10n.get('save_record'))),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 编辑重量
  Future<void> _editWeight() async {
    final controller = TextEditingController(
      text: _analysis!.weight.toStringAsFixed(1),
    );

    final newWeight = await showDialog<double>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.get('edit_weight')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('enter_weight'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  suffix: Text(l10n.get('gram')),
                  hintText: l10n.get('weight_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) {
                  final weight = double.tryParse(value);
                  if (weight != null && weight > 0) {
                    Navigator.of(context).pop(weight);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('calorie_recalc_hint'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(controller.text);
                if (weight != null && weight > 0) {
                  Navigator.of(context).pop(weight);
                } else {
                  AppUtils.showErrorSnackBar(context, l10n.get('enter_valid_weight'));
                }
              },
              child: Text(l10n.get('confirm')),
            ),
          ],
        );
      },
    );

    if (newWeight != null && newWeight != _analysis!.weight) {
      final oldCalorieDensity = _analysis!.calorieDensity;
      final newCalories = (newWeight * oldCalorieDensity / 100).round();
      
      setState(() {
        _analysis = _analysis!.copyWith(
          weight: newWeight,
          calories: newCalories,
        );
      });
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = l10n.get('weight_updated')
            .replaceAll('{weight}', newWeight.toStringAsFixed(1))
            .replaceAll('{calories}', newCalories.toString());
        AppUtils.showSuccessSnackBar(context, msg);
      }
    }
    
    controller.dispose();
  }
}