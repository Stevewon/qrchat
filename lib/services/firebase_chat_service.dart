import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'firebase_notification_service.dart';

/// Firebase Firestore 기반 실시간 채팅 서비스 (그룹 채팅 지원)
class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore 컬렉션 참조
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');
  CollectionReference get _messagesCollection => _firestore.collection('messages');

  /// 1:1 채팅방 생성 또는 가져오기
  Future<ChatRoom> getOrCreateOneToOneChatRoom(
    String myId,
    String myNickname,
    String friendId,
    String friendNickname,
  ) async {
    try {
      // 기존 채팅방 검색 (양방향 검색)
      final existingRoom = await _chatRoomsCollection
          .where('type', isEqualTo: 'oneToOne')
          .where('participantIds', arrayContains: myId)
          .get();

      for (var doc in existingRoom.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        if (participantIds.contains(friendId) && participantIds.contains(myId)) {
          return ChatRoom.fromFirestore(data, doc.id);
        }
      }

      // 새 채팅방 생성
      final roomId = '${myId}_${friendId}_${DateTime.now().millisecondsSinceEpoch}';
      final newRoomData = {
        'type': 'oneToOne',
        'participantIds': [myId, friendId],
        'participantNicknames': [myNickname, friendNickname],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _chatRoomsCollection.doc(roomId).set(newRoomData);

      return ChatRoom(
        id: roomId,
        type: ChatRoomType.oneToOne,
        participantIds: [myId, friendId],
        participantNicknames: [myNickname, friendNickname],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  /// 그룹 채팅방 생성
  Future<ChatRoom> createGroupChatRoom(
    List<String> participantIds,
    List<String> participantNicknames,
    String groupName,
    String creatorId, // 추가: 방장 ID
  ) async {
    try {
      final roomId = 'group_${DateTime.now().millisecondsSinceEpoch}';
      final newRoomData = {
        'type': 'group',
        'participantIds': participantIds,
        'participantNicknames': participantNicknames,
        'groupName': groupName,
        'createdBy': creatorId, // 추가: 방장 저장
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _chatRoomsCollection.doc(roomId).set(newRoomData);

      return ChatRoom(
        id: roomId,
        type: ChatRoomType.group,
        participantIds: participantIds,
        participantNicknames: participantNicknames,
        groupName: groupName,
        createdBy: creatorId, // 추가: 방장 저장
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
    } catch (e) {
      throw Exception('그룹 채팅방 생성 실패: $e');
    }
  }

  /// 채팅방 목록 실시간 스트림
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatRoom.fromFirestore(data, doc.id);
      }).toList();
      
      // 메모리에서 정렬 (인덱스 불필요)
      rooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return rooms;
    });
  }

  /// 채팅방 목록 가져오기 (일회성)
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    try {
      final snapshot = await _chatRoomsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      final rooms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatRoom.fromFirestore(data, doc.id);
      }).toList();
      
      // 메모리에서 정렬 (인덱스 불필요)
      rooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return rooms;
    } catch (e) {
      throw Exception('채팅방 목록 조회 실패: $e');
    }
  }

  /// 메시지 전송 (프로필 사진 포함)
  Future<bool> sendMessage(
    String chatRoomId,
    String senderId,
    String senderNickname,
    String content,
    MessageType type, {
    String? senderProfilePhoto,
  }) async {
    try {
      // 프로필 사진이 제공되지 않은 경우 Firestore에서 가져오기
      String? profilePhoto = senderProfilePhoto;
      if (profilePhoto == null && senderId != 'system') {
        try {
          final userDoc = await _firestore.collection('users').doc(senderId).get();
          if (userDoc.exists) {
            profilePhoto = userDoc.data()?['profilePhoto'] as String?;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 프로필 사진 조회 실패: $e');
          }
        }
      }

      final messageId = '${senderId}_${DateTime.now().millisecondsSinceEpoch}';
      final messageData = {
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderNickname': senderNickname,
        'senderProfilePhoto': profilePhoto,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'readBy': [senderId], // 발신자는 자동으로 읽음 처리
      };

      if (kDebugMode) {
        debugPrint('📨 [메시지 전송] ID: $messageId');
        debugPrint('📨 [메시지 전송] 발신자: $senderId ($senderNickname)');
        debugPrint('📨 [메시지 전송] 프로필 사진: ${profilePhoto ?? "null"}');
        if (profilePhoto != null) {
          debugPrint('📨 [메시지 전송] 프로필 URL 길이: ${profilePhoto.length}');
        }
        debugPrint('📨 [메시지 전송] 초기 readBy: [${senderId}]');
      }

      // 메시지 저장
      await _messagesCollection.doc(messageId).set(messageData);

      if (kDebugMode) {
        debugPrint('✅ [메시지 전송] Firestore 저장 완료');
      }

      // 채팅방 마지막 메시지 업데이트
      await _chatRoomsCollection.doc(chatRoomId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // 📱 FCM 푸시 알림 전송 (백그라운드/종료 상태 대응)
      try {
        // 채팅방 정보에서 수신자 찾기
        final chatRoomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
        if (chatRoomDoc.exists) {
          final data = chatRoomDoc.data() as Map<String, dynamic>?;
          // 🔧 수정: 'participants' -> 'participantIds' (Firestore 필드명과 일치)
          final participantIds = data?['participantIds'] as List<dynamic>?;
          if (participantIds != null) {
            if (kDebugMode) {
              debugPrint('📨 [알림 전송] 채팅방 참여자: $participantIds');
              debugPrint('📨 [알림 전송] 발신자: $senderId');
            }
            
            // 발신자가 아닌 다른 참여자에게 알림 전송
            for (final participantId in participantIds) {
              if (participantId != senderId) {
                if (kDebugMode) {
                  debugPrint('📨 [알림 전송] → 수신자: $participantId');
                }
                await FirebaseNotificationService.sendMessageNotification(
                  receiverUserId: participantId,
                  senderName: senderNickname,
                  messageText: type == MessageType.text ? content : '📎 파일을 보냈습니다',
                  chatRoomId: chatRoomId,
                );
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ [알림 전송] participantIds가 null입니다');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [알림 전송] 채팅방 문서가 존재하지 않습니다: $chatRoomId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ FCM 알림 전송 실패: $e');
        }
        // 알림 실패해도 메시지 전송은 성공으로 처리
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 메시지 전송 실패: $e');
      }
      return false;
    }
  }

  /// 메시지 목록 실시간 스트림
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _messagesCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromFirestore(data, doc.id);
      }).toList();
      
      // 메모리에서 정렬 (인덱스 불필요)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    });
  }

  /// 메시지 목록 가져오기 (일회성)
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    try {
      final snapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromFirestore(data, doc.id);
      }).toList();
      
      // 메모리에서 정렬 (인덱스 불필요)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    } catch (e) {
      throw Exception('메시지 조회 실패: $e');
    }
  }

  /// 메시지 읽음 처리 (readBy 배열에 사용자 추가)
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('👁️ [읽음 처리] 시작 - 채팅방: $chatRoomId, 사용자: $userId');
      }
      
      // 🔧 FIX: where('senderId', isNotEqualTo) 제거 - 단순 쿼리로 변경
      // 모든 메시지를 가져온 후 코드에서 필터링
      final snapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      if (kDebugMode) {
        debugPrint('👁️ [읽음 처리] 조회된 전체 메시지 수: ${snapshot.docs.length}');
      }

      final batch = _firestore.batch();
      int updateCount = 0;
      int skippedOwnMessages = 0;
      int skippedAlreadyRead = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String?;
        final readBy = (data['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
        
        if (kDebugMode) {
          debugPrint('👁️ [읽음 처리] 메시지 ${doc.id}');
          debugPrint('   발신자: $senderId');
          debugPrint('   내용: ${data['content']}');
          debugPrint('   현재 readBy: ${readBy.join(", ")}');
          debugPrint('   readBy 길이: ${readBy.length}');
        }
        
        // 본인이 보낸 메시지는 스킵
        if (senderId == userId) {
          if (kDebugMode) {
            debugPrint('   ⏭️  본인 메시지 - 스킵');
          }
          skippedOwnMessages++;
          continue;
        }
        
        // 이미 읽은 경우 스킵
        if (readBy.contains(userId)) {
          if (kDebugMode) {
            debugPrint('   ⏭️  이미 읽음 - 스킵');
          }
          skippedAlreadyRead++;
          continue;
        }
        
        // Firestore arrayUnion으로 중복 없이 추가
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'isRead': true, // 하위 호환성
        });
        
        updateCount++;
        
        if (kDebugMode) {
          debugPrint('   ✅ 읽음 처리 추가 (사용자: $userId)');
        }
      }
      
      if (kDebugMode) {
        debugPrint('👁️ [읽음 처리] 통계:');
        debugPrint('   - 전체 메시지: ${snapshot.docs.length}개');
        debugPrint('   - 본인 메시지 스킵: $skippedOwnMessages개');
        debugPrint('   - 이미 읽음 스킵: $skippedAlreadyRead개');
        debugPrint('   - 업데이트할 메시지: $updateCount개');
      }
      
      if (updateCount > 0) {
        await batch.commit();
        if (kDebugMode) {
          debugPrint('✅ [읽음 처리] Firestore 커밋 완료 ($updateCount개 메시지 업데이트)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️  [읽음 처리] 업데이트할 메시지 없음');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [읽음 처리] 실패: $e');
        debugPrint('   스택 트레이스: ${StackTrace.current}');
      }
      throw Exception('읽음 처리 실패: $e');
    }
  }

  /// 채팅방 삭제
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      // 채팅방의 모든 메시지 삭제
      final messagesSnapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 채팅방 삭제
      batch.delete(_chatRoomsCollection.doc(chatRoomId));

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 채팅방 나가기 (그룹 채팅용)
  Future<void> leaveChatRoom(String chatRoomId, String userId) async {
    try {
      final doc = await _chatRoomsCollection.doc(chatRoomId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final participantIds = List<String>.from(data['participantIds'] ?? []);
      final participantNicknames = List<String>.from(data['participantNicknames'] ?? []);

      final userIndex = participantIds.indexOf(userId);
      if (userIndex != -1) {
        participantIds.removeAt(userIndex);
        participantNicknames.removeAt(userIndex);

        if (participantIds.isEmpty) {
          // 참여자가 없으면 채팅방 삭제
          await deleteChatRoom(chatRoomId);
        } else {
          // 참여자 목록 업데이트
          await _chatRoomsCollection.doc(chatRoomId).update({
            'participantIds': participantIds,
            'participantNicknames': participantNicknames,
          });
        }
      }
    } catch (e) {
      throw Exception('채팅방 나가기 실패: $e');
    }
  }

  /// 🔥 실시간 채팅 메시지 스트림 (인덱스 불필요)
  Stream<List<ChatMessage>> getChatMessagesStream(String chatRoomId) {
    return _messagesCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = <ChatMessage>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        var message = ChatMessage.fromFirestore(data, doc.id);
        
        // 🐛 DEBUG: Firestore 원본 데이터 확인
        if (kDebugMode) {
          debugPrint('🔍 [메시지 스트림] 메시지 ID: ${doc.id}');
          debugPrint('   발신자: ${message.senderNickname}');
          debugPrint('   타입: ${data['type']} → ${message.type}');
          debugPrint('   Content: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');
          debugPrint('   Firestore senderProfilePhoto: ${data['senderProfilePhoto']}');
          debugPrint('   Message 객체 senderProfilePhoto: ${message.senderProfilePhoto}');
        }
        
        // 🔧 프로필 사진이 없거나 닉네임이 이상한 경우 Firebase에서 가져오기
        bool needsUserData = (message.senderProfilePhoto == null || message.senderProfilePhoto!.isEmpty) ||
                             (message.senderNickname.isEmpty || message.senderNickname == '시스템' || message.senderNickname == 'system');
        
        if (needsUserData && message.senderId != 'system') {
          if (kDebugMode) {
            debugPrint('   ⚠️ 사용자 데이터 불완전 - Firebase users에서 조회 시도');
            debugPrint('      현재 프로필 사진: ${message.senderProfilePhoto ?? "null"}');
            debugPrint('      현재 닉네임: ${message.senderNickname}');
          }
          
          try {
            final userDoc = await _firestore.collection('users').doc(message.senderId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final profilePhoto = userData['profilePhoto'] as String?;
              final nickname = userData['nickname'] as String?;
              
              // 프로필 사진과 닉네임 모두 업데이트
              if (profilePhoto != null && profilePhoto.isNotEmpty) {
                message = message.copyWith(
                  senderProfilePhoto: profilePhoto,
                  senderNickname: nickname ?? message.senderNickname,
                );
                
                if (kDebugMode) {
                  debugPrint('   ✅ [사용자 데이터 로드 성공]');
                  debugPrint('      프로필 URL: ${profilePhoto.substring(0, 50)}...');
                  debugPrint('      닉네임: $nickname');
                }
              } else {
                // 프로필 사진은 없지만 닉네임은 업데이트
                if (nickname != null && nickname.isNotEmpty) {
                  message = message.copyWith(senderNickname: nickname);
                  if (kDebugMode) {
                    debugPrint('   ✅ [닉네임만 로드 성공] $nickname');
                  }
                }
              }
            } else {
              if (kDebugMode) {
                debugPrint('   ❌ users 컬렉션에 사용자 문서 없음: ${message.senderId}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('   ⚠️ [사용자 데이터 로드 실패] ${message.senderId}: $e');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('   ✅ 사용자 데이터 완전함 (프로필: ${message.senderProfilePhoto != null ? "있음" : "없음"}, 닉네임: ${message.senderNickname})');
          }
        }
        
        messages.add(message);
      }
      
      // 메모리에서 정렬 (인덱스 불필요)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    });
  }

  /// 🔥 실시간 사용자 채팅방 목록 스트림
  Stream<List<ChatRoom>> getUserChatRoomsStream(String userId) {
    return _chatRoomsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final rooms = <ChatRoom>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final chatRoom = ChatRoom.fromFirestore(data, doc.id);
        
        // ⭐ 안 읽은 메시지 개수 계산
        final unreadCount = await _getUnreadMessageCount(chatRoom.id, userId);
        
        // ChatRoom 객체에 unreadCount 업데이트
        final updatedRoom = chatRoom.copyWith(unreadCount: unreadCount);
        rooms.add(updatedRoom);
      }
      
      // 메모리에서 정렬 (Firestore 인덱스 불필요)
      rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return rooms;
    });
  }

  /// ⭐ 안 읽은 메시지 개수 계산
  Future<int> _getUnreadMessageCount(String chatRoomId, String userId) async {
    try {
      final snapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();
      
      int unreadCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String?;
        final readBy = (data['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
        
        // 본인이 보낸 메시지가 아니고, readBy에 자신이 없으면 안 읽은 메시지
        if (senderId != userId && !readBy.contains(userId)) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 안 읽은 메시지 개수 계산 오류: $e');
      }
      return 0;
    }
  }

  /// 특정 채팅방 실시간 스트림
  Stream<ChatRoom?> getChatRoomStream(String chatRoomId) {
    if (kDebugMode) {
      debugPrint('📡 [채팅방 스트림] 시작: $chatRoomId');
    }
    
    return _chatRoomsCollection
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ [채팅방 스트림] 채팅방이 존재하지 않음: $chatRoomId');
        }
        return null;
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      final chatRoom = ChatRoom.fromFirestore(data, snapshot.id);
      
      if (kDebugMode) {
        debugPrint('🔄 [채팅방 스트림] 업데이트: ${chatRoom.id}');
        debugPrint('   참여자 수: ${chatRoom.participantIds.length}');
        debugPrint('   참여자 목록: ${chatRoom.participantIds.join(", ")}');
      }
      
      return chatRoom;
    });
  }

  /// 채팅방 정보 가져오기 (일회성)
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      if (kDebugMode) {
        debugPrint('📥 [채팅방 조회] 시작: $chatRoomId');
      }
      
      final snapshot = await _chatRoomsCollection.doc(chatRoomId).get();
      
      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ [채팅방 조회] 채팅방이 존재하지 않음: $chatRoomId');
        }
        return null;
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      final chatRoom = ChatRoom.fromFirestore(data, snapshot.id);
      
      if (kDebugMode) {
        debugPrint('✅ [채팅방 조회] 성공: ${chatRoom.id}');
        debugPrint('   채팅방 이름: ${chatRoom.groupName}');
        debugPrint('   참여자 수: ${chatRoom.participantIds.length}');
        debugPrint('   참여자 목록: ${chatRoom.participantIds.join(", ")}');
      }
      
      return chatRoom;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [채팅방 조회] 실패: $e');
      }
      return null;
    }
  }

  /// 모든 채팅방 조회 (호환성을 위한 일반 메서드)
  Future<List<ChatRoom>> getAllChatRooms(String userId) async {
    try {
      final snapshot = await _chatRoomsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      final rooms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatRoom.fromFirestore(data, doc.id);
      }).toList();
      
      // 메모리에서 정렬 (Firestore 인덱스 불필요)
      rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return rooms;
    } catch (e) {
      throw Exception('채팅방 목록 조회 실패: $e');
    }
  }

  /// 🎉 채팅방에 친구 초대하기 (그룹 채팅으로 전환)
  Future<ChatRoom> inviteFriendsToChatRoom(
    String chatRoomId,
    List<String> newParticipantIds,
    List<String> newParticipantNicknames,
    String inviterNickname,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('\n👥 ========== 친구 초대 ==========');
        debugPrint('채팅방 ID: $chatRoomId');
        debugPrint('초대할 친구: ${newParticipantNicknames.join(", ")}');
        debugPrint('초대자: $inviterNickname');
      }

      // 1. 기존 채팅방 정보 가져오기
      final roomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
      
      if (!roomDoc.exists) {
        throw Exception('채팅방을 찾을 수 없습니다');
      }

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final currentParticipantIds = List<String>.from(roomData['participantIds'] ?? []);
      final currentParticipantNicknames = List<String>.from(roomData['participantNicknames'] ?? []);

      // 2. 새로운 참가자 추가 (중복 제거)
      final updatedParticipantIds = [...currentParticipantIds];
      final updatedParticipantNicknames = [...currentParticipantNicknames];

      for (int i = 0; i < newParticipantIds.length; i++) {
        if (!updatedParticipantIds.contains(newParticipantIds[i])) {
          updatedParticipantIds.add(newParticipantIds[i]);
          updatedParticipantNicknames.add(newParticipantNicknames[i]);
        }
      }

      if (kDebugMode) {
        debugPrint('기존 참가자: ${currentParticipantNicknames.join(", ")}');
        debugPrint('업데이트된 참가자: ${updatedParticipantNicknames.join(", ")}');
      }

      // 3. 채팅방 타입을 그룹으로 변경 (3명 이상인 경우)
      final isGroupChat = updatedParticipantIds.length > 2;
      final chatType = isGroupChat ? 'group' : 'oneToOne';

      // 4. 그룹 이름 생성 (첫 3명의 닉네임)
      String? groupName;
      if (isGroupChat) {
        final displayNames = updatedParticipantNicknames.take(3).toList();
        groupName = displayNames.join(', ');
        if (updatedParticipantNicknames.length > 3) {
          groupName += ' 외 ${updatedParticipantNicknames.length - 3}명';
        }
      }

      // 5. Firestore 업데이트
      await _chatRoomsCollection.doc(chatRoomId).update({
        'type': chatType,
        'participantIds': updatedParticipantIds,
        'participantNicknames': updatedParticipantNicknames,
        'groupName': groupName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔥 v9.3.11: 시스템 초대 메시지 완전 제거!
      // 초대 알림 없이 조용히 참여자 추가만 처리
      if (kDebugMode) {
        debugPrint('✅ 친구 초대 완료! (시스템 메시지 없음)');
        debugPrint('채팅방 타입: $chatType');
        if (groupName != null) {
          debugPrint('그룹 이름: $groupName');
        }
        debugPrint('========== 초대 완료 ==========\n');
      }

      // 7. 업데이트된 채팅방 정보 반환
      return ChatRoom(
        id: chatRoomId,
        type: isGroupChat ? ChatRoomType.group : ChatRoomType.oneToOne,
        participantIds: updatedParticipantIds,
        participantNicknames: updatedParticipantNicknames,
        lastMessage: roomData['lastMessage'] ?? '',
        lastMessageTime: roomData['lastMessageTime'] != null
            ? (roomData['lastMessageTime'] as Timestamp).toDate()
            : DateTime.now(),
        unreadCount: roomData['unreadCount'] ?? 0,
        groupName: groupName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 초대 실패: $e');
      }
      rethrow;
    }
  }
}
