import 'package:flutter/material.dart';
import '../app.dart';

/// 每日汇总组件
class DailySummary extends StatelessWidget {
  final int totalCalories;
  final Map<String, int> mealCalories;
  final int? recommendedCalories;
  final bool showDetails;

  const DailySummary({
    Key? key,
    required this.totalCalories,
    required this.mealCalories,
    this.recommendedCalories,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 总热量显示
            _buildTotalCaloriesSection(context),
            const SizedBox(height: 20),

            // 热量进度条
            _buildCalorieProgressBar(context),
            const SizedBox(height: 20),

            // 餐次详情
            if (showDetails) _buildMealDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCaloriesSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              AppUtils.formatCalories(context, totalCalories),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '今日总热量',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (recommendedCalories != null) ...[
          const SizedBox(height: 4),
          Text(
            '建议: ${AppUtils.formatCalories(context, recommendedCalories!)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalorieProgressBar(BuildContext context) {
    final recommended = recommendedCalories ?? 2000;
    final percentage = (totalCalories / recommended).clamp(0.0, 1.0);
    final statusColor = _getCalorieStatusColor(totalCalories, recommended);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '完成度',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          _getCalorieStatusText(totalCalories, recommended),
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMealDetails(BuildContext context) {
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '餐次分布',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...mealTypes.map((mealType) => _buildMealItem(mealType)),
      ],
    );
  }

  Widget _buildMealItem(String mealType) {
    final calories = mealCalories[mealType] ?? 0;
    final percentage = totalCalories > 0 ? (calories / totalCalories) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 餐次图标
          Icon(
            AppUtils.getMealIcon(mealType),
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),

          // 餐次名称
          SizedBox(
            width: 40,
            child: Text(
              AppUtils.getMealName(mealType),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 进度条
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getMealTypeColor(mealType),
                ),
                minHeight: 6,
              ),
            ),
          ),

          // 热量值
          SizedBox(
            width: 60,
            child: Text(
              AppUtils.formatCalories(context, calories),
              textAlign: 'right',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCalorieStatusColor(int actual, int recommended) {
    final ratio = actual / recommended;

    if (ratio < 0.8) {
      return Colors.orange; // 摄入不足
    } else if (ratio > 1.2) {
      return Colors.red; // 摄入超标
    } else {
      return Colors.green; // 正常
    }
  }

  String _getCalorieStatusText(int actual, int recommended) {
    final ratio = actual / recommended;

    if (ratio < 0.8) {
      return '热量摄入偏低，建议适量增加';
    } else if (ratio > 1.2) {
      return '热量摄入偏高，建议适当控制';
    } else {
      return '热量摄入正常，继续保持';
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'dinner':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// 简化版每日汇总卡片
class DailySummaryCard extends StatelessWidget {
  final int totalCalories;
  final Map<String, int> mealCalories;
  final VoidCallback? onTap;

  const DailySummaryCard({
    Key? key,
    required this.totalCalories,
    required this.mealCalories,
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
              // 图标
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.today,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日摄入',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppUtils.formatCalories(context, totalCalories),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 餐次快速预览
              Row(
                children: [
                  if ((mealCalories['breakfast'] ?? 0) > 0) ...[
                    Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                    const SizedBox(width: 2),
                  ],
                  if ((mealCalories['lunch'] ?? 0) > 0) ...[
                    Icon(Icons.wb_cloudy, size: 16, color: Colors.blue),
                    const SizedBox(width: 2),
                  ],
                  if ((mealCalories['dinner'] ?? 0) > 0) ...[
                    Icon(Icons.nights_stay, size: 16, color: Colors.purple),
                  ],
                ],
              ),

              const SizedBox(width: 8),

              // 箭头图标
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 热量环形图组件
class CalorieRingChart extends StatelessWidget {
  final int currentCalories;
  final int recommendedCalories;
  final double size;
  final double strokeWidth;

  const CalorieRingChart({
    Key? key,
    required this.currentCalories,
    required this.recommendedCalories,
    this.size = 120,
    this.strokeWidth = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (currentCalories / recommendedCalories).clamp(0.0, 1.0);
    final color = _getCalorieStatusColor(currentCalories, recommendedCalories);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 背景圆环
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
            ),
          ),

          // 进度圆环
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          // 中心文字
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '完成度',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCalorieStatusColor(int actual, int recommended) {
    final ratio = actual / recommended;

    if (ratio < 0.8) {
      return Colors.orange;
    } else if (ratio > 1.2) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }
}