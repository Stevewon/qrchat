import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_room.dart';
import '../models/securet_user.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';
import '../services/app_badge_service.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_chat_screen.dart';
import 'friends_list_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  List<ChatRoom> _chatRooms = [];
  SecuretUser? _currentUser;
  bool _isLoading = true;
  StreamSubscription? _chatRoomsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }

  /// 현재 사용자 로드 후 채팅방 스트림 구독
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await SecuretAuthService.getCurrentUser();
      if (_currentUser != null) {
        _listenToChatRooms();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보 로딩 실패: $e'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Firebase 실시간 채팅방 목록 스트림 구독
  void _listenToChatRooms() {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    _chatRoomsSubscription = _chatService.getUserChatRoomsStream(_currentUser!.id).listen(
      (rooms) {
        if (mounted) {
          setState(() {
            _chatRooms = rooms;
            _isLoading = false;
          });
          
          // ⭐ 앱 배지 업데이트 (총 안 읽은 메시지 개수)
          _updateAppBadge();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('채팅 목록 로딩 실패: $error'),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  /// ⭐ 앱 배지 업데이트
  Future<void> _updateAppBadge() async {
    if (_currentUser != null) {
      await AppBadgeService.updateBadge(_currentUser!.id);
    }
  }

  /// 수동 새로고침 (필요시 - Firebase 스트림으로 자동 업데이트)
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await SecuretAuthService.getCurrentUser();
      if (_currentUser != null) {
        final rooms = await _chatService.getAllChatRooms(_currentUser!.id);
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅 목록 로딩 실패: $e'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Colors.teal,
        actions: [
          // 그룹 채팅 생성 버튼
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              if (_currentUser != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateGroupChatScreen(
                      currentUserId: _currentUser!.id,
                      currentUserNickname: _currentUser!.nickname,
                    ),
                  ),
                );
                
                // 그룹 채팅방 생성 완료 시 해당 채팅방으로 이동
                if (result != null && result is ChatRoom && mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        chatRoom: result,
                        currentUserId: _currentUser!.id,
                        currentUserNickname: _currentUser!.nickname,
                      ),
                    ),
                  );
                  _loadData();
                }
              }
            },
            tooltip: '그룹 채팅 만들기',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsListScreen(),
                ),
              ).then((_) => _loadData());
            },
            tooltip: '친구 목록',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '아직 채팅이 없습니다',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FriendsListScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.people),
                        label: const Text('친구 목록 보기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    itemCount: _chatRooms.length,
                    itemBuilder: (context, index) {
                      final room = _chatRooms[index];
                      return _buildChatRoomItem(room);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    final otherParticipant = _currentUser != null
        ? room.getOtherParticipant(_currentUser!.nickname)
        : 'Unknown';
    
    // 상대방 ID 가져오기
    final otherUserId = _currentUser != null && room.type == ChatRoomType.oneToOne
        ? room.getOtherParticipantId(_currentUser!.id)
        : null;

    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.startToEnd, // ⭐ 왼쪽에서 오른쪽으로 스와이프 (카카오톡 스타일)
      background: Container(
        alignment: Alignment.centerLeft, // ⭐ 왼쪽 정렬
        padding: const EdgeInsets.only(left: 20), // ⭐ 왼쪽 패딩
        color: Colors.lightGreen[200], // 연한 연두색
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.exit_to_app, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              '나가기',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // ⭐ 스와이프 시 확인 다이얼로그 표시
        return await _showLeaveConfirmDialog(room);
      },
      onDismissed: (direction) {
        // 이미 confirmDismiss에서 처리했으므로 여기서는 아무것도 안 함
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: () {
            if (_currentUser != null) {
              // 채팅방 타입에 따라 다른 화면으로 이동
              if (room.type == ChatRoomType.group) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      chatRoom: room,
                      currentUserId: _currentUser!.id,
                      currentUserNickname: _currentUser!.nickname,
                    ),
                  ),
                ).then((_) => _loadData());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoom: room,
                      currentUserId: _currentUser!.id,
                      currentUserNickname: _currentUser!.nickname,
                    ),
                  ),
                ).then((_) => _loadData());
              }
            }
          },
          onLongPress: () {
            _showLeaveChatDialog(room);
          },
          child: ListTile(
        leading: otherUserId != null
            ? FutureBuilder<String?>(
                future: _getProfilePhoto(otherUserId),
                builder: (context, snapshot) {
                  return Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: room.isSecuret ? Colors.red : Colors.teal,
                        radius: 28,
                        backgroundImage: snapshot.hasData && 
                                       snapshot.data != null && 
                                       snapshot.data!.isNotEmpty
                            ? NetworkImage(snapshot.data!)
                            : null,
                        child: snapshot.hasData && 
                               snapshot.data != null && 
                               snapshot.data!.isNotEmpty
                            ? null
                            : Text(
                                otherParticipant.isNotEmpty
                                    ? otherParticipant[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                      if (room.isSecuret)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: room.isSecuret ? Colors.red : Colors.teal,
                    radius: 28,
                    child: Icon(
                      room.type == ChatRoomType.group ? Icons.group : Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (room.isSecuret)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherParticipant,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (room.isSecuret)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Securet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          _formatMessagePreview(room.lastMessage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: room.lastMessage.isEmpty ? Colors.grey : null,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(room.lastMessageTime),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (room.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: room.isSecuret ? Colors.red : Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${room.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    ),
    );
  }

  /// ⭐ 스와이프로 바로 나가기 (팝업 없이 즉시 실행)
  Future<bool> _showLeaveConfirmDialog(ChatRoom room) async {
    if (_currentUser != null) {
      await _leaveChatRoom(room);
      
      // 채팅방 나가기 성공 시 즉시 목록에서 제거 (스낵바 제거)
      // Dismissible 위젯이 자동으로 아이템을 제거하므로 추가 작업 불필요
      
      return true; // Dismissible이 아이템을 제거하도록 허용
    }
    
    return false;
  }

  /// 채팅방 나가기 확인 다이얼로그 (Long Press용 - 기존 유지)
  Future<void> _showLeaveChatDialog(ChatRoom room) async {
    final otherParticipant = _currentUser != null
        ? room.getOtherParticipant(_currentUser!.nickname)
        : 'Unknown';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: Text(
          room.type == ChatRoomType.group
              ? '${room.groupName ?? "그룹 채팅"}에서 나가시겠습니까?\n나가면 대화 내용이 모두 삭제됩니다.'
              : '$otherParticipant님과의 채팅방에서 나가시겠습니까?\n나가면 대화 내용이 모두 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentUser != null) {
      await _leaveChatRoom(room);
    }
  }

  /// 채팅방 나가기 실행
  Future<void> _leaveChatRoom(ChatRoom room) async {
    try {
      // 채팅방 삭제
      final success = await _chatService.deleteChatRoom(room.id);
      
      if (success) {
        if (mounted) {
          // 채팅방 목록 새로고침
          setState(() {
            _chatRooms.remove(room);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('채팅방 나가기 실패'),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// 상대방 프로필 사진 가져오기
  Future<String?> _getProfilePhoto(String userId) async {
    try {
      final friend = await _friendService.getFriendById(userId);
      return friend?.profilePhoto;
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.month}/${time.day}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금';
    }
  }

  /// 메시지 내용 포맷 (이미지/파일 URL 처리)
  String _formatMessagePreview(String message) {
    if (message.isEmpty) return '새로운 대화를 시작해보세요';
    
    // 모든 URL 패턴 감지 (Firebase, Giphy, 기타 모든 URL)
    if (message.startsWith('http://') || message.startsWith('https://')) {
      final lowerMessage = message.toLowerCase();
      
      // 이미지 파일 확장자 체크
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      if (imageExtensions.any((ext) => lowerMessage.contains(ext))) {
        return '📷 사진';
      }
      
      // 동영상 파일 확장자 체크
      final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
      if (videoExtensions.any((ext) => lowerMessage.contains(ext))) {
        return '🎥 동영상';
      }
      
      // 특정 도메인 감지
      if (message.contains('giphy.com') || message.contains('tenor.com')) {
        return '🎬 GIF';
      }
      
      // 기타 URL
      return '📎 링크';
    }
    
    // 일반 텍스트 메시지
    return message;
  }
}
