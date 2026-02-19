// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 웹에서 URL을 새 탭에서 열기
Future<void> openUrlInNewTab(String url) async {
  html.window.open(url, '_blank');
}

