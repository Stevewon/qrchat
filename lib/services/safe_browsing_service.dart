import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Google Safe Browsing API를 사용하여 유해 URL 검사
/// API 키가 없으면 로컬 블랙리스트만 사용
class SafeBrowsingService {
  // Google Safe Browsing API 키 (프로덕션에서는 환경 변수로 관리)
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _apiEndpoint = 'https://safebrowsing.googleapis.com/v4/threatMatches:find';
  
  // 로컬 블랙리스트 (API 없이도 기본 차단)
  static const List<String> _localBlockedDomains = [
    'malicious.com',
    'phishing.com',
    'scam.com',
    // 추가 도메인은 여기에 추가
  ];

  /// URL이 안전한지 확인
  /// 반환값: true = 안전함, false = 유해함
  static Future<bool> isUrlSafe(String url) async {
    try {
      // 1. 로컬 블랙리스트 검사
      if (_isInLocalBlacklist(url)) {
        if (kDebugMode) {
          debugPrint('🚫 로컬 블랙리스트에서 차단: $url');
        }
        return false;
      }

      // 2. API 키가 설정되지 않았으면 로컬 검사만 사용
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        if (kDebugMode) {
          debugPrint('⚠️ Safe Browsing API 키 미설정 - 로컬 블랙리스트만 사용');
        }
        return true; // 로컬 블랙리스트 통과하면 안전으로 간주
      }

      // 3. Google Safe Browsing API로 검사
      final response = await http.post(
        Uri.parse('$_apiEndpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client': {
            'clientId': 'qrchat',
            'clientVersion': '9.8.1',
          },
          'threatInfo': {
            'threatTypes': [
              'MALWARE',
              'SOCIAL_ENGINEERING',
              'UNWANTED_SOFTWARE',
              'POTENTIALLY_HARMFUL_APPLICATION',
            ],
            'platformTypes': ['ANY_PLATFORM'],
            'threatEntryTypes': ['URL'],
            'threatEntries': [
              {'url': url}
            ],
          },
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 위협이 발견되지 않으면 안전
        if (data['matches'] == null || (data['matches'] as List).isEmpty) {
          if (kDebugMode) {
            debugPrint('✅ 안전한 URL: $url');
          }
          return true;
        }

        // 위협 발견
        if (kDebugMode) {
          debugPrint('🚫 유해 URL 감지: $url');
          debugPrint('위협 유형: ${data['matches']}');
        }
        return false;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Safe Browsing API 오류: ${response.statusCode}');
        }
        // API 오류 시 로컬 블랙리스트만 신뢰
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Safe Browsing 검사 실패: $e');
      }
      // 오류 시 안전한 쪽으로 처리 (사용자 경험 우선)
      return true;
    }
  }

  /// 로컬 블랙리스트 검사
  static bool _isInLocalBlacklist(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final domain = uri.host.toLowerCase();
    
    // 정확한 도메인 매칭
    for (final blocked in _localBlockedDomains) {
      if (domain == blocked || domain.endsWith('.$blocked')) {
        return true;
      }
    }
    
    return false;
  }

  /// 유해 URL 경고 다이얼로그용 메시지
  static String getBlockedUrlMessage(String url) {
    return '⚠️ 이 링크는 Google에서 유해한 사이트로 지정되어 차단되었습니다.\n\n'
        '보안을 위해 접속을 권장하지 않습니다.';
  }
}
