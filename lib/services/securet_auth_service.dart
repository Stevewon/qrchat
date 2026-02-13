import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/securet_user.dart';
import 'firebase_notification_service.dart';
import 'app_badge_service.dart';

/// Securet 인증 서비스
/// 
/// QR 코드 기반 회원가입 및 닉네임/비밀번호 기반 로그인을 지원합니다.
/// 
/// 주요 기능:
/// - QR 코드 스캔을 통한 회원가입
/// - Firebase Firestore 기반 사용자 저장
/// - 닉네임 + 비밀번호 로그인
/// - 멀티 디바이스 로그인 지원
/// - 자동 로그인 (SharedPreferences)
class SecuretAuthService {
  // SharedPreferences keys
  static const String _keySecuretUser = 'securet_user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Firebase friend service for profile management
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if Securet URL is valid
  static bool isValidSecuretUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check domain contains 'securet.kr'
      if (!uri.host.contains('securet.kr')) {
        return false;
      }
      
      // Check required parameters exist
      final hasKey = uri.queryParameters.containsKey('key');
      final hasToken = uri.queryParameters.containsKey('token');
      
      return hasKey && hasToken;
    } catch (e) {
      return false;
    }
  }

  // Register with Securet QR code
  static Future<bool> registerWithSecuret(String qrUrl, String nickname, String password) async {
    // Validate inputs
    if (!isValidSecuretUrl(qrUrl) || nickname.isEmpty || password.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ 유효하지 않은 입력 데이터');
      }
      return false;
    }

    try {
      // Check if this QR code is banned
      final bannedUsersSnapshot = await _firestore
          .collection('users')
          .where('bannedQrCode', isEqualTo: qrUrl)
          .limit(1)
          .get();
      
      if (bannedUsersSnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🚫 차단된 QR 코드입니다!');
        }
        throw Exception('🚫 차단된 QR 코드입니다\n\n이 QR 코드로는 가입할 수 없습니다.\n차단된 계정의 QR 코드입니다.\n\n문의: 관리자에게 연락해주세요.');
      }

      final uri = Uri.parse(qrUrl);
      final token = uri.queryParameters['token'] ?? '';
      final voip = uri.queryParameters['voip'] ?? '';
      
      // Create user object
      final user = SecuretUser.fromQRUrl(qrUrl, nickname, password)!;
      
      // Save to SharedPreferences (local)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySecuretUser, jsonEncode(user.toMap()));
      await prefs.setBool(_keyIsLoggedIn, true);
      
      // Register user in Firebase Firestore
      try {
        await _firestore.collection('users').doc(user.id).set({
          'id': user.id,
          'qrUrl': qrUrl,
          'qrCodeUrl': qrUrl,  // For consistency with ban check
          'nickname': nickname,
          'password': password,  // 멀티 디바이스 로그인을 위해 저장
          'token': token,
          'voip': voip,
          'os': 'android',
          'registeredAt': FieldValue.serverTimestamp(),
          'profilePhoto': '',
          'banned': false,  // Default to not banned
        }, SetOptions(merge: true));
        
        if (kDebugMode) {
          debugPrint('✅ Firestore에 사용자 등록 완료: $nickname');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Firestore 등록 실패 (로컬 저장은 완료됨): $e');
        }
        // Firestore 실패해도 로컬 저장은 되었으므로 회원가입은 성공으로 처리
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 회원가입 오류: $e');
      }
      rethrow;  // Throw the exception so UI can show the error message
    }
  }

  // Login with nickname + password - SUPER SIMPLIFIED
  static Future<bool> login(String nickname, String password) async {
    if (nickname.isEmpty || password.isEmpty) {
      throw Exception('닉네임과 비밀번호를 입력해주세요');
    }

    try {
      if (kDebugMode) {
        debugPrint('\n🔑 ========== 로그인 시도 ==========');
        debugPrint('👤 닉네임: "$nickname"');
        debugPrint('🔒 비밀번호: "$password"');
      }
      
      // Firestore에서 사용자 찾기 (ONLY SOURCE)
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ 사용자를 찾을 수 없습니다');
        }
        throw Exception('사용자를 찾을 수 없습니다. 회원가입을 먼저 진행해주세요.');
      }

      final doc = querySnapshot.docs.first;
      final userData = doc.data();
      final storedPassword = userData['password'] ?? '';
      final isBanned = userData['banned'] == true;
      
      if (kDebugMode) {
        debugPrint('✅ 사용자 발견!');
        debugPrint('🔍 비밀번호 확인:');
        debugPrint('   입력값: "$password"');
        debugPrint('   저장값: "$storedPassword"');
        debugPrint('   일치: ${storedPassword == password}');
        debugPrint('   차단 상태: $isBanned');
      }

      // 차단 여부 확인
      if (isBanned) {
        if (kDebugMode) {
          debugPrint('🚫 차단된 사용자입니다!');
        }
        throw Exception('🚫 차단된 계정입니다\n\n관리자에 의해 차단되었습니다.\n차단 해제 전까지 로그인할 수 없습니다.\n\n문의: 관리자에게 연락해주세요.');
      }

      // 비밀번호 확인
      if (storedPassword != password) {
        if (kDebugMode) {
          debugPrint('❌ 비밀번호가 일치하지 않습니다!');
        }
        throw Exception('비밀번호가 일치하지 않습니다');
      }

      // 로그인 성공! 로컬에 저장
      final user = SecuretUser(
        id: userData['id'] ?? '',
        qrUrl: userData['qrUrl'] ?? '',
        nickname: userData['nickname'] ?? '',
        password: userData['password'] ?? '',
        token: userData['token'] ?? '',
        voip: userData['voip'] ?? '',
        os: userData['os'] ?? 'android',
        registeredAt: userData['registeredAt'] != null 
            ? (userData['registeredAt'] as Timestamp).toDate()
            : DateTime.now(),
        profilePhoto: userData['profilePhoto'] ?? '',
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySecuretUser, jsonEncode(user.toMap()));
      await prefs.setBool(_keyIsLoggedIn, true);
      
      if (kDebugMode) {
        debugPrint('✅✅✅ 로그인 성공! ✅✅✅');
        debugPrint('========== 로그인 완료 ==========\n');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌❌❌ 로그인 실패 ❌❌❌');
        debugPrint('에러: $e');
        debugPrint('========== 로그인 종료 ==========\n');
      }
      rethrow;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current Securet user
  static Future<SecuretUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keySecuretUser);
    
    if (userData == null) {
      return null;
    }

    try {
      final userMap = jsonDecode(userData) as Map<String, dynamic>;
      return SecuretUser.fromMap(userMap);
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    // 📱 FCM 토큰 제거 (로그아웃 시)
    try {
      await FirebaseNotificationService.clearFCMToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ FCM 토큰 제거 실패: $e');
      }
    }
    
    // 📛 앱 배지 제거 (로그아웃 시)
    try {
      await AppBadgeService.removeBadge();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 앱 배지 제거 실패: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // 모든 데이터 삭제
    
    if (kDebugMode) {
      debugPrint('✅ 로그아웃 완료 - 모든 로컬 데이터 삭제됨');
    }
  }

  /// 회원탈퇴 (카카오톡 스타일)
  /// 
  /// Firebase에서 사용자 데이터를 완전히 삭제합니다:
  /// 1. users 컬렉션에서 사용자 문서 삭제
  /// 2. 참여 중인 모든 채팅방에서 제거
  /// 3. 친구 관계 정리
  /// 4. FCM 토큰 제거
  /// 5. 로컬 데이터 삭제
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'message': '로그인된 사용자가 없습니다',
        };
      }

      final userId = currentUser.id;
      
      if (kDebugMode) {
        debugPrint('🗑️ [회원탈퇴] 시작: $userId');
      }

      // 1. 참여 중인 모든 채팅방 조회 및 나가기
      try {
        final chatRoomsSnapshot = await _firestore
            .collection('chat_rooms')
            .where('participantIds', arrayContains: userId)
            .get();

        if (kDebugMode) {
          debugPrint('🗑️ [회원탈퇴] 참여 중인 채팅방: ${chatRoomsSnapshot.docs.length}개');
        }

        for (var chatRoomDoc in chatRoomsSnapshot.docs) {
          final chatRoomData = chatRoomDoc.data();
          final participantIds = List<String>.from(chatRoomData['participantIds'] ?? []);
          
          // 채팅방에서 사용자 제거
          participantIds.remove(userId);
          
          if (participantIds.isEmpty) {
            // 마지막 참여자면 채팅방 삭제
            await chatRoomDoc.reference.delete();
            if (kDebugMode) {
              debugPrint('   채팅방 삭제: ${chatRoomDoc.id}');
            }
          } else {
            // 다른 참여자가 있으면 나만 제거
            await chatRoomDoc.reference.update({
              'participantIds': participantIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            if (kDebugMode) {
              debugPrint('   채팅방에서 나가기: ${chatRoomDoc.id}');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [회원탈퇴] 채팅방 정리 실패: $e');
        }
      }

      // 2. 친구 관계 정리 (나를 친구로 추가한 다른 사용자들)
      try {
        final friendsSnapshot = await _firestore
            .collection('friends')
            .where('friendId', isEqualTo: userId)
            .get();

        if (kDebugMode) {
          debugPrint('🗑️ [회원탈퇴] 친구 관계 정리: ${friendsSnapshot.docs.length}개');
        }

        for (var friendDoc in friendsSnapshot.docs) {
          await friendDoc.reference.delete();
        }

        // 내가 추가한 친구 관계도 삭제
        final myFriendsSnapshot = await _firestore
            .collection('friends')
            .where('userId', isEqualTo: userId)
            .get();

        for (var friendDoc in myFriendsSnapshot.docs) {
          await friendDoc.reference.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [회원탈퇴] 친구 관계 정리 실패: $e');
        }
      }

      // 3. FCM 토큰 제거
      try {
        await FirebaseNotificationService.clearFCMToken();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [회원탈퇴] FCM 토큰 제거 실패: $e');
        }
      }

      // 4. 앱 배지 제거
      try {
        await AppBadgeService.removeBadge();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [회원탈퇴] 앱 배지 제거 실패: $e');
        }
      }

      // 5. users 컬렉션에서 사용자 문서 삭제
      await _firestore.collection('users').doc(userId).delete();
      
      if (kDebugMode) {
        debugPrint('✅ [회원탈퇴] users 컬렉션에서 삭제 완료');
      }

      // 6. 로컬 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (kDebugMode) {
        debugPrint('✅ [회원탈퇴] 완료 - 모든 데이터 삭제됨');
      }

      return {
        'success': true,
        'message': '회원탈퇴가 완료되었습니다',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [회원탈퇴] 실패: $e');
      }
      return {
        'success': false,
        'message': '회원탈퇴 중 오류가 발생했습니다: $e',
      };
    }
  }

  /// Save user to SharedPreferences (사용자 정보 로컬 저장)
  /// 프로필 사진 업데이트 등 사용자 정보가 변경되었을 때 호출
  static Future<void> saveUser(SecuretUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySecuretUser, jsonEncode(user.toMap()));
      await prefs.setBool(_keyIsLoggedIn, true);
      
      if (kDebugMode) {
        debugPrint('✅ [SecuretAuthService] 사용자 정보 SharedPreferences 저장 완료');
        debugPrint('   - User ID: ${user.id}');
        debugPrint('   - Nickname: ${user.nickname}');
        debugPrint('   - Profile Photo: ${user.profilePhoto ?? "없음"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [SecuretAuthService] 사용자 정보 저장 실패: $e');
      }
      rethrow;
    }
  }

  // Get Securet API base URL
  static String getSecuretApiUrl() {
    return 'https://securet.kr/securet.php';
  }
}
