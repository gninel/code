import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';

/// 食物分析结果卡片
class FoodAnalysisCard extends StatelessWidget {
  final FoodAnalysis analysis;

  const FoodAnalysisCard({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食物名称和置信度
            _buildFoodHeader(context),
            const SizedBox(height: 20),

            // 主要信息网格
            _buildMainInfoGrid(context),
            const SizedBox(height: 20),

            // 成分信息
            if (analysis.ingredients.isNotEmpty) ...[
              _buildIngredientsSection(context),
              const SizedBox(height: 20),
            ],

            // 标签
            if (analysis.tags.isNotEmpty) _buildTagsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodHeader(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final displayName = isEnglish && analysis.foodNameEn.isNotEmpty 
        ? analysis.foodNameEn 
        : analysis.foodName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getConfidenceColor(analysis.confidence).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getConfidenceColor(analysis.confidence),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConfidenceIcon(analysis.confidence),
                    size: 16,
                    color: _getConfidenceColor(analysis.confidence),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(analysis.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(analysis.confidence),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.get('ai_result'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfoGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildInfoCard(
          context: context,
          icon: Icons.local_fire_department,
          title: l10n.get('calories'),
          value: AppUtils.formatCalories(context, analysis.calories),
          color: AppUtils.getCalorieColor(analysis.calories),
          valueColor: AppUtils.getCalorieColor(analysis.calories),
        ),
        _buildInfoCard(
          context: context,
          icon: Icons.scale,
          title: l10n.get('weight'),
          value: '${analysis.weight.toStringAsFixed(1)}${l10n.get('gram')}',
          color: Colors.blue,
        ),
        _buildInfoCard(
          context: context,
          icon: Icons.restaurant,
          title: l10n.get('meal_type'),
          value: AppUtils.getMealName(context, analysis.mealType),
          color: Colors.green,
        ),
        _buildInfoCard(
          context: context,
          icon: Icons.speed,
          title: l10n.get('calorie_density'),
          value: '${analysis.calorieDensity.toStringAsFixed(1)} ${l10n.get('kcal_per_100g')}',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory_2,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              l10n.get('main_ingredients'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: () {
            final isEnglish = Localizations.localeOf(context).languageCode == 'en';
            final displayIngredients = isEnglish && analysis.ingredientsEn.isNotEmpty
                ? analysis.ingredientsEn.take(3).toList()
                : analysis.mainIngredients;
            return displayIngredients.map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ingredient,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList();
          }(),
        ),
        if (analysis.ingredients.length > 3) ...[
          const SizedBox(height: 8),
          Text(
            l10n.get('total_ingredients').replaceAll('{count}', analysis.ingredients.length.toString()),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              l10n.get('tags'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) {
      return Colors.green;
    } else if (confidence >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.9) {
      return Icons.check_circle;
    } else if (confidence >= 0.7) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }
}

/// 简化版食物分析卡片
class FoodAnalysisSummaryCard extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback? onTap;

  const FoodAnalysisSummaryCard({
    Key? key,
    required this.analysis,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 主要信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.foodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppUtils.getCalorieColor(analysis.calories),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppUtils.formatCalories(context, analysis.calories),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppUtils.getCalorieColor(analysis.calories),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${analysis.weight.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 置信度指示器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(analysis.confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getConfidenceIcon(analysis.confidence),
                      size: 12,
                      color: _getConfidenceColor(analysis.confidence),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(analysis.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getConfidenceColor(analysis.confidence),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) {
      return Colors.green;
    } else if (confidence >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.9) {
      return Icons.check_circle;
    } else if (confidence >= 0.7) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }
}