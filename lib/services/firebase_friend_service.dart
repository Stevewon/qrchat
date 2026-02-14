import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/securet_user.dart';
import '../models/friend_request.dart';
import '../models/friend.dart';

/// 카카오톡 스타일 친구 관리 서비스
/// 
/// 주요 기능:
/// - 닉네임으로 친구 검색 (정확히 일치)
/// - 친구 요청 전송
/// - 친구 요청 수락/거절
/// - 친구 목록 조회
class FirebaseFriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore 컬렉션 참조
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _friendRequestsCollection =>
      _firestore.collection('friend_requests');
  CollectionReference get _friendsCollection => _firestore.collection('friends');

  /// 사용자 등록 (회원가입 시)
  Future<void> registerUser(SecuretUser user) async {
    try {
      await _usersCollection.doc(user.id).set({
        'id': user.id,
        'nickname': user.nickname,
        'password': user.password,
        'qrUrl': user.qrUrl,
        'token': user.token,
        'os': user.os,
        'voip': user.voip,
        'registeredAt': FieldValue.serverTimestamp(),
        'profilePhoto': user.profilePhoto ?? '',
      });
      
      if (kDebugMode) {
        debugPrint('✅ 사용자 등록 완료: ${user.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 사용자 등록 실패: $e');
      }
      rethrow;
    }
  }

  /// 전체 사용자 목록 조회 (QR Scanner용)
  Future<List<SecuretUser>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SecuretUser(
          id: data['id'] ?? doc.id,
          qrUrl: data['qrUrl'] ?? '',
          nickname: data['nickname'] ?? '',
          password: '',
          token: data['token'] ?? '',
          os: data['os'] ?? 'android',
          registeredAt: data['registeredAt'] != null
              ? (data['registeredAt'] as Timestamp).toDate()
              : DateTime.now(),
          voip: data['voip'],
          profilePhoto: data['profilePhoto'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 전체 사용자 조회 실패: $e');
      }
      rethrow;
    }
  }

  /// ID로 사용자 조회
  Future<SecuretUser?> getUserById(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n🔍 [getUserById] 사용자 조회 시작');
        debugPrint('   userId: $userId');
      }
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ 사용자를 찾을 수 없습니다: $userId');
        }
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      if (kDebugMode) {
        debugPrint('✅ [getUserById] 사용자 문서 조회 성공');
        debugPrint('   닉네임: ${data['nickname']}');
        debugPrint('   qrUrl 존재: ${data.containsKey('qrUrl')}');
        debugPrint('   qrUrl 값: ${data['qrUrl']}');
        debugPrint('   qrUrl 타입: ${data['qrUrl']?.runtimeType}');
        debugPrint('   전체 필드: ${data.keys.toList()}');
      }
      
      return SecuretUser(
        id: data['id'] ?? doc.id,
        qrUrl: data['qrUrl'] ?? '',
        nickname: data['nickname'] ?? '',
        password: '',
        token: data['token'] ?? '',
        os: data['os'] ?? 'android',
        registeredAt: data['registeredAt'] != null
            ? (data['registeredAt'] as Timestamp).toDate()
            : DateTime.now(),
        voip: data['voip'],
        profilePhoto: data['profilePhoto'],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 사용자 조회 실패: $e');
      }
      return null;
    }
  }
  /// 닉네임으로 사용자 검색 (카카오톡 스타일 - 정확히 일치하는 사용자만)
  Future<SecuretUser?> searchUserByNickname(String nickname, String currentUserId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n🔍 ========== 친구 검색 ==========');
        debugPrint('검색할 닉네임: "$nickname"');
        debugPrint('현재 사용자 ID: $currentUserId');
      }
      
      if (nickname.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ 검색어가 비어있습니다');
        }
        return null;
      }

      // Firestore에서 정확히 일치하는 닉네임 검색
      final querySnapshot = await _usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (kDebugMode) {
        debugPrint('📊 검색 결과: ${querySnapshot.docs.length}명');
      }

      if (querySnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ "$nickname" 사용자를 찾을 수 없습니다');
        }
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['id'] ?? doc.id;
      
      // 자기 자신은 제외
      if (userId == currentUserId) {
        if (kDebugMode) {
          debugPrint('⚠️ 본인은 친구 추가할 수 없습니다');
        }
        return null;
      }

      final user = SecuretUser(
        id: userId,
        qrUrl: data['qrUrl'] ?? '',
        nickname: data['nickname'] ?? '',
        password: '',
        token: data['token'] ?? '',
        os: data['os'] ?? 'android',
        registeredAt: data['registeredAt'] != null
            ? (data['registeredAt'] as Timestamp).toDate()
            : DateTime.now(),
        voip: data['voip'],
        profilePhoto: data['profilePhoto'],
      );

      if (kDebugMode) {
        debugPrint('✅ 사용자 발견: ${user.nickname} (ID: ${user.id})');
        debugPrint('========== 검색 완료 ==========\n');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 검색 실패: $e');
      }
      rethrow;
    }
  }

  /// 닉네임으로 여러 사용자 검색 (부분 일치) - 실시간 검색용
  Future<List<SecuretUser>> searchUsersByNickname(String query, String currentUserId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n🔍 ========== 실시간 친구 검색 ==========');
        debugPrint('검색어: "$query"');
        debugPrint('현재 사용자 ID: $currentUserId');
      }
      
      if (query.isEmpty) {
        return [];
      }

      // Firestore는 부분 일치 검색을 직접 지원하지 않으므로
      // 모든 사용자를 가져와서 클라이언트에서 필터링
      final querySnapshot = await _usersCollection.get();

      final results = <SecuretUser>[];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['id'] ?? doc.id;
        final nickname = data['nickname'] ?? '';
        
        // 자기 자신 제외
        if (userId == currentUserId) {
          continue;
        }
        
        // 닉네임에 검색어가 포함되어 있는지 확인 (대소문자 구분 없음)
        if (nickname.toLowerCase().contains(query.toLowerCase())) {
          final user = SecuretUser(
            id: userId,
            qrUrl: data['qrUrl'] ?? '',
            nickname: nickname,
            password: '',
            token: data['token'] ?? '',
            os: data['os'] ?? 'android',
            registeredAt: data['registeredAt'] != null
                ? (data['registeredAt'] as Timestamp).toDate()
                : DateTime.now(),
            voip: data['voip'],
            profilePhoto: data['profilePhoto'],
          );
          results.add(user);
        }
      }

      if (kDebugMode) {
        debugPrint('📊 검색 결과: ${results.length}명');
        for (var user in results) {
          debugPrint('   - ${user.nickname}');
        }
        debugPrint('========== 검색 완료 ==========\n');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 검색 실패: $e');
      }
      rethrow;
    }
  }

  /// 친구 요청 전송
  Future<void> sendFriendRequest(
    String fromUserId,
    String fromUserNickname,
    String toUserId,
    String toUserNickname,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('\n📤 ========== 친구 요청 전송 ==========');
        debugPrint('보내는 사람: $fromUserNickname ($fromUserId)');
        debugPrint('받는 사람: $toUserNickname ($toUserId)');
      }
      
      // 1. 이미 친구인지 확인
      final friendCheck = await _friendsCollection
          .where('userId', isEqualTo: fromUserId)
          .where('friendId', isEqualTo: toUserId)
          .get();

      if (friendCheck.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ 이미 친구입니다');
        }
        throw Exception('이미 친구입니다');
      }

      // 2. 중복 요청 확인
      final requestCheck = await _friendRequestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (requestCheck.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ 이미 친구 요청을 보냈습니다');
        }
        throw Exception('이미 친구 요청을 보냈습니다');
      }

      // 3. 친구 요청 생성
      final requestId = '${fromUserId}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _friendRequestsCollection.doc(requestId).set({
        'id': requestId,
        'fromUserId': fromUserId,
        'fromUserNickname': fromUserNickname,
        'toUserId': toUserId,
        'toUserNickname': toUserNickname,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ 친구 요청 전송 완료!');
        debugPrint('요청 ID: $requestId');
        debugPrint('========== 전송 완료 ==========\n');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 전송 실패: $e');
      }
      rethrow;
    }
  }

  /// 받은 친구 요청 목록 조회 (실시간 스트림)
  Stream<List<FriendRequest>> getFriendRequestsStream(String userId) {
    if (kDebugMode) {
      debugPrint('📡 친구 요청 스트림 시작: $userId');
    }
    
    return _friendRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      if (kDebugMode) {
        debugPrint('📨 친구 요청 업데이트: ${snapshot.docs.length}건');
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        return FriendRequest(
          id: data['id'] ?? doc.id,
          fromUserId: data['fromUserId'] ?? '',
          fromUserNickname: data['fromUserNickname'] ?? '',
          toUserId: data['toUserId'] ?? '',
          toUserNickname: data['toUserNickname'] ?? '',
          status: FriendRequestStatus.pending,
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          respondedAt: data['respondedAt'] != null
              ? (data['respondedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    });
  }

  /// 친구 요청 수락
  /// QR 스캔 시 자동으로 친구 추가 (양방향)
  Future<void> addFriend(
    String userId,
    String userNickname,
    String friendId,
    String friendNickname,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('\n✅ ========== QR 자동 친구 추가 ==========');
        debugPrint('사용자: $userNickname ($userId)');
        debugPrint('친구: $friendNickname ($friendId)');
      }

      // 1. 이미 친구인지 확인
      final friendCheck = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .get();

      if (friendCheck.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ 이미 친구입니다');
        }
        throw Exception('이미 친구입니다');
      }

      // 2. 양방향 친구 관계 추가
      final batch = _firestore.batch();

      // A → B 친구 추가
      final friendAB = _friendsCollection.doc('${userId}_${friendId}');
      batch.set(friendAB, {
        'userId': userId,
        'friendId': friendId,
        'friendNickname': friendNickname,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // B → A 친구 추가
      final friendBA = _friendsCollection.doc('${friendId}_${userId}');
      batch.set(friendBA, {
        'userId': friendId,
        'friendId': userId,
        'friendNickname': userNickname,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ 양방향 친구 추가 완료!');
        debugPrint('========== 자동 추가 완료 ==========\n');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 추가 실패: $e');
      }
      rethrow;
    }
  }
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n✅ ========== 친구 요청 수락 ==========');
        debugPrint('요청 ID: $requestId');
      }
      
      // 1. 친구 요청 정보 가져오기
      final requestDoc = await _friendRequestsCollection.doc(requestId).get();
      
      if (!requestDoc.exists) {
        throw Exception('친구 요청을 찾을 수 없습니다');
      }

      final data = requestDoc.data() as Map<String, dynamic>;
      final fromUserId = data['fromUserId'];
      final fromUserNickname = data['fromUserNickname'];
      final toUserId = data['toUserId'];
      final toUserNickname = data['toUserNickname'];

      if (kDebugMode) {
        debugPrint('요청자: $fromUserNickname ($fromUserId)');
        debugPrint('수락자: $toUserNickname ($toUserId)');
      }

      // 2. 양방향 친구 관계 추가
      final batch = _firestore.batch();

      // A → B 친구 추가
      final friendAB = _friendsCollection.doc('${fromUserId}_${toUserId}');
      batch.set(friendAB, {
        'userId': fromUserId,
        'friendId': toUserId,
        'friendNickname': toUserNickname,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // B → A 친구 추가
      final friendBA = _friendsCollection.doc('${toUserId}_${fromUserId}');
      batch.set(friendBA, {
        'userId': toUserId,
        'friendId': fromUserId,
        'friendNickname': fromUserNickname,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. 친구 요청 상태 업데이트
      batch.update(_friendRequestsCollection.doc(requestId), {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ 친구 추가 완료!');
        debugPrint('========== 수락 완료 ==========\n');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 수락 실패: $e');
      }
      rethrow;
    }
  }

  /// 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n❌ ========== 친구 요청 거절 ==========');
        debugPrint('요청 ID: $requestId');
      }
      
      await _friendRequestsCollection.doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ 친구 요청 거절 완료');
        debugPrint('========== 거절 완료 ==========\n');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 거절 실패: $e');
      }
      rethrow;
    }
  }

  /// 친구 목록 조회
  Future<List<Friend>> getFriends(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n👥 ========== 친구 목록 조회 ==========');
        debugPrint('사용자 ID: $userId');
      }
      
      final querySnapshot = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (kDebugMode) {
                debugPrint('⚠️ Firestore 조회 타임아웃 - 빈 목록 반환');
              }
              throw Exception('Firebase 연결 타임아웃');
            },
          );

      if (kDebugMode) {
        debugPrint('📊 Firestore 쿼리 결과: ${querySnapshot.docs.length}개 문서');
      }

      // 각 친구의 프로필 정보를 Firestore에서 가져오기
      final friends = <Friend>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final friendId = data['friendId'] ?? '';
        
        if (kDebugMode) {
          debugPrint('   처리 중: 문서 ID ${doc.id}, friendId: $friendId');
        }
        
        // Firestore에서 친구의 프로필 정보 가져오기
        String? profilePhoto;
        String? statusMessage;
        bool isOnline = false;
        
        try {
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            profilePhoto = userData['profilePhoto'] as String?;
            statusMessage = userData['statusMessage'] as String?;
            isOnline = userData['isOnline'] as bool? ?? false;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 친구 프로필 정보 로드 실패 (${data['friendNickname']}): $e');
          }
        }
        
        friends.add(Friend(
          userId: data['userId'] ?? '',
          friendId: friendId,
          friendNickname: data['friendNickname'] ?? '',
          profilePhoto: profilePhoto,
          statusMessage: statusMessage,
          isOnline: isOnline,
          addedAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }

      // 가나다순 정렬 (한글 → 영어 알파벳 순)
      friends.sort((a, b) {
        final aName = a.friendNickname.toLowerCase();
        final bName = b.friendNickname.toLowerCase();
        
        // 한글 여부 확인 (가-힣 범위)
        final aIsKorean = RegExp(r'[가-힣]').hasMatch(aName[0]);
        final bIsKorean = RegExp(r'[가-힣]').hasMatch(bName[0]);
        
        // 1. 한글끼리 비교
        if (aIsKorean && bIsKorean) {
          return aName.compareTo(bName);
        }
        
        // 2. 한글이 먼저, 영어가 나중
        if (aIsKorean && !bIsKorean) {
          return -1; // a가 앞으로
        }
        if (!aIsKorean && bIsKorean) {
          return 1; // b가 앞으로
        }
        
        // 3. 영어끼리 비교
        return aName.compareTo(bName);
      });

      if (kDebugMode) {
        debugPrint('✅ 친구 ${friends.length}명 조회 완료');
        if (friends.isEmpty) {
          debugPrint('⚠️ 친구 목록이 비어 있습니다!');
          debugPrint('   → Firestore "friends" 컬렉션에 데이터가 없습니다');
          debugPrint('   → Firebase Security Rules를 확인하세요');
          debugPrint('   → 또는 친구를 새로 추가해야 합니다');
        } else {
          for (var friend in friends) {
            debugPrint('   - ${friend.friendNickname} (프로필: ${friend.profilePhoto != null ? "있음" : "없음"})');
          }
        }
        debugPrint('========== 조회 완료 ==========\n');
      }

      return friends;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 목록 조회 실패: $e');
        debugPrint('   오류 타입: ${e.runtimeType}');
        debugPrint('   상세: $e');
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          debugPrint('');
          debugPrint('🔥 Firebase Security Rules 권한 오류 발생!');
          debugPrint('   해결 방법:');
          debugPrint('   1. Firebase Console 접속: https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules');
          debugPrint('   2. 다음 규칙 추가:');
          debugPrint('      match /friends/{friendId} {');
          debugPrint('        allow read, write: if true;  // 또는 request.auth != null');
          debugPrint('      }');
          debugPrint('   3. "게시" 버튼 클릭');
          debugPrint('');
        }
      }
      // 빈 목록 대신 에러를 다시 던져서 UI에서 처리 가능하게
      rethrow;
    }
  }

  /// 친구 삭제
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      if (kDebugMode) {
        debugPrint('\n🗑️ ========== 친구 삭제 ==========');
        debugPrint('사용자 ID: $userId');
        debugPrint('친구 ID: $friendId');
      }
      
      final batch = _firestore.batch();

      // A → B 관계 삭제
      batch.delete(_friendsCollection.doc('${userId}_${friendId}'));

      // B → A 관계 삭제
      batch.delete(_friendsCollection.doc('${friendId}_${userId}'));

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ 친구 삭제 완료');
        debugPrint('========== 삭제 완료 ==========\n');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 삭제 실패: $e');
      }
      rethrow;
    }
  }

  /// 사용자 ID로 프로필 사진 가져오기
  Future<Friend?> getFriendById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      final data = userDoc.data();
      if (data == null) {
        return null;
      }
      
      // Friend 객체로 반환 (프로필 사진만 필요)
      return Friend(
        userId: '',
        friendId: userId,
        friendNickname: data['nickname'] ?? '',
        profilePhoto: data['profilePhoto'],
        addedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 사용자 정보 조회 실패: $e');
      }
      return null;
    }
  }
}
