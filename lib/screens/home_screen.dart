import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_list_screen.dart';
import 'friends_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import '../services/securet_auth_service.dart';
import '../services/firebase_notification_service.dart';
import '../services/qkey_service.dart';
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasShownLoginBonus = false; // 로그인 보너스 팝업 표시 여부

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
    _checkLoginBonus(); // 로그인 보너스 확인
  }
  
  /// 🎁 로그인 보너스 확인 및 팝업 표시
  Future<void> _checkLoginBonus() async {
    if (_hasShownLoginBonus) return;
    
    // 화면이 완전히 로드된 후 실행
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) return;
      
      // Firestore에서 마지막 로그인 보너스 시간 확인
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 이미 보너스를 받았는지 SharedPreferences로 확인 (중복 팝업 방지)
      final prefs = await SharedPreferences.getInstance();
      final lastPopupDate = prefs.getString('last_login_bonus_popup');
      
      if (lastPopupDate != null) {
        final lastDate = DateTime.parse(lastPopupDate);
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        
        // 오늘 이미 팝업을 표시했으면 skip
        if (lastDay.isAtSameMomentAs(today)) {
          return;
        }
      }
      
      // 보너스를 받았는지 확인 (QKeyService에서 받았음)
      // 실제로 오늘 로그인 보너스를 받았는지 체크
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final lastLoginBonusDate = (userData['lastLoginBonusDate'] as Timestamp?)?.toDate();
      
      if (lastLoginBonusDate != null) {
        final lastBonusDay = DateTime(lastLoginBonusDate.year, lastLoginBonusDate.month, lastLoginBonusDate.day);
        
        // 오늘 로그인 보너스를 받았으면 팝업 표시
        if (lastBonusDay.isAtSameMomentAs(today)) {
          final todayCount = (userData['todayLoginBonusCount'] as int?) ?? 0;
          
          // ⭐ 5회 미만일 때만 팝업 표시 (5/5 달성 시 숨김)
          if (todayCount < QKeyService.loginBonusMaxPerDay) {
            _hasShownLoginBonus = true;
            await prefs.setString('last_login_bonus_popup', now.toIso8601String());
            
            if (mounted) {
              _showLoginBonusSnackBar(todayCount);
            }
          } else {
            // 5회 달성 시 로그
            if (kDebugMode) {
              debugPrint('🎁 오늘 로그인 보너스를 모두 받았습니다 ($todayCount/${QKeyService.loginBonusMaxPerDay})');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 로그인 보너스 확인 실패: $e');
    }
  }
  
  /// 🎉 로그인 보너스 스낵바 표시 + 알림음
  Future<void> _showLoginBonusSnackBar(int count) async {
    // 🔊 알림음 재생
    try {
      debugPrint('🔊 [코인음] 재생 시작...');
      final player = AudioPlayer();
      
      // 음량 설정 (최대)
      await player.setVolume(1.0);
      debugPrint('🔊 [코인음] 볼륨 설정: 1.0');
      
      // 재생 모드 설정
      await player.setReleaseMode(ReleaseMode.stop);
      debugPrint('🔊 [코인음] ReleaseMode 설정: stop');
      
      // 재생
      await player.play(AssetSource('sounds/coin_earn.mp3'));
      debugPrint('🔔 [코인음] 재생 완료 - assets/sounds/coin_earn.mp3');
    } catch (e) {
      debugPrint('⚠️ [코인음] 재생 실패: $e');
      debugPrint('📋 [코인음] 실패 스택트레이스: ${StackTrace.current}');
    }
    
    // 💬 스낵바 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '🎁 로그인 보너스 +${QKeyService.loginBonusAmount} QKEY! ($count/${QKeyService.loginBonusMaxPerDay})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppColors.badge,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
      body: SafeArea(
        child: screens[_currentIndex],
      ),
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
