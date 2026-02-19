import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

/// 실시간 채팅 서비스
class ChatService {
  static const String _chatRoomsKey = 'qrchat_chat_rooms';
  static const String _messagesKeyPrefix = 'qrchat_messages_';

  /// 1:1 채팅방 생성 또는 가져오기
  Future<ChatRoom> getOrCreateOneToOneChatRoom(
    String myId,
    String myNickname,
    String friendId,
    String friendNickname,
  ) async {
    try {
      // 기존 채팅방 검색
      final allRooms = await getAllChatRooms(myId);
      
      // 이미 존재하는 1:1 채팅방 찾기
      for (var room in allRooms) {
        if (room.type == ChatRoomType.oneToOne &&
            room.participantIds.contains(friendId) &&
            room.participantIds.contains(myId)) {
          return room;
        }
      }

      // 새 채팅방 생성
      final newRoom = ChatRoom(
        id: '${myId}_${friendId}_${DateTime.now().millisecondsSinceEpoch}',
        type: ChatRoomType.oneToOne,
        participantIds: [myId, friendId],
        participantNicknames: [myNickname, friendNickname],
        lastMessageTime: DateTime.now(),
      );

      // 채팅방 저장
      await _saveChatRoom(newRoom);

      return newRoom;
    } catch (e) {
      rethrow;
    }
  }

  /// 그룹 채팅방 생성
  Future<ChatRoom> createGroupChatRoom(
    List<String> participantIds,
    List<String> participantNicknames,
    String groupName,
  ) async {
    try {
      // 그룹 채팅방 생성
      final newRoom = ChatRoom(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        type: ChatRoomType.group,
        participantIds: participantIds,
        participantNicknames: participantNicknames,
        groupName: groupName,
        lastMessageTime: DateTime.now(),
      );

      // 채팅방 저장
      await _saveChatRoom(newRoom);

      return newRoom;
    } catch (e) {
      rethrow;
    }
  }

  /// 채팅방 저장
  Future<void> _saveChatRoom(ChatRoom room) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_chatRoomsKey);
      
      List<ChatRoom> rooms = [];
      if (roomsJson != null) {
        final List<dynamic> roomsList = json.decode(roomsJson);
        rooms = roomsList.map((json) => ChatRoom.fromJson(json)).toList();
      }

      // 중복 확인 및 업데이트
      final existingIndex = rooms.indexWhere((r) => r.id == room.id);
      if (existingIndex != -1) {
        rooms[existingIndex] = room;
      } else {
        rooms.add(room);
      }

      await prefs.setString(_chatRoomsKey, json.encode(rooms.map((r) => r.toJson()).toList()));
    } catch (e) {
      // 에러 무시
    }
  }

  /// 모든 채팅방 가져오기
  Future<List<ChatRoom>> getAllChatRooms(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_chatRoomsKey);
      
      if (roomsJson == null) return [];
      
      final List<dynamic> roomsList = json.decode(roomsJson);
      final allRooms = roomsList.map((json) => ChatRoom.fromJson(json)).toList();
      
      // 내가 참여한 채팅방만 필터링
      final myRooms = allRooms
          .where((room) => room.participantIds.contains(userId))
          .toList();
      
      // 최근 메시지 시간순 정렬
      myRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      return myRooms;
    } catch (e) {
      return [];
    }
  }

  /// 메시지 전송
  Future<bool> sendMessage(
    String chatRoomId,
    String senderId,
    String senderNickname,
    String content,
    MessageType type,
  ) async {
    try {
      // 새 메시지 생성
      final message = ChatMessage(
        id: '${senderId}_${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      );

      // 메시지 저장
      await _saveMessage(message);

      // 채팅방 마지막 메시지 업데이트
      await _updateChatRoomLastMessage(chatRoomId, content);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 메시지 저장
  Future<void> _saveMessage(ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_messagesKeyPrefix${message.chatRoomId}';
      final messagesJson = prefs.getString(key);
      
      List<ChatMessage> messages = [];
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        messages = messagesList.map((json) => ChatMessage.fromJson(json)).toList();
      }

      messages.add(message);
      await prefs.setString(key, json.encode(messages.map((m) => m.toJson()).toList()));
    } catch (e) {
      // 에러 무시
    }
  }

  /// 채팅방의 메시지 목록 가져오기
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_messagesKeyPrefix$chatRoomId';
      final messagesJson = prefs.getString(key);
      
      if (messagesJson == null) return [];
      
      final List<dynamic> messagesList = json.decode(messagesJson);
      final messages = messagesList.map((json) => ChatMessage.fromJson(json)).toList();
      
      // 시간순 정렬 (오래된 것부터)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    } catch (e) {
      return [];
    }
  }

  /// 채팅방 마지막 메시지 업데이트
  Future<void> _updateChatRoomLastMessage(String chatRoomId, String lastMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_chatRoomsKey);
      
      if (roomsJson == null) return;
      
      final List<dynamic> roomsList = json.decode(roomsJson);
      final rooms = roomsList.map((json) => ChatRoom.fromJson(json)).toList();
      
      final roomIndex = rooms.indexWhere((r) => r.id == chatRoomId);
      if (roomIndex != -1) {
        final updatedRoom = rooms[roomIndex].copyWith(
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
        );
        rooms[roomIndex] = updatedRoom;
        
        await prefs.setString(_chatRoomsKey, json.encode(rooms.map((r) => r.toJson()).toList()));
      }
    } catch (e) {
      // 에러 무시
    }
  }

  /// 메시지 읽음 처리
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final messages = await getMessages(chatRoomId);
      
      // 내가 보낸 메시지가 아닌 것들을 읽음 처리
      final updatedMessages = messages.map((msg) {
        if (msg.senderId != userId && !msg.isRead) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      // 저장
      final prefs = await SharedPreferences.getInstance();
      final key = '$_messagesKeyPrefix$chatRoomId';
      await prefs.setString(key, json.encode(updatedMessages.map((m) => m.toJson()).toList()));

      // 채팅방 읽지 않은 메시지 카운트 초기화
      await _updateChatRoomUnreadCount(chatRoomId, userId);
    } catch (e) {
      // 에러 무시
    }
  }

  /// 채팅방 읽지 않은 메시지 카운트 업데이트
  Future<void> _updateChatRoomUnreadCount(String chatRoomId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_chatRoomsKey);
      
      if (roomsJson == null) return;
      
      final List<dynamic> roomsList = json.decode(roomsJson);
      final rooms = roomsList.map((json) => ChatRoom.fromJson(json)).toList();
      
      final roomIndex = rooms.indexWhere((r) => r.id == chatRoomId);
      if (roomIndex != -1) {
        final updatedRoom = rooms[roomIndex].copyWith(unreadCount: 0);
        rooms[roomIndex] = updatedRoom;
        
        await prefs.setString(_chatRoomsKey, json.encode(rooms.map((r) => r.toJson()).toList()));
      }
    } catch (e) {
      // 에러 무시
    }
  }

  /// 채팅방 삭제
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 채팅방 삭제
      final roomsJson = prefs.getString(_chatRoomsKey);
      if (roomsJson != null) {
        final List<dynamic> roomsList = json.decode(roomsJson);
        final rooms = roomsList.map((json) => ChatRoom.fromJson(json)).toList();
        rooms.removeWhere((r) => r.id == chatRoomId);
        await prefs.setString(_chatRoomsKey, json.encode(rooms.map((r) => r.toJson()).toList()));
      }

      // 메시지 삭제
      final key = '$_messagesKeyPrefix$chatRoomId';
      await prefs.remove(key);

      return true;
    } catch (e) {
      return false;
    }
  }
}
