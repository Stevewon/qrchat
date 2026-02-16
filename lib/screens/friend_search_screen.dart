import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/securet_user.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';
import 'dart:async';

/// 친구 검색 화면 (카카오톡 스타일)
/// 
/// 실시간 검색으로 한 글자만 입력해도 결과를 보여줍니다.
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final TextEditingController _searchController = TextEditingController();
  
  List<SecuretUser> _searchResults = [];
  bool _isSearching = false;
  String? _currentUserId;
  String? _currentUserNickname;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // 실시간 검색 - 텍스트 변경 시마다 검색
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
        _currentUserNickname = user.nickname;
      });
    }
  }

  /// 검색어 변경 시 실시간 검색 (디바운싱 적용)
  void _onSearchChanged() {
    // 이전 타이머 취소
    _debounceTimer?.cancel();
    
    // 300ms 후에 검색 실행 (타이핑 멈추면 검색)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchFriends();
    });
  }

  /// 닉네임으로 친구 검색 (부분 일치)
  Future<void> _searchFriends() async {
    final query = _searchController.text.trim();
    
    // 빈 검색어는 결과 초기화
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_currentUserId == null) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _friendService.searchUsersByNickname(query, _currentUserId!);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        if (kDebugMode) {
          debugPrint('검색 실패: $e');
        }
      }
    }
  }

  /// 친구 요청 전송
  Future<void> _sendFriendRequest(SecuretUser user) async {
    if (_currentUserId == null || _currentUserNickname == null) {
      _showSnackBar('로그인이 필요합니다');
      return;
    }

    try {
      // 🔧 이미 친구인지 확인
      final friends = await _friendService.getFriends(_currentUserId!);
      final isAlreadyFriend = friends.any((friend) => friend.friendId == user.id);
      
      if (isAlreadyFriend) {
        if (mounted) {
          _showAlreadyFriendDialog(user.nickname);
        }
        return;
      }

      // 친구 요청 전송
      await _friendService.sendFriendRequest(
        _currentUserId!,
        _currentUserNickname!,
        user.id,
        user.nickname,
      );

      // 친구 요청 성공 - 녹색 스낵바 표시
      if (mounted) {
        _showSnackBar('친구추가를 요청하였습니다', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('친구 요청 실패: $e');
      }
    }
  }

  /// 이미 친구입니다 알림
  void _showAlreadyFriendDialog(String friendNickname) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text('$friendNickname님은 이미 친구입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시 (성공 시 녹색, 실패 시 빨간색)
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red, // 성공 시 녹색, 실패 시 빨간색
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          '친구 찾기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          // 카카오톡 스타일 검색창
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '닉네임으로 검색',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),

          // 검색 결과 카운트
          if (_searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _isSearching
                    ? '검색 중...'
                    : _searchResults.isEmpty
                        ? '검색 결과 없음'
                        : '검색 결과 ${_searchResults.length}명',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // 검색 결과 리스트
          Expanded(
            child: _buildSearchResult(),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildSearchResult() {
    // 검색어 없음
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              '닉네임으로 친구를 검색하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '한 글자만 입력해도 검색됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 로딩 중
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '검색 중...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 검색 결과 없음
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 닉네임으로 검색해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 카카오톡 스타일 검색 결과 리스트
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Container(
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                  ? NetworkImage(user.profilePhoto!)
                  : null,
              child: user.profilePhoto == null || user.profilePhoto!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            title: Text(
              user.nickname,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _sendFriendRequest(user),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  '추가',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
