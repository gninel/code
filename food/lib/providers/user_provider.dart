import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _nickname = '用户昵称';
  int _dailyCalorieGoal = 2000;
  String _unitPreference = 'kcal_kg'; // kcal_kg 或 cal_lb
  Locale _locale = const Locale('zh');

  String get nickname => _nickname;
  int get dailyCalorieGoal => _dailyCalorieGoal;
  String get unitPreference => _unitPreference;
  Locale get locale => _locale;

  UserProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = prefs.getString('nickname') ?? '用户昵称';
    _dailyCalorieGoal = prefs.getInt('dailyCalorieGoal') ?? 2000;
    _unitPreference = prefs.getString('unitPreference') ?? 'kcal_kg';
    final languageCode = prefs.getString('languageCode') ?? 'zh';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> updateNickname(String newNickname) async {
    _nickname = newNickname;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nickname);
    notifyListeners();
  }

  Future<void> updateDailyCalorieGoal(int newGoal) async {
    _dailyCalorieGoal = newGoal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyCalorieGoal', _dailyCalorieGoal);
    notifyListeners();
  }

  Future<void> updateUnitPreference(String newUnit) async {
    _unitPreference = newUnit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unitPreference', _unitPreference);
    notifyListeners();
  }

  Future<void> updateLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
}
