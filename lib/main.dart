import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Firebase 초기화 (멀티플랫폼 지원)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🔔 알림음 서비스 초기화
  await NotificationService().initialize();
  
  // 📱 FCM 푸시 알림 초기화
  await FirebaseNotificationService.initialize();
  
  // 🔔 로컬 알림 서비스 초기화 (포그라운드 알림)
  await LocalNotificationService.initialize();
  
  runApp(const QRChatApp());
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
