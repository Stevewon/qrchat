import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// 모바일에서 URL을 외부 브라우저로 열기
Future<void> openUrlInNewTab(String url) async {
  try {
    final uri = Uri.parse(url);
    
    if (kDebugMode) {
      debugPrint('📱 [URL Launcher] 시도: $url');
      debugPrint('📱 [URL Launcher] URI 스킴: ${uri.scheme}');
      debugPrint('📱 [URL Launcher] URI 호스트: ${uri.host}');
    }
    
    // ⚡ CRITICAL: Securet URL 처리 개선
    // 웹 URL (http/https)은 외부 브라우저로 열기
    // 앱 스킴 (securet://)은 외부 앱으로 열기
    final mode = (uri.scheme == 'http' || uri.scheme == 'https')
        ? LaunchMode.externalApplication  // 브라우저 또는 앱으로 열기
        : LaunchMode.externalApplication;
    
    if (kDebugMode) {
      debugPrint('📱 [URL Launcher] 모드: $mode');
    }
    
    // canLaunchUrl 먼저 확인 (CRITICAL: 디버깅용)
    final canLaunch = await canLaunchUrl(uri);
    if (kDebugMode) {
      debugPrint('📱 [URL Launcher] canLaunch: $canLaunch');
    }
    
    if (!canLaunch) {
      if (kDebugMode) {
        debugPrint('❌ [URL Launcher] canLaunchUrl 실패: URL을 처리할 앱이 없습니다');
      }
      throw Exception('URL을 처리할 앱이 설치되어 있지 않습니다.\n\nSecuret 앱을 설치해 주세요.');
    }
    
    // launchUrl 시도
    final launched = await launchUrl(
      uri,
      mode: mode,
    );
    
    if (!launched) {
      if (kDebugMode) {
        debugPrint('❌ [URL Launcher] launchUrl 실패: $url');
      }
      throw Exception('URL을 열 수 없습니다');
    } else {
      if (kDebugMode) {
        debugPrint('✅ [URL Launcher] 성공: $url');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ [URL Launcher] 예외: $e');
    }
    rethrow;
  }
}

