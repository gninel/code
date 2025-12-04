import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      // 应用基础
      'app_name': '识食君',
      'home': '首页',
      'statistics': '热量分析',
      'profile': '个人中心',
      
      // 导航和标题
      'camera_home': '拍照记录',
      'take_photo': '拍照识别',
      'select_from_gallery': '从相册选择',
      'recognition_result': '识别结果',
      'edit_record': '编辑记录',
      
      // 个人中心
      'nickname': '用户昵称',
      'daily_target': '每日目标热量',
      'unit_preference': '单位偏好',
      'language': '语言',
      'health_settings': '健康设置',
      'data_management': '数据管理',
      'about': '关于',
      'export_data': '导出数据',
      'clear_data': '清除所有数据',
      'about_app': '关于应用',
      'privacy_policy': '隐私政策',
      
      // 操作按钮
      'edit_nickname': '修改昵称',
      'enter_nickname': '请输入新昵称',
      'cancel': '取消',
      'save': '保存',
      'confirm': '确定',
      'delete': '删除',
      'update_record': '更新记录',
      'save_record': '保存记录',
      
      // 设置相关
      'set_daily_goal': '设置每日目标热量',
      'kcal': '千卡',
      'example_2000': '例如：2000',
      'clear_data_title': '清除所有数据',
      'clear_data_warning': '确定要清除所有食物记录吗？此操作将删除所有历史记录和图片，且无法撤销。',
      'clear_confirm': '确定清除',
      'data_cleared': '数据已清除',
      'clear_failed': '清除失败',
      'chinese': '简体中文',
      'english': 'English',
      'kcal_kg': '千卡 / 公斤',
      'cal_lb': '卡路里 / 磅',
      'developing': '功能开发中...',
      'only_kcal_kg': '暂只支持千卡/公斤',
      
      // 统计页面
      'this_week': '本周',
      'this_month': '本月',
      'all': '全部',
      'average_per_day': '平均热量/天',
      'total': '总计',
      'this_week_total': '本周总计',
      'this_month_total': '本月总计',
      'this_period_total': '本期总计',
      'calorie_trend': '热量趋势',
      'this_week_records': '本周记录',
      'this_month_records': '本月记录',
      'detailed_records': '详细记录',
      'no_records': '暂无符合条件的记录',
      
      // 食物信息
      'food_name': '食物名称',
      'ingredients': '主要成分',
      'calories': '热量',
      'weight': '重量',
      'meal_type': '餐次',
      'breakfast': '早餐',
      'lunch': '午餐',
      'dinner': '晚餐',
      'other': '其他',
      'nutrition_info': '营养信息',
      'confidence': '识别置信度',
      
      // 日期时间
      'today': '今天',
      'yesterday': '昨天',
      'tomorrow': '明天',
      'monday': '周一',
      'tuesday': '周二',
      'wednesday': '周三',
      'thursday': '周四',
      'friday': '周五',
      'saturday': '周六',
      'sunday': '周日',
      
      // 提示信息
      'loading': '加载中...',
      'recognizing': '正在识别...',
      'please_wait': '请稍候',
      'recognition_success': '识别成功',
      'recognition_failed': '识别失败',
      'save_success': '保存成功',
      'save_failed': '保存失败',
      'delete_confirm': '确定要删除这条食物记录吗？',
      'delete_record': '删除记录',
      
      // 相机相关
      'camera': '相机',
      'retake': '重新拍摄',
      'use_this_photo': '使用照片',
      'camera_permission_denied': '相机权限被拒绝',
      'storage_permission_denied': '存储权限被拒绝',
      
      // 其他
      'adjusted': '已调整',
      'gram': '克',
      'low_calorie': '低热量',
      'medium_calorie': '中等热量',
      'high_calorie': '高热量',
      
      // 识别过程
      'recognizing_food': '正在识别食物，请稍候...',
      'ai_result': 'AI 智能识别结果',
      'calorie_density': '热量密度',
      'kcal_per_100g': '千卡/100g',
      'tags': '标签',
      'main_ingredients': '主要成分',
      'total_ingredients': '共 {count} 种成分',
      
      // 结果页面
      'select_meal': '选择餐次',
      'detail_info': '详细信息',
      'rerecognize': '重新识别',
      'saving': '保存中...',
      'no_image': '无图片',
      'image_load_failed': '图片加载失败',
      'record_saved': '记录已保存',
      'record_updated': '记录已更新',
      'update_failed': '更新失败',
      'operation_failed': '操作失败',
      
      // 编辑对话框
      'edit_food_info': '编辑食物信息',
      'edit_weight': '编辑重量',
      'enter_weight': '请输入实际重量（克）：',
      'weight_hint': '例：250.0',
      'weight_calc_hint': '修改重量会自动计算热量',
      'calorie_recalc_hint': '● 总热量将自动按热量密度重新计算',
      'enter_valid_weight': '请输入有效的重量',
      'info_updated': '信息已更新，请点击底部按钮保存',
      'weight_updated': '重量已更新为{weight}克，总热量已调整为{calories}千卡',
      'no_result': '没有识别结果',
      'density_abnormal_adjusted': '原始数据（{weight}g）热量密度异常，已自动调整',
      'no_data': '暂无数据',
      'month_1': '1月',
      'month_2': '2月',
      'month_3': '3月',
      'month_4': '4月',
      'month_5': '5月',
      'month_6': '6月',
      'month_7': '7月',
      'month_8': '8月',
      'month_9': '9月',
      'month_10': '10月',
      'month_11': '11月',
      'month_12': '12月',
    },
    'en': {
      // App basics
      'app_name': 'Food Calorie',
      'home': 'Home',
      'statistics': 'Statistics',
      'profile': 'Profile',
      
      // Navigation and titles
      'camera_home': 'Camera Home',
      'take_photo': 'Take Photo',
      'select_from_gallery': 'From Gallery',
      'recognition_result': 'Result',
      'edit_record': 'Edit Record',
      
      // Profile
      'nickname': 'Nickname',
      'daily_target': 'Daily Calorie Goal',
      'unit_preference': 'Unit Preference',
      'language': 'Language',
      'health_settings': 'Health Settings',
      'data_management': 'Data Management',
      'about': 'About',
      'export_data': 'Export Data',
      'clear_data': 'Clear All Data',
      'about_app': 'About App',
      'privacy_policy': 'Privacy Policy',
      
      // Action buttons
      'edit_nickname': 'Edit Nickname',
      'enter_nickname': 'Enter new nickname',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'update_record': 'Update Record',
      'save_record': 'Save Record',
      
      // Settings
      'set_daily_goal': 'Set Daily Calorie Goal',
      'kcal': 'kcal',
      'example_2000': 'e.g., 2000',
      'clear_data_title': 'Clear All Data',
      'clear_data_warning':
          'Are you sure to clear all food records? This will delete all history and images permanently.',
      'clear_confirm': 'Clear',
      'data_cleared': 'Data cleared',
      'clear_failed': 'Failed to clear',
      'chinese': '简体中文',
      'english': 'English',
      'kcal_kg': 'kcal / kg',
      'cal_lb': 'cal / lb',
      'developing': 'Coming soon...',
      'only_kcal_kg': 'Only kcal/kg supported',
      
      // Statistics page
      'this_week': 'This Week',
      'this_month': 'This Month',
      'all': 'All',
      'average_per_day': 'Avg/Day',
      'total': 'Total',
      'this_week_total': 'Week Total',
      'this_month_total': 'Month Total',
      'this_period_total': 'Total',
      'calorie_trend': 'Calorie Trend',
      'this_week_records': 'This Week',
      'this_month_records': 'This Month',
      'detailed_records': 'Records',
      'no_records': 'No records found',
      
      // Food information
      'food_name': 'Food Name',
      'ingredients': 'Ingredients',
      'calories': 'Calories',
      'weight': 'Weight',
      'meal_type': 'Meal',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'other': 'Other',
      'nutrition_info': 'Nutrition',
      'confidence': 'Confidence',
      
      // Date and time
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
      
      // Messages
      'loading': 'Loading...',
      'recognizing': 'Recognizing...',
      'please_wait': 'Please wait',
      'recognition_success': 'Success',
      'recognition_failed': 'Failed',
      'save_success': 'Saved',
      'save_failed': 'Save failed',
      'delete_confirm': 'Delete this record?',
      'delete_record': 'Delete Record',
      
      // Camera
      'camera': 'Camera',
      'retake': 'Retake',
      'use_this_photo': 'Use Photo',
      'camera_permission_denied': 'Camera permission denied',
      'storage_permission_denied': 'Storage permission denied',
      
      // Others
      'adjusted': 'Adjusted',
      'gram': 'g',
      'low_calorie': 'Low',
      'medium_calorie': 'Medium',
      'high_calorie': 'High',
      
      // Recognition process
      'recognizing_food': 'Recognizing food, please wait...',
      'ai_result': 'AI Recognition Result',
      'calorie_density': 'Calorie Density',
      'kcal_per_100g': 'kcal/100g',
      'tags': 'Tags',
      'main_ingredients': 'Main Ingredients',
      'total_ingredients': '{count} ingredients total',
      
      // Result page
      'select_meal': 'Select Meal',
      'detail_info': 'Details',
      'rerecognize': 'Retry',
      'saving': 'Saving...',
      'no_image': 'No Image',
      'image_load_failed': 'Image load failed',
      'record_saved': 'Record saved',
      'record_updated': 'Record updated',
      'update_failed': 'Update failed',
      'operation_failed': 'Operation failed',
      
      // Edit dialogs
      'edit_food_info': 'Edit Food Info',
      'edit_weight': 'Edit Weight',
      'enter_weight': 'Enter actual weight (grams):',
      'weight_hint': 'e.g., 250.0',
      'weight_calc_hint': 'Changing weight will auto-calc calories',
      'calorie_recalc_hint': '● Calories will be recalculated by density',
      'enter_valid_weight': 'Please enter a valid weight',
      'info_updated': 'Info updated, tap bottom button to save',
      'weight_updated': 'Weight updated to {weight}g, calories adjusted to {calories} kcal',
      'no_result': 'No result',
      'density_abnormal_adjusted': 'Original ({weight}g) had abnormal density, auto-adjusted',
      'no_data': 'No Data',
      'month_1': 'Jan',
      'month_2': 'Feb',
      'month_3': 'Mar',
      'month_4': 'Apr',
      'month_5': 'May',
      'month_6': 'Jun',
      'month_7': 'Jul',
      'month_8': 'Aug',
      'month_9': 'Sep',
      'month_10': 'Oct',
      'month_11': 'Nov',
      'month_12': 'Dec',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
