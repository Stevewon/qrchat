import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'friends_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import '../services/securet_auth_service.dart';
import '../services/firebase_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
  }

  /// ⭐ 실시간 알림 트리거 리스너 시작
  Future<void> _startNotificationListener() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (user != null) {
      FirebaseNotificationService.listenToNotificationTriggers(user.id);
    }
  }

  void _navigateToFriendsTab() {
    setState(() {
      _currentIndex = 0; // 친구 탭으로 전환 (첫 번째 탭)
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const FriendsListScreen(), // 1️⃣ 친구 (카카오톡 스타일)
      const ChatListScreen(),     // 2️⃣ 채팅
      QRScannerScreen(
        onFriendAdded: _navigateToFriendsTab,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '친구',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'QR 스캔',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
