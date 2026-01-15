import 'package:flutter/material.dart';
import 'camera_home_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import '../app.dart';
import '../l10n/app_localizations.dart';

/// 主导航页面 - 底部导航栏
class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // 三个主页面
  final List<Widget> _pages = [
    const CameraHomeScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 延迟一帧以确保 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializer.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: l10n.get('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment),
            label: l10n.get('statistics'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.get('profile'),
          ),
        ],
      ),
    );
  }
}
