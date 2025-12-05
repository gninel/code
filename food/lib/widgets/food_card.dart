import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';

/// 食物卡片组件
class FoodCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showActions;

  const FoodCard({
    Key? key,
    required this.foodItem,
    this.onTap,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 食物图片
              _buildFoodImage(context),
              const SizedBox(width: 12),

              // 食物信息
              Expanded(
                child: _buildFoodInfo(context),
              ),

              // 操作按钮
              if (showActions) ...[
                const SizedBox(width: 8),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodImage(BuildContext context) {
    if (foodItem.imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(foodItem.imagePath),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage(context);
          },
        ),
      );
    }
    return _buildDefaultImage(context);
  }

  Widget _buildDefaultImage(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        AppUtils.getMealIcon(foodItem.mealType),
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }

  Widget _buildFoodInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 食物名称
        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                  final displayName = isEnglish && foodItem.foodNameEn.isNotEmpty
                      ? foodItem.foodNameEn
                      : foodItem.foodName;
                  return Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppUtils.getCalorieColor(foodItem.calories).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppUtils.getCalorieLevel(context, foodItem.calories),
                style: TextStyle(
                  fontSize: 10,
                  color: AppUtils.getCalorieColor(foodItem.calories),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 餐次和时间
        Row(
          children: [
            Icon(
              AppUtils.getMealIcon(foodItem.mealType),
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              AppUtils.getMealName(context, foodItem.mealType),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatTime(foodItem.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 成分
        if (foodItem.ingredients.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final isEnglish = Localizations.localeOf(context).languageCode == 'en';
              final ingredients = isEnglish && foodItem.ingredientsEn.isNotEmpty
                  ? foodItem.ingredientsEn
                  : foodItem.ingredients;
              return Text(
                ingredients.take(3).join(isEnglish ? ', ' : '、'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
          ),
        ],

        const SizedBox(height: 8),

        // 热量
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: AppUtils.getCalorieColor(foodItem.calories),
            ),
            const SizedBox(width: 4),
            Text(
              AppUtils.formatCalories(context, foodItem.calories),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppUtils.getCalorieColor(foodItem.calories),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: '删除',
            color: Colors.grey[600],
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// 食物列表项组件（简化版）
class FoodListItem extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FoodListItem({
    Key? key,
    required this.foodItem,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          AppUtils.getMealIcon(foodItem.mealType),
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Builder(
        builder: (context) {
          final isEnglish = Localizations.localeOf(context).languageCode == 'en';
          final displayName = isEnglish && foodItem.foodNameEn.isNotEmpty
              ? foodItem.foodNameEn
              : foodItem.foodName;
          return Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        }
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppUtils.getMealName(context, foodItem.mealType)),
          if (foodItem.ingredients.isNotEmpty)
          if (foodItem.ingredients.isNotEmpty)
            Builder(
              builder: (context) {
                final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                final ingredients = isEnglish && foodItem.ingredientsEn.isNotEmpty
                    ? foodItem.ingredientsEn
                    : foodItem.ingredients;
                return Text(
                  ingredients.join(isEnglish ? ', ' : '、'),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppUtils.formatCalories(context, foodItem.calories),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppUtils.getCalorieColor(foodItem.calories),
                ),
              ),
              Text(
                _formatTime(foodItem.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('删除'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// 今日食物汇总卡片
class TodayFoodSummaryCard extends StatelessWidget {
  final List<FoodItem> foodItems;
  final int totalCalories;
  final VoidCallback? onViewAll;

  const TodayFoodSummaryCard({
    Key? key,
    required this.foodItems,
    required this.totalCalories,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.get('today'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(AppLocalizations.of(context)!.get('all')),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 热量汇总
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.formatCalories(context, totalCalories),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            if (foodItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              // 最近3条食物记录
              ...foodItems.take(3).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      AppUtils.getMealIcon(item.mealType),
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.foodName,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppUtils.formatCalories(context, item.calories),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.no_food,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.get('no_records'),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}