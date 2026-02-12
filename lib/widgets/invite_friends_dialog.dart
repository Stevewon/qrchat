import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/chat_room.dart';

/// 친구 초대 다이얼로그 (카카오톡 스타일 - 검색 기능 포함)
/// 
/// 현재 채팅방에 없는 친구들을 선택해서 초대할 수 있습니다.
class InviteFriendsDialog extends StatefulWidget {
  final List<Friend> availableFriends; // 초대 가능한 친구 목록
  final ChatRoom currentChatRoom;      // 현재 채팅방

  const InviteFriendsDialog({
    super.key,
    required this.availableFriends,
    required this.currentChatRoom,
  });

  @override
  State<InviteFriendsDialog> createState() => _InviteFriendsDialogState();
}

class _InviteFriendsDialogState extends State<InviteFriendsDialog> {
  final Set<String> _selectedFriendIds = {};
  final TextEditingController _searchController = TextEditingController();
  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _filteredFriends = widget.availableFriends;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 검색어 변경 처리
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = widget.availableFriends;
      } else {
        _filteredFriends = widget.availableFriends.where((friend) {
          // 이름, 초성으로 검색
          final nickname = friend.friendNickname.toLowerCase();
          return nickname.contains(query) || _getChosung(friend.friendNickname).contains(query);
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
    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // 화면 높이에서 키보드와 여백을 뺀 사용 가능한 높이
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight - 100; // 상하 여백 100px
    
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 40,
        bottom: keyboardHeight + 16, // 키보드 높이만큼 올림
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight, // 동적 높이 제한
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '친구 초대',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 검색바
            if (widget.availableFriends.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름(초성) 검색',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            // 친구 목록 (Flexible로 공간 자동 조절)
            Flexible(
              child: widget.availableFriends.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '초대할 수 있는 친구가 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : _filteredFriends.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                '검색 결과가 없습니다',
                                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero, // 불필요한 패딩 제거
                          itemCount: _filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            final isSelected = _selectedFriendIds.contains(friend.friendId);

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedFriendIds.remove(friend.friendId);
                                  } else {
                                    _selectedFriendIds.add(friend.friendId);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.primary 
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),

                                    // 프로필 이미지 (컬러풀 아바타)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: friend.profilePhoto?.isNotEmpty == true 
                                          ? Colors.grey[300] 
                                          : _getAvatarColor(friend.friendNickname),
                                      backgroundImage: friend.profilePhoto?.isNotEmpty == true 
                                          ? NetworkImage(friend.profilePhoto!) 
                                          : null,
                                      child: friend.profilePhoto?.isNotEmpty != true 
                                          ? Text(
                                              friend.friendNickname.isNotEmpty 
                                                  ? friend.friendNickname[0].toUpperCase() 
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 16, 
                                                fontWeight: FontWeight.bold, 
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // 닉네임 및 상태
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            friend.friendNickname,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Securet 사용자',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // 하단 버튼 (SafeArea 적용)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // 선택 상태 표시
                    Expanded(
                      child: Text(
                        _selectedFriendIds.isEmpty
                            ? '친구를 선택해주세요'
                            : '${_selectedFriendIds.length}명 선택',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedFriendIds.isEmpty 
                              ? FontWeight.normal 
                              : FontWeight.bold,
                          color: _selectedFriendIds.isEmpty 
                              ? Colors.grey[600] 
                              : Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 취소 버튼
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 초대 버튼
                    ElevatedButton(
                      onPressed: _selectedFriendIds.isEmpty
                          ? null
                          : () {
                              // 선택된 친구들의 정보 반환
                              final selectedFriends = widget.availableFriends
                                  .where((f) => _selectedFriendIds.contains(f.friendId))
                                  .toList();
                              
                              Navigator.of(context).pop(selectedFriends);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedFriendIds.isEmpty 
                            ? Colors.grey[300] 
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '초대',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
