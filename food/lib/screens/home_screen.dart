import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/statistics_provider.dart';
import '../app.dart';
import '../widgets/food_card.dart';
import '../widgets/daily_summary.dart';
import '../widgets/loading_widget.dart';

/// 主界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 初始化应用
  Future<void> _initializeApp() async {
    try {
      await AppInitializer.initialize(context);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        AppUtils.showErrorSnackBar(context, '应用初始化失败: $e');
      }
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    try {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);

      await Future.wait([
        foodProvider.refresh(),
        statisticsProvider.refresh(),
      ]);

      if (mounted) {
        AppUtils.showSuccessSnackBar(context, '数据已更新');
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showErrorSnackBar(context, '刷新失败: $e');
      }
    }
  }

  /// 拍照识别食物
  void _takePhoto() {
    AppRoutes.navigateToCamera(context, (imagePath) {
      _processImage(imagePath);
    });
  }

  /// 从相册选择图片
  void _pickFromGallery() async {
    // 注意：需要添加 image_picker 依赖
    // 这里先使用占位实现
    AppUtils.showErrorSnackBar(context, '相册选择功能待实现');
  }

  /// 处理图片
  Future<void> _processImage(String imagePath) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    try {
      // 显示加载对话框
      AppUtils.showLoadingDialog(context, '正在识别食物...');

      // 调用API识别
      final response = await foodProvider.recognizeFoodFromImage(imagePath);

      // 隐藏加载对话框
      AppUtils.hideLoadingDialog(context);

      if (response.success && response.data != null) {
        // 跳转到结果页面
        AppRoutes.navigateToResult(context, {
          'analysis': response.data,
          'imagePath': imagePath,
        });
      } else {
        AppUtils.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      AppUtils.hideLoadingDialog(context);
      AppUtils.showErrorSnackBar(context, '识别失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: LoadingWidget(message: '正在初始化应用...'),
      );
    }

    return Scaffold(
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          if (foodProvider.isLoading) {
            return const LoadingWidget(message: '加载数据中...');
          }

          if (foodProvider.error != null) {
            return _buildErrorView(foodProvider.error!);
          }

          return _buildMainView(foodProvider);
        },
      ),
    );
  }

  Widget _buildMainView(FoodProvider foodProvider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食物热量识别'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              AppRoutes.navigateToStatistics(context);
            },
            tooltip: '统计数据',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettings();
                  break;
                case 'about':
                  _showAbout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('设置'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('关于'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日记录'),
            Tab(text: '识别食物'),
            Tab(text: '历史记录'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(foodProvider),
          _buildRecognitionTab(),
          _buildHistoryTab(foodProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('拍照识别'),
      ),
    );
  }

  Widget _buildTodayTab(FoodProvider foodProvider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日汇总
            DailySummary(
              totalCalories: foodProvider.currentTotalCalories,
              mealCalories: foodProvider.mealCalories,
            ),
            const SizedBox(height: 24),

            // 今日食物列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日食物',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (foodProvider.todayRecord?.allItems.isEmpty ?? true)
              _buildEmptyState()
            else
              _buildTodayFoodList(foodProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.camera_alt,
            size: 120,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            '智能食物识别',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '使用AI技术识别食物并估算热量',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text('拍照识别'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 24),
                  label: const Text('相册选择'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 功能介绍
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(FoodProvider foodProvider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: foodProvider.foodItems.length,
        itemBuilder: (context, index) {
          final foodItem = foodProvider.foodItems[index];
          return FoodCard(
            foodItem: foodItem,
            onTap: () {
              // 显示详情
            },
            onDelete: () async {
              final confirmed = await AppUtils.showConfirmDialog(
                context,
                title: '删除记录',
                content: '确定要删除这条食物记录吗？',
              );
              if (confirmed) {
                foodProvider.deleteFoodRecord(foodItem.id!);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.no_food,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '今日还没有记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮开始记录食物',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('开始识别'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFoodList(FoodProvider foodProvider) {
    final todayItems = foodProvider.todayRecord?.allItems ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayItems.length,
      itemBuilder: (context, index) {
        final foodItem = todayItems[index];
        return FoodCard(
          foodItem: foodItem,
          onTap: () {
            // 显示食物详情
          },
          onDelete: () async {
            final confirmed = await AppUtils.showConfirmDialog(
              context,
              title: '删除记录',
              content: '确定要删除这条食物记录吗？',
            );
            if (confirmed) {
              foodProvider.deleteFoodRecord(foodItem.id!);
            }
          },
        );
      },
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.auto_awesome,
                title: 'AI智能识别',
                description: '基于先进的图像识别技术',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.calculate,
                title: '精确计算',
                description: '准确估算食物热量和营养',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.insert_chart,
                title: '数据统计',
                description: '详细的饮食数据和分析',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.history,
                title: '历史记录',
                description: '完整的饮食历史追踪',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    // 显示设置页面
    AppUtils.showErrorSnackBar(context, '设置页面待实现');
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '食物热量识别',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.restaurant, size: 48),
      children: [
        const Text('基于AI技术的食物热量识别应用，帮助您科学管理饮食健康。'),
      ],
    );
  }
}