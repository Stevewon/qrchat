/// 채팅 메시지 타입
enum MessageType {
  text,       // 텍스트 메시지
  image,      // 이미지
  file,       // 파일
  video,      // 동영상
  securet,    // Securet 보안 메시지 (중요한 대화)
}

/// 채팅 메시지 모델
class ChatMessage {
  final String id;              // 메시지 ID
  final String chatRoomId;      // 채팅방 ID
  final String senderId;        // 발신자 ID
  final String senderNickname;  // 발신자 닉네임
  final String? senderProfilePhoto; // 발신자 프로필 사진
  final String content;         // 메시지 내용
  final MessageType type;       // 메시지 타입
  final DateTime timestamp;     // 전송 시간
  final bool isRead;            // 읽음 여부 (하위 호환성)
  final List<String> readBy;    // 읽은 사용자 ID 목록

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderNickname,
    this.senderProfilePhoto,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
  });

  /// JSON to ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderId: json['senderId'] as String,
      senderNickname: json['senderNickname'] as String,
      senderProfilePhoto: json['senderProfilePhoto'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readBy: (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  /// Firebase Firestore에서 데이터 읽기
  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String docId) {
    return ChatMessage(
      id: docId,
      chatRoomId: data['chatRoomId'] as String,
      senderId: data['senderId'] as String,
      senderNickname: data['senderNickname'] as String,
      senderProfilePhoto: data['senderProfilePhoto'] as String?,
      content: data['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      readBy: (data['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  /// ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'senderProfilePhoto': senderProfilePhoto,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readBy': readBy,
    };
  }

  /// 복사본 생성 (읽음 상태 변경용)
  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderNickname,
    String? senderProfilePhoto,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      senderProfilePhoto: senderProfilePhoto ?? this.senderProfilePhoto,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }
  
  /// 읽지 않은 사용자 수 계산
  int getUnreadCount(int totalParticipants) {
    // 읽지 않은 사용자 수 = 총 참여자 - 읽은 사용자 수
    // (발신자는 이미 readBy에 포함되어 있음)
    final unreadCount = totalParticipants - readBy.length;
    return unreadCount > 0 ? unreadCount : 0;
  }
}
