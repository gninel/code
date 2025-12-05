import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/food_provider.dart';
import '../models/api_response.dart';
import '../models/food_item.dart';
import '../widgets/calorie_trend_chart.dart';
import '../widgets/food_card.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';

/// 热量分析页面（原统计页面）
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'this_week';
  
  // 筛选状态
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterMealType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 初始化为本周
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePeriodDateRange('this_week');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 显示筛选对话框
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FilterDialog(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        mealType: _filterMealType,
      ),
    );

    if (result != null) {
      setState(() {
        _filterStartDate = result['startDate'];
        _filterEndDate = result['endDate'];
        _filterMealType = result['mealType'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('statistics')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(text: l10n.get('detailed_records')),
            Tab(text: l10n.get('this_week')),
            Tab(text: l10n.get('this_month')),
          ],
        ),
      ),
      body: Consumer2<StatisticsProvider, FoodProvider>(
        builder: (context, statisticsProvider, foodProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRecordListTab(statisticsProvider, foodProvider),
              _buildWeekTrendTab(context, statisticsProvider, foodProvider),
              _buildMonthTrendTab(context, statisticsProvider, foodProvider),
            ],
          );
        },
      ),
    );
  }

  /// 记录列表Tab
  Widget _buildRecordListTab(
    StatisticsProvider statisticsProvider,
    FoodProvider foodProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // 获取筛选后的数据
    final filteredItems = foodProvider.filterFoodItems(
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      mealType: _filterMealType,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          statisticsProvider.refresh(),
          foodProvider.refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部周期选择器
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: ['this_week', 'this_month', 'all'].map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(l10n.get(key)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _updatePeriodDateRange(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 统计卡片
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: l10n.get('average_per_day'),
                    value: _calculateAverageCalories(
                      filteredItems, 
                      days: _selectedPeriod == 'this_week' ? 7 : 
                            _selectedPeriod == 'this_month' ? 30 : 
                            filteredItems.isEmpty ? 1 : 
                            (filteredItems.first.createdAt.difference(filteredItems.last.createdAt).inDays + 1)
                    ).toString(),
                    change: _calculateCalorieChange(filteredItems),
                    isPositive: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: _selectedPeriod == 'this_week' ? l10n.get('this_week_total') : 
                            _selectedPeriod == 'this_month' ? l10n.get('this_month_total') : l10n.get('this_period_total'),
                    value: AppUtils.formatCalories(context, _calculateTotalCalories(filteredItems)),
                    change: '',
                    isPositive: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 趋势图
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('calorie_trend'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CalorieTrendChart(
                    data: _generateChartData(foodProvider.filterFoodItems(
                      startDate: _filterStartDate,
                      endDate: _filterEndDate,
                      mealType: _filterMealType,
                    ), l10n),
                    isWeekly: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 食物记录列表
            Text(
              _selectedPeriod == 'this_week' ? l10n.get('this_week_records') : 
              _selectedPeriod == 'this_month' ? l10n.get('this_month_records') : l10n.get('detailed_records'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._buildFoodRecordList(foodProvider, l10n),
          ],
        ),
      ),
    );
  }

  /// 周趋势Tab
  Widget _buildWeekTrendTab(BuildContext context, StatisticsProvider statisticsProvider, FoodProvider foodProvider) {
    final l10n = AppLocalizations.of(context)!;
    final filteredItems = foodProvider.filterFoodItems(
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      mealType: _filterMealType,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('calorie_trend'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CalorieTrendChart(
                data: _getWeeklyData(filteredItems),
                isWeekly: true,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 统计信息
          _buildTrendStats(
            context: context,
            averageCalories: _calculateAverageCalories(filteredItems, days: 7),
            totalCalories: _calculateTotalCalories(filteredItems),
            maxCalories: _calculateMaxDailyCalories(filteredItems),
            minCalories: _calculateMinDailyCalories(filteredItems),
          ),
        ],
      ),
    );
  }

  /// 月趋势Tab
  Widget _buildMonthTrendTab(BuildContext context, StatisticsProvider statisticsProvider, FoodProvider foodProvider) {
    final l10n = AppLocalizations.of(context)!;
    final filteredItems = foodProvider.filterFoodItems(
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      mealType: _filterMealType,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('calorie_trend'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CalorieTrendChart(
                data: _getMonthlyData(filteredItems, l10n),
                isWeekly: false,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 月度统计信息
          _buildTrendStats(
            context: context,
            averageCalories: _calculateAverageCalories(filteredItems, days: 30),
            totalCalories: _calculateTotalCalories(filteredItems),
            maxCalories: _calculateMaxDailyCalories(filteredItems),
            minCalories: _calculateMinDailyCalories(filteredItems),
          ),
        ],
      ),
    );
  }

  /// 统计卡片
  /// 统计卡片
  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (change.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 10,
                      color: isPositive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 趋势统计信息
  Widget _buildTrendStats({
    required BuildContext context,
    required int averageCalories,
    required int totalCalories,
    required int maxCalories,
    required int minCalories,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(l10n.get('average_per_day'), AppUtils.formatCalories(context, averageCalories)),
            const Divider(),
            _buildStatRow(l10n.get('total'), AppUtils.formatCalories(context, totalCalories)),
            const Divider(),
            _buildStatRow(l10n.get('high_calorie'), AppUtils.formatCalories(context, maxCalories)),
            const Divider(),
            _buildStatRow(l10n.get('low_calorie'), AppUtils.formatCalories(context, minCalories)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 食物记录列表
  List<Widget> _buildFoodRecordList(FoodProvider foodProvider, AppLocalizations l10n) {
    final filteredItems = foodProvider.filterFoodItems(
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      mealType: _filterMealType,
    );

    if (filteredItems.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.get('no_records')),
          ),
        ),
      ];
    }

    // 按日期分组
    final Map<String, List<FoodItem>> groupedItems = {};
    for (var item in filteredItems) {
      final dateKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}';
      if (!groupedItems.containsKey(dateKey)) {
        groupedItems[dateKey] = [];
      }
      groupedItems[dateKey]!.add(item);
    }

    final List<Widget> widgets = [];
    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 降序排列

    for (var dateKey in sortedKeys) {
      final items = groupedItems[dateKey]!;
      final date = items.first.createdAt;
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            AppUtils.formatDate(context, date),
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

      widgets.addAll(items.map((foodItem) {
        return FoodCard(
          foodItem: foodItem,
          onTap: () {
            // 跳转到详情页面（复用结果页）
            final analysis = FoodAnalysis(
              foodName: foodItem.foodName,
              ingredients: foodItem.ingredients,
              calories: foodItem.calories,
              weight: foodItem.weight, // 使用真实重量
              mealType: foodItem.mealType,
              nutritionInfo: '',
              confidence: 1.0,
              tags: [],
            );
            
            AppRoutes.navigateToResult(context, {
              'analysis': analysis,
              'imagePath': foodItem.imagePath,
              'id': foodItem.id, // 传递记录ID
              'createdAt': foodItem.createdAt, // 传递原始创建时间
            });
          },
          onDelete: () async {
            final confirmed = await AppUtils.showConfirmDialog(
              context,
              title: l10n.get('delete_record'),
              content: l10n.get('delete_confirm'),
            );
            if (confirmed) {
              foodProvider.deleteFoodRecord(foodItem.id!);
            }
          },
        );
      }));
    }

    return widgets;
  }

  /// 更新周期日期范围
  void _updatePeriodDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      if (period == 'this_week') {
        // 获取本周一
        final monday = now.subtract(Duration(days: now.weekday - 1));
        _filterStartDate = DateTime(monday.year, monday.month, monday.day);
        // 获取本周日
        final sunday = monday.add(const Duration(days: 6));
        _filterEndDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      } else if (period == 'this_month') {
        // 获取本月第一天
        _filterStartDate = DateTime(now.year, now.month, 1);
        // 获取本月最后一天
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        _filterEndDate = nextMonth.subtract(const Duration(seconds: 1));
      } else {
        _filterStartDate = null;
        _filterEndDate = null;
      }
    });
  }

  /// 从食物记录生成图表数据
  List<DailyCalorieData> _generateChartData(List<FoodItem> items, AppLocalizations l10n) {
    if (items.isEmpty) return [];

    // 按日期分组聚合热量
    final Map<String, int> dailyCalories = {};
    for (var item in items) {
      final dateKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}';
      dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + item.calories;
    }

    // 确定日期范围
    DateTime start = _filterStartDate ?? items.last.createdAt; // items是按时间倒序的，所以last是最早的
    DateTime end = _filterEndDate ?? items.first.createdAt;

    // 确保 start <= end
    if (start.isAfter(end)) {
      final temp = start;
      start = end;
      end = temp;
    }

    // 生成连续的日期数据
    final List<DailyCalorieData> data = [];
    final days = end.difference(start).inDays + 1;
    
    // 只对"全部"视图进行30天限制，保留"本周"/"本月"的完整数据
    bool shouldLimit = _selectedPeriod == 'all' && days > 30;
    final displayDays = shouldLimit ? 30 : days;
    final displayStart = shouldLimit ? end.subtract(Duration(days: 29)) : start;

    for (int i = 0; i < displayDays; i++) {
      final date = displayStart.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final calories = dailyCalories[dateKey] ?? 0;
      
      String label = '';
      if (displayDays <= 7) {
        final weekdays = [
          l10n.get('monday'),
          l10n.get('tuesday'),
          l10n.get('wednesday'),
          l10n.get('thursday'),
          l10n.get('friday'),
          l10n.get('saturday'),
          l10n.get('sunday')
        ];
        label = weekdays[date.weekday - 1];
      } else {
        label = '${date.month}/${date.day}';
      }

      data.add(DailyCalorieData(
        label: label,
        calories: calories,
        date: date,
      ));
    }

    return data;
  }

  /// 获取周数据（按周汇总）
  List<DailyCalorieData> _getWeeklyData(List<FoodItem> items) {
    if (items.isEmpty) return [];

    // 按周分组聚合热量
    final Map<String, int> weeklyCalories = {};
    final Map<String, DateTime> weekStartDates = {};

    for (var item in items) {
      // 计算该日期所在周的周一
      final date = item.createdAt;
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = '${monday.year}-W${_getWeekOfYear(monday)}';
      
      weeklyCalories[weekKey] = (weeklyCalories[weekKey] ?? 0) + item.calories;
      weekStartDates[weekKey] = DateTime(monday.year, monday.month, monday.day);
    }

    // 获取最近12周
    final now = DateTime.now();
    final List<DailyCalorieData> data = [];
    
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekKey = '${weekStart.year}-W${_getWeekOfYear(weekStart)}';
      final calories = weeklyCalories[weekKey] ?? 0;
      
      data.add(DailyCalorieData(
        label: '${weekStart.month}/${weekStart.day}',
        calories: calories,
        date: weekStart,
      ));
    }

    return data;
  }

  /// 获取月数据（按月汇总）
  /// 获取月数据（按月汇总）
  List<DailyCalorieData> _getMonthlyData(List<FoodItem> items, AppLocalizations l10n) {
    if (items.isEmpty) return [];

    // 按月分组聚合热量
    final Map<String, int> monthlyCalories = {};

    for (var item in items) {
      final date = item.createdAt;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyCalories[monthKey] = (monthlyCalories[monthKey] ?? 0) + item.calories;
    }

    // 获取最近12个月
    final now = DateTime.now();
    final List<DailyCalorieData> data = [];
    
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final calories = monthlyCalories[monthKey] ?? 0;
      
      data.add(DailyCalorieData(
        label: l10n.get('month_${month.month}'),
        calories: calories,
        date: month,
      ));
    }

    return data;
  }

  /// 计算一年中的第几周
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(firstDayOfYear).inDays;
    return (daysSinceStart / 7).ceil() + 1;
  }

  /// 计算总热量
  int _calculateTotalCalories(List<FoodItem> items) {
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) => sum + item.calories);
  }

  /// 计算平均每日热量
  int _calculateAverageCalories(List<FoodItem> items, {int days = 1}) {
    if (items.isEmpty) return 0;
    
    // 计算总热量
    final total = _calculateTotalCalories(items);
    
    // 如果指定了天数，直接除以天数
    if (days > 1) {
      return (total / days).round();
    }
    
    // 否则按有数据的天数计算（兼容旧逻辑，虽然这里可能不再需要）
    final Map<String, int> dailyCalories = {};
    for (var item in items) {
      final dateKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}';
      dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + item.calories;
    }
    
    if (dailyCalories.isEmpty) return 0;
    return (total / dailyCalories.length).round();
  }

  /// 计算热量变化
  String _calculateCalorieChange(List<FoodItem> items) {
    if (items.isEmpty) return '';
    
    // 简单计算：与上一周期对比
    final total = _calculateTotalCalories(items);
    // 这里简化处理，实际应该对比上一周期
    return '';  // 暂时返回空字符串
  }

  /// 计算最高每日热量
  int _calculateMaxDailyCalories(List<FoodItem> items) {
    if (items.isEmpty) return 0;
    
    final Map<String, int> dailyCalories = {};
    for (var item in items) {
      final dateKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}';
      dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + item.calories;
    }
    
    if (dailyCalories.isEmpty) return 0;
    return dailyCalories.values.reduce((a, b) => a > b ? a : b);
  }

  /// 计算最低每日热量
  int _calculateMinDailyCalories(List<FoodItem> items) {
    if (items.isEmpty) return 0;
    
    final Map<String, int> dailyCalories = {};
    for (var item in items) {
      final dateKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}';
      dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + item.calories;
    }
    
    if (dailyCalories.isEmpty) return 0;
    return dailyCalories.values.reduce((a, b) => a < b ? a : b);
  }

  }


class _FilterDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String mealType;

  const _FilterDialog({
    Key? key,
    this.startDate,
    this.endDate,
    required this.mealType,
  }) : super(key: key);

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _mealType = widget.mealType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('筛选记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('日期范围', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Text(_startDate == null ? '开始日期' : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'),
                ),
              ),
              const Text(' - '),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: Text(_endDate == null ? '结束日期' : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('餐次类型', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _mealType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('全部')),
              DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
              DropdownMenuItem(value: 'lunch', child: Text('午餐')),
              DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
              DropdownMenuItem(value: 'other', child: Text('其他')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _mealType = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
              _mealType = 'all';
            });
          },
          child: const Text('重置'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'startDate': _startDate,
              'endDate': _endDate,
              'mealType': _mealType,
            });
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}