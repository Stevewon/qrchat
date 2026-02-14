import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/friend.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_friend_service.dart';

/// 그룹 채팅 생성 화면 (카카오톡 스타일 - 검색 기능 포함)
class CreateGroupChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserNickname;

  const CreateGroupChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserNickname,
  });

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final FirebaseChatService _chatService = FirebaseChatService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Friend> _allFriends = [];
  List<Friend> _filteredFriends = [];
  Set<String> _selectedFriendIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final friends = await _friendService.getFriends(widget.currentUserId);
      
      // 🔍 디버그: 프로필 사진 로드 확인
      debugPrint('\n📸 [그룹 초대] 친구 목록 로드 완료: ${friends.length}명');
      for (var friend in friends) {
        debugPrint('   - ${friend.nickname}: profilePhoto=${friend.profilePhoto}');
      }
      
      setState(() {
        _allFriends = friends;
        _filteredFriends = friends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [그룹 초대] 친구 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 검색어 변경 처리
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends.where((friend) {
          // 이름, 초성, 전화번호로 검색
          final nickname = friend.nickname.toLowerCase();
          return nickname.contains(query) || _getChosung(friend.nickname).contains(query);
        }).toList();
      }
    });
  }

  /// 초성 추출 (간단 버전)
  String _getChosung(String text) {
    const chosung = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 
      'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    
    String result = '';
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0xAC00 && code <= 0xD7A3) {
        // 한글 유니코드 범위
        final chosungIndex = ((code - 0xAC00) / 28 / 21).floor();
        result += chosung[chosungIndex];
      } else {
        result += text[i];
      }
    }
    return result.toLowerCase();
  }

  /// 그룹 채팅방 생성
  Future<void> _createGroupChat() async {
    if (_selectedFriendIds.isEmpty) {
      _showSnackBar('최소 1명 이상의 친구를 선택해주세요', isError: true);
      return;
    }

    // 그룹명 입력 다이얼로그
    final groupName = await _showGroupNameDialog();
    if (groupName == null || groupName.trim().isEmpty) {
      return; // 취소 또는 빈 이름
    }

    // 로딩 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 선택된 친구들의 정보 수집
      final selectedFriends = _allFriends.where((f) => _selectedFriendIds.contains(f.id)).toList();
      
      final participantIds = [widget.currentUserId, ..._selectedFriendIds];
      final participantNicknames = [widget.currentUserNickname, ...selectedFriends.map((f) => f.nickname)];

      // 그룹 채팅방 생성
      final chatRoom = await _chatService.createGroupChatRoom(
        participantIds,
        participantNicknames,
        groupName.trim(),
        widget.currentUserId, // 방장은 채팅방을 만든 사람
      );

      if (mounted) {
        // 로딩 닫기
        Navigator.pop(context);
        
        // 생성 완료 - 채팅방으로 이동
        Navigator.pop(context, chatRoom);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        print('❌ [그룹 채팅 생성 오류] $e');
        _showSnackBar('그룹 채팅 생성 실패: $e', isError: true);
      }
    }
  }

  /// 그룹명 입력 다이얼로그
  Future<String?> _showGroupNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 채팅방 이름'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '그룹 채팅방 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시
  /// 에러 스낵바 표시 (성공 메시지는 제거)
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (!isError) return; // 성공 메시지는 표시하지 않음
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 닉네임 기반 색상 생성 (일관된 색상)
  Color _getAvatarColor(String nickname) {
    if (nickname.isEmpty) return Colors.grey;
    
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFF5722), // Deep Orange
    ];
    
    // 닉네임의 해시 코드를 사용하여 색상 선택
    final index = nickname.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '대화상대 초대',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 확인 버튼
          TextButton(
            onPressed: _selectedFriendIds.isEmpty ? null : _createGroupChat,
            child: Text(
              '확인',
              style: TextStyle(
                color: _selectedFriendIds.isEmpty ? Colors.grey : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름(초성), 전화번호 검색',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),

          // 친구 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredFriends.length + 1, // +1 for section headers
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // 섹션 헤더: 친구
                            return Container(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                '친구',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            );
                          }

                          final friend = _filteredFriends[index - 1];
                          final isSelected = _selectedFriendIds.contains(friend.id);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedFriendIds.remove(friend.id);
                                } else {
                                  _selectedFriendIds.add(friend.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // 체크박스 (좌측)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),

                                  // 프로필 이미지
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: friend.profilePhoto?.isNotEmpty == true 
                                        ? Colors.grey[300] 
                                        : _getAvatarColor(friend.nickname),
                                    backgroundImage: friend.profilePhoto?.isNotEmpty == true 
                                        ? NetworkImage(friend.profilePhoto!) 
                                        : null,
                                    child: friend.profilePhoto?.isNotEmpty != true 
                                        ? Text(
                                            friend.nickname.isNotEmpty ? friend.nickname[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // 닉네임
                                  Expanded(
                                    child: Text(
                                      friend.nickname,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 하단 선택 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedFriendIds.isEmpty
                      ? '대화상대를 선택해주세요.'
                      : '${_selectedFriendIds.length}명 선택',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedFriendIds.isEmpty ? FontWeight.normal : FontWeight.bold,
                    color: _selectedFriendIds.isEmpty ? Colors.grey[600] : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 표시
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? '친구가 없습니다'
                : '검색 결과가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              'QR 코드를 스캔하여 친구를 추가하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }
}
