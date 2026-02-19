import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:auto_updater/auto_updater.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🖥️ Desktop 초기화 (Windows, macOS, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await _initializeDesktop();
  }
  
  // 🔥 Firebase 초기화 (멀티플랫폼 지원)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🔔 알림음 서비스 초기화
  await NotificationService().initialize();
  
  // 📱 FCM 푸시 알림 초기화 (모바일만)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await FirebaseNotificationService.initialize();
  }
  
  // 🔔 로컬 알림 서비스 초기화
  await LocalNotificationService.initialize();
  
  runApp(const QRChatApp());
}

/// 🖥️ Desktop 플랫폼 초기화
Future<void> _initializeDesktop() async {
  // 윈도우 매니저 초기화
  await windowManager.ensureInitialized();
  
  // 패키지 정보 가져오기
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  // 자동 시작 설정
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  
  // 윈도우 옵션 설정 (카카오톡 스타일)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),           // 카카오톡과 비슷한 크기
    minimumSize: Size(800, 600),     // 최소 크기
    center: true,                     // 화면 중앙에 표시
    backgroundColor: Colors.transparent,
    skipTaskbar: false,               // 작업 표시줄에 표시
    titleBarStyle: TitleBarStyle.normal,
    title: 'QRChat',                  // 윈도우 제목
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // 시스템 트레이 초기화
  await _initializeSystemTray();
  
  // 🔄 자동 업데이트 초기화
  await _initializeAutoUpdater();
}

/// 🔄 자동 업데이트 초기화
Future<void> _initializeAutoUpdater() async {
  // 업데이트 피드 URL 설정
  String feedURL = Platform.isWindows
      ? 'https://github.com/Stevewon/qrchat/releases/latest/download/appcast.xml'
      : Platform.isMacOS
          ? 'https://github.com/Stevewon/qrchat/releases/latest/download/appcast.xml'
          : 'https://github.com/Stevewon/qrchat/releases/latest';
  
  await autoUpdater.setFeedURL(feedURL);
  await autoUpdater.setScheduledCheckInterval(3600); // 1시간마다 체크
  await autoUpdater.checkForUpdates();
  
  // 업데이트 이벤트 리스너
  autoUpdater.onUpdateAvailable = ((version) {
    debugPrint('🔄 New version available: $version');
    // TODO: 사용자에게 업데이트 알림 표시
  });
  
  autoUpdater.onUpdateDownloaded = (() {
    debugPrint('✅ Update downloaded, ready to install');
    // TODO: 재시작 프롬프트 표시
  });
  
  autoUpdater.onError = ((error) {
    debugPrint('❌ Update error: $error');
  });
}

/// 🎯 시스템 트레이 초기화 (카카오톡처럼)
Future<void> _initializeSystemTray() async {
  await trayManager.setIcon(
    Platform.isWindows
        ? 'windows/runner/resources/app_icon.ico'
        : 'assets/icon/app_icon.png',
  );
  
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: 'QRChat 열기',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '종료',
      ),
    ],
  );
  
  await trayManager.setContextMenu(menu);
  await trayManager.setToolTip('QRChat');
}

class QRChatApp extends StatelessWidget {
  const QRChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
