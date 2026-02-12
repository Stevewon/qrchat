import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';
import '../models/chat_room.dart';
import '../services/firebase_friend_service.dart';
import '../services/firebase_chat_service.dart';
import '../services/securet_auth_service.dart';
import 'friend_search_screen.dart';
import 'friend_requests_screen.dart';
import 'chat_screen.dart';

/// 친구 목록 화면
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final FirebaseChatService _chatService = FirebaseChatService();
  
  List<Friend> _friends = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserNickname;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _currentUserId = user.id;
      _currentUserNickname = user.nickname;
      final friends = await _friendService.getFriends(user.id);
      
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 친구 삭제 확인 다이얼로그
  Future<void> _confirmRemoveFriend(Friend friend) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.nickname}님을 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true && _currentUserId != null) {
      try {
        await _friendService.removeFriend(_currentUserId!, friend.id);
        // 친구 삭제 성공 시 즉시 목록 새로고침 (스낵바 제거)
        await _loadFriends();
      } catch (e) {
        _showSnackBar('친구 삭제에 실패했습니다', isError: true);
      }
    }
  }

  /// 스낵바 표시
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 1:1 대화 시작
  Future<void> _startChat(Friend friend) async {
    if (_currentUserId == null || _currentUserNickname == null) {
      _showSnackBar('로그인이 필요합니다', isError: true);
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 🔍 디버그: 사용자 인증 상태 확인
      print('🔍 [인증 확인] currentUserId: $_currentUserId');
      print('🔍 [인증 확인] currentUserNickname: $_currentUserNickname');
      print('🔍 [인증 확인] friendId: ${friend.id}');
      print('🔍 [인증 확인] friendNickname: ${friend.nickname}');
      
      // Firebase Auth 현재 사용자 확인
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔍 [Firebase Auth] currentUser: ${currentUser?.uid}');
      print('🔍 [Firebase Auth] email: ${currentUser?.email}');
      
      // 채팅방 생성 또는 가져오기
      final chatRoom = await _chatService.getOrCreateOneToOneChatRoom(
        _currentUserId!,
        _currentUserNickname!,
        friend.id,
        friend.nickname,
      );

      if (mounted) {
        // 로딩 닫기
        Navigator.pop(context);

        // 채팅 화면으로 이동
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: chatRoom,
              currentUserId: _currentUserId!,
              currentUserNickname: _currentUserNickname!,
            ),
          ),
        );

        // 채팅방이 삭제되었으면 새로고침
        if (result == true) {
          _loadFriends();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        print('❌ [채팅방 생성 오류] $e');
        _showSnackBar('채팅방 생성 실패: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        elevation: 0,
        actions: [
          // 친구 요청 버튼
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.person_add),
                // TODO: 새 요청이 있으면 배지 표시
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestsScreen(),
                ),
              );
              _loadFriends();
            },
          ),
          // 친구 검색 버튼
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendSearchScreen(),
                ),
              );
              _loadFriends();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? _buildEmptyState()
              : _buildFriendsList(),
    );
  }

  /// 빈 상태 빌드
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 친구가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendSearchScreen(),
                ),
              );
              _loadFriends();
            },
            icon: const Icon(Icons.person_search),
            label: const Text('친구 찾기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 친구 목록 빌드
  Widget _buildFriendsList() {
    return Column(
      children: [
        // 친구 수
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          child: Text(
            '친구 ${_friends.length}명',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),

        // 친구 목록
        Expanded(
          child: ListView.builder(
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              final friend = _friends[index];
              return _buildFriendTile(friend);
            },
          ),
        ),
      ],
    );
  }

  /// 친구 타일 빌드
  Widget _buildFriendTile(Friend friend) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            backgroundImage: friend.profilePhoto != null && friend.profilePhoto!.isNotEmpty
                ? NetworkImage(friend.profilePhoto!)
                : null,
            child: friend.profilePhoto == null || friend.profilePhoto!.isEmpty
                ? Icon(
                    Icons.person,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
          ),
          // 온라인 상태 표시
          if (friend.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        friend.nickname,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: friend.statusMessage != null
          ? Text(
              friend.statusMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'chat') {
            _startChat(friend);
          } else if (value == 'remove') {
            _confirmRemoveFriend(friend);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'chat',
            child: Row(
              children: [
                Icon(Icons.chat, size: 20),
                SizedBox(width: 12),
                Text('1:1 대화'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('친구 삭제', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _startChat(friend),
    );
  }
}
