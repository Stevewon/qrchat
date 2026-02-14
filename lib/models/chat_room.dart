/// 채팅방 타입
enum ChatRoomType {
  oneToOne,   // 1:1 채팅
  group,      // 그룹 채팅
}

class ChatRoom {
  final String id;
  final ChatRoomType type;          // 채팅방 타입
  final List<String> participantIds;    // 참여자 ID 리스트
  final List<String> participantNicknames; // 참여자 닉네임 리스트
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isSecuret; // Securet 대화인지 일반 대화인지
  final String? groupName;  // 그룹 채팅방 이름 (옵션)
  final String? createdBy;  // 채팅방을 만든 사람 (방장) ID

  ChatRoom({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNicknames,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.unreadCount = 0,
    this.isSecuret = false,
    this.groupName,
    this.createdBy,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'participantNicknames': participantNicknames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isSecuret': isSecuret,
      'groupName': groupName,
      'createdBy': createdBy,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatRoomType.oneToOne,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      participantNicknames: List<String>.from(json['participantNicknames'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(
          json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
      isSecuret: json['isSecuret'] ?? false,
      groupName: json['groupName'],
      createdBy: json['createdBy'],
    );
  }

  /// Firebase Firestore에서 데이터 읽기
  factory ChatRoom.fromFirestore(Map<String, dynamic> data, String docId) {
    return ChatRoom(
      id: docId,
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatRoomType.oneToOne,
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNicknames: List<String>.from(data['participantNicknames'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as dynamic).toDate()
          : DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      isSecuret: data['isSecuret'] ?? false,
      groupName: data['groupName'],
      createdBy: data['createdBy'],
    );
  }

  // 상대방 닉네임 가져오기 (1:1 채팅용)
  String getOtherParticipant(String myNickname) {
    return participantNicknames.firstWhere(
      (nickname) => nickname != myNickname,
      orElse: () => 'Unknown',
    );
  }

  // 상대방 ID 가져오기 (1:1 채팅용)
  String getOtherParticipantId(String myId) {
    return participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
  }

  // 채팅방 제목 가져오기
  String getTitle(String myNickname) {
    if (type == ChatRoomType.group) {
      return groupName ?? '그룹 채팅';
    } else {
      return getOtherParticipant(myNickname);
    }
  }

  // 복사본 생성
  ChatRoom copyWith({
    String? id,
    ChatRoomType? type,
    List<String>? participantIds,
    List<String>? participantNicknames,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isSecuret,
    String? groupName,
    String? createdBy,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNicknames: participantNicknames ?? this.participantNicknames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isSecuret: isSecuret ?? this.isSecuret,
      groupName: groupName ?? this.groupName,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
