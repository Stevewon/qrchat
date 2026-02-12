import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // TapGestureRecognizer
import 'package:flutter/services.dart'; // Clipboard
import 'dart:async';
import 'dart:io';
import 'package:gal/gal.dart'; // 이미지/동영상 저장
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/friend.dart'; // ⭐ Friend 모델
import '../models/securet_user.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';
import '../services/notification_service.dart';
import '../services/app_badge_service.dart';
import '../services/safe_browsing_service.dart';
import '../services/chat_state_service.dart';
import '../widgets/invite_friends_dialog.dart'; // ⭐ 초대 다이얼로그
import 'package:url_launcher/url_launcher.dart';
import '../utils/url_launcher.dart' as url_launcher;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🐱 스티커 전송용
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 그룹 채팅 화면 (1:1 채팅 구조 기반)
class GroupChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final String currentUserNickname;

  const GroupChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.currentUserNickname,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  Map<String, SecuretUser> _participantsMap = {}; // 🔥 참여자 맵 (userId → SecuretUser)
  bool _isLoading = true;
  int _previousMessageCount = 0;
  StreamSubscription? _messagesSubscription;
  StreamSubscription<ChatRoom?>? _chatRoomSubscription;
  late ChatRoom _currentChatRoom;
  
  // 업로드 중인 임시 메시지 목록 (카카오톡 스타일)
  final List<Map<String, dynamic>> _uploadingMessages = [];

  @override
  void initState() {
    super.initState();
    _currentChatRoom = widget.chatRoom;
    
    // ⭐ 그룹 채팅방 진입 추적 (알림 차단용)
    ChatStateService().enterChatRoom(widget.chatRoom.id);
    
    debugPrint('🟢 [그룹 채팅 v3] initState 시작');
    debugPrint('   채팅방 ID: ${widget.chatRoom.id}');
    debugPrint('   채팅방 이름: ${widget.chatRoom.groupName}');
    debugPrint('   참여자 수: ${widget.chatRoom.participantIds.length}');
    
    // 🔥 재진입 시 안전한 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeChat();
      }
    });
  }
  
  /// 채팅 초기화 (재진입 시에도 안전)
  Future<void> _initializeChat() async {
    debugPrint('🔵 [초기화] 시작...');
    
    // 기존 구독 정리
    await _messagesSubscription?.cancel();
    await _chatRoomSubscription?.cancel();
    
    // ⭐ 일대일 채팅 방식: Firebase 스트림이 자동으로 최신 데이터를 가져옴
    // getChatRoom() 호출 제거 - 불필요한 중복 로딩 방지
    // _listenToChatRoom()이 즉시 최신 데이터를 업데이트함
    
    // 순차 로딩: 스트림 시작 → 참여자 정보 로드 → 메시지 렌더링
    _listenToChatRoom();
    await _initializeDataSequentially();
  }
  
  /// 순차적 데이터 로딩 (참여자 → 메시지 → 읽음 처리)
  Future<void> _initializeDataSequentially() async {
    // 1. 참여자 정보 로드 완료 대기
    await _loadParticipants();
    debugPrint('✅ [초기화] Step 1: 참여자 로드 완료 (${_participantsMap.length}명)');
    
    // 2. 참여자 정보가 준비된 후 메시지 스트림 구독
    _listenToMessages();
    debugPrint('✅ [초기화] Step 2: 메시지 스트림 시작');
    
    // 3. 읽음 처리
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _markMessagesAsRead();
        debugPrint('✅ [초기화] Step 3: 읽음 처리 완료');
      }
    });
  }

  @override
  void dispose() {
    // ⭐ 그룹 채팅방 나가기 추적 (알림 재개용)
    ChatStateService().exitChatRoom();
    
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _chatRoomSubscription?.cancel();
    super.dispose();
  }

  /// 참여자 정보 로드 (1:1의 단순한 구조 유지)
  Future<void> _loadParticipants() async {
    try {
      debugPrint('🔵 [참여자 로드] 시작...');
      
      final Map<String, SecuretUser> participantsMap = {};
      
      // ⭐ 수정: _currentChatRoom 사용 (최신 데이터)
      for (final participantId in _currentChatRoom.participantIds) {
        if (participantId == widget.currentUserId) continue; // 자신 제외
        
        final user = await _friendService.getUserById(participantId);
        if (user != null) {
          participantsMap[participantId] = user;
          debugPrint('   ✅ ${user.nickname} (QR: ${user.qrUrl != null && user.qrUrl!.isNotEmpty ? "O" : "X"})');
        }
      }
      
      if (mounted) {
        setState(() {
          _participantsMap = participantsMap;
        });
      }
      
      debugPrint('✅ [참여자 로드] 완료: ${_participantsMap.length}명');
    } catch (e) {
      debugPrint('❌ [참여자 로드] 실패: $e');
    }
  }

  /// Firebase 실시간 채팅방 정보 스트림 구독 (1:1과 동일)
  void _listenToChatRoom() {
    _chatRoomSubscription = _chatService.getChatRoomStream(widget.chatRoom.id).listen(
      (chatRoom) {
        if (chatRoom != null && mounted) {
          final previousParticipantCount = _currentChatRoom.participantIds.length;
          
          setState(() {
            _currentChatRoom = chatRoom;
          });
          
          debugPrint('🔄 [채팅방 업데이트] 참여자 수: ${chatRoom.participantIds.length}');
          
          // ⭐ 참여자 수가 변경되었을 때만 다시 로드
          if (chatRoom.participantIds.length != previousParticipantCount) {
            debugPrint('🔄 [참여자 변경 감지] 다시 로드');
            _loadParticipants();
          }
        }
      },
      onError: (error) {
        debugPrint('❌ [채팅방 스트림 오류] $error');
      },
    );
  }

  /// Firebase 실시간 메시지 스트림 구독 (1:1과 동일)
  void _listenToMessages() {
    setState(() {
      _isLoading = true;
    });

    _messagesSubscription = _chatService.getChatMessagesStream(widget.chatRoom.id).listen(
      (messages) {
        if (mounted) {
          debugPrint('📨 [메시지 스트림] 수신: ${messages.length}개');
          
          // 새 메시지 알림
          // ⚠️ 채팅방 안에 있을 때는 알림음 재생 안 함 (사용자가 이미 메시지를 보고 있음)
          if (_previousMessageCount > 0 && messages.length > _previousMessageCount) {
            debugPrint('📨 [새 메시지 도착] 그룹 채팅방 안에서는 알림음 재생 안 함');
          }
          
          setState(() {
            _messages = messages;
            _isLoading = false;
            _previousMessageCount = messages.length;
          });
          
          // 스크롤 이동 (1:1과 동일)
          if (messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ [메시지 스트림 오류] $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  /// 메시지 읽음 처리 (1:1과 동일)
  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(
        widget.chatRoom.id,
        widget.currentUserId,
      );
      
      // 배지 업데이트
      await AppBadgeService.updateBadge(widget.currentUserId);
      
      debugPrint('✅ [읽음 처리] 완료');
    } catch (e) {
      debugPrint('❌ [읽음 처리] 실패: $e');
    }
  }

  /// 메시지 전송 (1:1과 동일)
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final currentUser = await SecuretAuthService.getCurrentUser();
      String? currentUserProfilePhoto = currentUser?.profilePhoto;

      await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        content,
        MessageType.text,
        senderProfilePhoto: currentUserProfilePhoto,
      );

      debugPrint('✅ [메시지 전송] 성공');
    } catch (e) {
      debugPrint('❌ [메시지 전송] 실패: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  /// 🐱 스티커 선택 바텀시트 (고양이 감정 GIF 20종)
  void _showStickerPicker() {
    // 키보드 숨김
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 🎨 카카오톡 스타일 탭
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(icon: Icon(Icons.pets), text: '스티커'),
                  Tab(icon: Icon(Icons.emoji_emotions), text: '이모티콘'),
                ],
              ),
              
              // 탭 컨텐츠
              SizedBox(
                height: 350,
                child: TabBarView(
                  children: [
                    // 🐱 Firebase 스티커 탭
                    _buildFirebaseStickerGrid(),
                    
                    // 😊 일반 이모티콘 탭
                    _buildEmojiGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 😊 일반 이모티콘 그리드 (그룹 채팅용)
  Widget _buildEmojiGrid() {
    // 자주 사용하는 이모티콘
    final List<String> emojis = [
      '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆', '😉', '😊',
      '😋', '😎', '😍', '😘', '🥰', '😗', '😙', '😚', '☺️', '🙂',
      '🤗', '🤩', '🤔', '🤨', '😐', '😑', '😶', '🙄', '😏', '😣',
      '😥', '😮', '🤐', '😯', '😪', '😫', '😴', '😌', '😛', '😜',
      '😝', '🤤', '😒', '😓', '😔', '😕', '🙁', '☹️', '😖', '😞',
      '😟', '😤', '😢', '😭', '😦', '😧', '😨', '😩', '🤯', '😬',
      '😰', '😱', '🥵', '🥶', '😳', '🤪', '😵', '🥴', '😠', '😡',
    ];
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            // 이모티콘을 텍스트로 입력창에 추가
            final currentText = _messageController.text;
            _messageController.text = currentText + emojis[index];
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emojis[index],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🐱 Firebase 스티커 그리드 (그룹 채팅용)
  Widget _buildFirebaseStickerGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sticker_packs')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 48),
                const SizedBox(height: 8),
                Text('스티커 로딩 실패: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // 기본 스티커 (Firestore에 데이터 없을 때)
          return _buildDefaultStickerGrid();
        }

        // Firebase에서 로딩한 스티커 팩들
        final stickerPacks = snapshot.data!.docs;
        
        // 모든 스티커팩의 스티커를 하나의 리스트로 합침
        final List<Map<String, dynamic>> allStickers = [];
        for (var pack in stickerPacks) {
          final data = pack.data() as Map<String, dynamic>;
          final stickers = data['stickers'] as List<dynamic>? ?? [];
          allStickers.addAll(stickers.cast<Map<String, dynamic>>());
        }

        if (allStickers.isEmpty) {
          return _buildDefaultStickerGrid();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: allStickers.length,
          itemBuilder: (context, index) {
            final sticker = allStickers[index];
            final imageUrl = sticker['image_url'] as String;
            final stickerName = sticker['sticker_name'] as String? ?? '스티커';
            
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _sendSticker(imageUrl);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey[400]),
                            Text(stickerName, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 기본 스티커 그리드 (Firebase 연결 실패 시 폴백 - 그룹 채팅용)
  Widget _buildDefaultStickerGrid() {
    // 🎬 투명 배경 애니메이션 스티커 20종
    final List<Map<String, String>> transparentStickers = [
      {'name': '행복한 고양이', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Animals/Cat.png'},
      {'name': '웃는 얼굴', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Grinning%20Face.png'},
      {'name': '하트 눈', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Smiling%20Face%20with%20Heart-Eyes.png'},
      {'name': '웃음', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Face%20with%20Tears%20of%20Joy.png'},
      {'name': '윙크', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Winking%20Face.png'},
      {'name': '파티', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Partying%20Face.png'},
      {'name': '별', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Glowing%20Star.png'},
      {'name': '하트', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Heart%20Hands.png'},
      {'name': '박수', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Clapping%20Hands.png'},
      {'name': '좋아요', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Thumbs%20Up.png'},
      {'name': '불', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Fire.png'},
      {'name': '폭죽', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Activities/Party%20Popper.png'},
      {'name': '선물', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Wrapped%20Gift.png'},
      {'name': '트로피', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Activities/Trophy.png'},
      {'name': '왕관', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Crown.png'},
      {'name': '로켓', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png'},
      {'name': '번개', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/High%20Voltage.png'},
      {'name': '무지개', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rainbow.png'},
      {'name': '달', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Crescent%20Moon.png'},
      {'name': '해', 'url': 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Sun.png'},
    ];
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: transparentStickers.length,
      itemBuilder: (context, index) {
        final sticker = transparentStickers[index];
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            _sendSticker(sticker['url']!);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                sticker['url']!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🐱 스티커 전송 (이미지 메시지로 전송)
  Future<void> _sendSticker(String stickerUrl) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Firestore에서 사용자 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final profilePhoto = userDoc.data()?['profilePhoto'] as String?;

      // 스티커를 이미지 메시지로 전송
      await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .add({
        'type': MessageType.image.toString().split('.').last,
        'content': stickerUrl,  // GIF URL
        'senderId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'profilePhoto': profilePhoto,
      });

      // 마지막 메시지 업데이트
      await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.chatRoom.id)
          .update({
        'last_message': '🐱 고양이 스티커',
        'last_message_time': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ [스티커 전송] 성공: $stickerUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [스티커 전송] 실패: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스티커 전송 실패: $e')),
        );
      }
    }
  }

  /// 친구 초대 기능
  Future<void> _inviteFriends() async {
    // 초대 가능한 친구 목록 (현재 참여자 제외)
    final allFriends = await _friendService.getFriends(widget.currentUserId);
    
    // Friend 타입으로 변환 (현재 참여자 제외)
    final availableFriends = allFriends
        .where((friend) => !_currentChatRoom.participantIds.contains(friend.friendId))
        .toList();
    
    if (availableFriends.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대할 수 있는 친구가 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // 초대 다이얼로그 표시
    if (!mounted) return;
    final selectedFriends = await showDialog<List<dynamic>>(
      context: context,
      builder: (context) => InviteFriendsDialog(
        availableFriends: availableFriends,
        currentChatRoom: _currentChatRoom,
      ),
    );
    
    if (selectedFriends == null || selectedFriends.isEmpty) return;
    
    // Firebase에 참여자 추가
    try {
      // Friend 객체에서 friendId 추출
      final selectedFriendIds = selectedFriends
          .map((f) => f.friendId as String)
          .toList();
      
      final updatedParticipantIds = [
        ..._currentChatRoom.participantIds,
        ...selectedFriendIds,
      ];
      
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoom.id)
          .update({
        'participantIds': updatedParticipantIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedFriends.length}명의 친구를 초대했습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 초대 실패: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 초대에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  /// Securet 보안 통화 참여자 선택
  void _startSecuretDirectCall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        bottom: true,  // Safe Area 하단 적용
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,  // 초기 높이 92%로 최대화
          minChildSize: 0.7,       // 최소 높이 70%로 증가
          maxChildSize: 0.95,      // 최대 높이 95% 유지
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),  // 하단 패딩 증가
            child: Column(
              children: [
                // 핸들
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 헤더 (컴팩트하게)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.green,
                        size: 24,  // 아이콘 크기 축소
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Securet 보안 통화',
                            style: TextStyle(
                              fontSize: 17,  // 폰트 크기 축소
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '누구와 1:1 보안 통화를 하시겠습니까?',
                            style: TextStyle(
                              fontSize: 12,  // 폰트 크기 축소
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 참여자 목록 (스크롤 가능, 하단 여백 추가)
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 200), // 하단 여백 200px (더 넉넉하게)
                    children: [
                      ..._participantsMap.entries.map((entry) {
                        final participantId = entry.key;
                        final participant = entry.value;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            backgroundImage: participant.profilePhoto != null && participant.profilePhoto!.isNotEmpty
                                ? NetworkImage(participant.profilePhoto!)
                                : null,
                            child: participant.profilePhoto == null || participant.profilePhoto!.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                          title: Text(participant.nickname),
                          subtitle: const Text('Securet 보안 통화 시작'),
                          trailing: const Icon(Icons.phone, color: Colors.green),
                          onTap: () {
                            Navigator.pop(context);
                            _initiateSecuretCall(participantId, participant.nickname);
                          },
                        );
                      }),
                      
                      const SizedBox(height: 12),
                      
                      // 안내 문구
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '종단간 암호화된 보안 통화가 시작됩니다',
                                style: TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 하단 여백은 ListView padding으로 처리
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Securet 통화 시작 (1:1과 동일한 로직)
  Future<void> _initiateSecuretCall(String participantId, String participantNickname) async {
    debugPrint('🔵 [Securet 통화] 시작');
    debugPrint('   참여자 ID: $participantId');
    debugPrint('   참여자 닉네임: $participantNickname');
    
    // 🔥 참여자 맵에서 정보 가져오기
    final participantUser = _participantsMap[participantId];
    
    if (participantUser == null) {
      debugPrint('❌ [Securet 통화] 참여자 정보 없음 (맵에서)');
      
      // 실시간으로 다시 로드 시도
      final user = await _friendService.getUserById(participantId);
      if (user == null) {
        _showSnackBar('사용자 정보를 가져올 수 없습니다', isError: true);
        return;
      }
      
      // 맵에 추가
      setState(() {
        _participantsMap[participantId] = user;
      });
      
      debugPrint('✅ [Securet 통화] 실시간 로드 성공');
    }

    final qrUrl = _participantsMap[participantId]?.qrUrl;
    
    debugPrint('🔍 [Securet 통화] QR URL 체크:');
    debugPrint('   QR URL: ${qrUrl ?? "null"}');
    debugPrint('   QR URL 길이: ${qrUrl?.length ?? 0}');
    debugPrint('   isEmpty: ${qrUrl?.isEmpty ?? true}');
    
    // QR URL 존재 여부 검증
    if (qrUrl == null || qrUrl.isEmpty) {
      debugPrint('❌ [Securet 통화] QR URL 없음');
      _showSnackBar(
        '$participantNickname님이 Securet을 등록하지 않았습니다\n상대방에게 Securet QR 등록을 요청해주세요',
        isError: true,
      );
      return;
    }
    
    // URL 형식 검증
    if (!qrUrl.startsWith('http://') && !qrUrl.startsWith('https://')) {
      debugPrint('❌ [Securet 통화] 잘못된 URL 형식: $qrUrl');
      _showSnackBar(
        'Securet URL 형식이 올바르지 않습니다\n(Firebase에서 qrUrl 필드를 확인해주세요)',
        isError: true,
      );
      return;
    }

    debugPrint('✅ [Securet 통화] QR URL 확인 완료');
    debugPrint('   전체 QR URL: $qrUrl');
    
    // 로딩 표시
    // Securet 통화 연결 (스낵바 제거)
    
    // Securet 앱 실행
    await _launchSecuretCall(qrUrl);
  }

  /// Securet 앱으로 통화 시작 (1:1과 동일)
  Future<void> _launchSecuretCall(String qrUrl) async {
    try {
      debugPrint('🚀 [Securet 실행] 시작');
      debugPrint('   입력 QR URL: $qrUrl');
      
      // URL 형식 검증
      if (!qrUrl.startsWith('http://') && !qrUrl.startsWith('https://')) {
        debugPrint('❌ [Securet 실행] 잘못된 URL 형식: $qrUrl');
        throw 'Securet URL 형식이 올바르지 않습니다';
      }
      
      debugPrint('🚀 [Securet 실행] URL 형식 검증 완료');
      
      // ⚡ 1:1 채팅과 동일: 원본 Securet URL을 그대로 새 탭/외부 브라우저에서 열기
      await url_launcher.openUrlInNewTab(qrUrl);
      
      debugPrint('✅ [Securet 실행] 성공');
      
      // Securet 보안통화 연결 성공 (스낵바 제거)
    } catch (e, stackTrace) {
      debugPrint('❌ [Securet 실행] 실패: $e');
      debugPrint('❌ [Securet 실행] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Securet 연결 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentChatRoom.groupName ?? '그룹 채팅',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${_currentChatRoom.participantIds.length}명',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          // ⭐ 친구 초대 버튼
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: '친구 초대',
            onPressed: _inviteFriends,
          ),
          // 참여자 목록 및 Securet 통화
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '참여자 목록',
            onPressed: _startSecuretDirectCall,
          ),
          // 추가 메뉴
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                // 대화 삭제 확인 다이얼로그
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('대화 삭제'),
                    content: const Text('이 대화방을 나가시겠습니까?\n\n대화 내용은 유지되며, 다시 초대받을 수 있습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('나가기', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  // 대화방 나가기
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('대화방을 나갔습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('대화 삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 그룹 채팅 참여자 안내 (일대일 채팅 스타일)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.teal.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.group, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildParticipantNames(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 메시지 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),

          // 입력 영역
          _buildInputArea(),
        ],
      ),
      ),
    );
  }

  /// 참여자 이름 표시 (일대일 채팅 스타일)
  String _buildParticipantNames() {
    if (_participantsMap.isEmpty) {
      return '${_currentChatRoom.participantIds.length}명이 참여 중인 그룹 채팅입니다';
    }
    
    // 자신을 제외한 참여자 목록
    final otherParticipants = _participantsMap.values
        .where((user) => user.id != widget.currentUserId)
        .toList();
    
    if (otherParticipants.isEmpty) {
      return '나만 있는 그룹 채팅입니다';
    }
    
    // 최대 3명까지 이름 표시
    final displayCount = otherParticipants.length > 3 ? 3 : otherParticipants.length;
    final names = otherParticipants
        .take(displayCount)
        .map((user) => user.nickname)
        .join(', ');
    
    if (otherParticipants.length > 3) {
      final remaining = otherParticipants.length - 3;
      return '$names 외 ${remaining}명';
    }
    
    return names;
  }

  /// 빈 상태 (1:1과 동일)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 메시지를 보내보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 목록 (1:1과 동일)
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.currentUserId;
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  /// 메시지 버블 (1:1 기반 + 그룹 기능 추가)
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    // 시스템 메시지 처리
    if (message.senderId == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
    }

    // 🔥 참여자 정보 가져오기 (맵에서)
    final sender = _participantsMap[message.senderId];
    final displayNickname = sender?.nickname ?? message.senderNickname;
    final displayProfilePhoto = sender?.profilePhoto ?? message.senderProfilePhoto;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 사진 (타인만)
            if (!isMe) ...[
              GestureDetector(
                onTap: () => _initiateSecuretCall(message.senderId, displayNickname),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: displayProfilePhoto != null && displayProfilePhoto.isNotEmpty
                        ? NetworkImage(displayProfilePhoto)
                        : null,
                    child: displayProfilePhoto == null || displayProfilePhoto.isEmpty
                        ? Text(
                            displayNickname.isNotEmpty ? displayNickname[0] : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
            
            // 메시지 내용
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 닉네임 (타인만)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        displayNickname,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  
                  // 메시지 버블 (길게 누르면 복사 메뉴)
                  if (message.type == MessageType.image)
                    // 이미지 메시지 (클릭 시 확대, 길게 누르면 복사) - 테두리 없음
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, message.content),
                      onLongPress: () => _showCopyMenu(context, message),
                      child: _buildImageMessage(message.content),  // 🎨 스티커 구분 로직 적용
                    )
                  else if (message.type == MessageType.video)
                    // 동영상 메시지 (길게 누르면 복사) - 테두리 없음
                    GestureDetector(
                      onLongPress: () => _showCopyMenu(context, message),
                      child: Container(
                      width: 200,
                      height: 200,
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Colors.black54,
                              child: const Text(
                                '동영상',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  else if (message.type == MessageType.file)
                    // 파일 메시지 (길게 누르면 복사)
                    GestureDetector(
                      onLongPress: () => _showCopyMenu(context, message),
                      child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMe ? Colors.white : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.content.split('|').first,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  else
                    // 텍스트 메시지 (URL 링크 포함, 길게 누르면 복사)
                    GestureDetector(
                      onLongPress: () => _showCopyMenu(context, message),
                      child: _buildTextMessageWithLinks(message.content, isMe),
                    ),
                  
                  // 시간
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 입력 영역 (1:1과 동일)
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // + 버튼 (파일 첨부)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: _showAttachmentOptions,
            color: Colors.grey[700],
          ),
          
          // 텍스트 입력 (1:1과 동일한 스타일)
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          
          // 😊 이모티콘/스티커 버튼 (1:1과 동일 위치)
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, size: 28),
            onPressed: _showStickerPicker,
            color: Colors.grey[700],
            tooltip: '이모티콘',
          ),
          
          const SizedBox(width: 4),
          
          // 전송 버튼 (이쁜 동그라미 테두리 디자인)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  /// 파일 첨부 옵션 표시 (1:1과 동일)
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 앨범 (갤러리)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple, size: 24),
                ),
                title: const Text('앨범', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: const Text('사진/동영상 선택', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              
              // 카메라
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue, size: 24),
                ),
                title: const Text('카메라', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: const Text('사진 촬영', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              
              // 동영상 촬영
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam, color: Colors.red, size: 24),
                ),
                title: const Text('동영상 촬영', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: const Text('동영상 녹화', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideoFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.insert_drive_file, color: Colors.orange, size: 24),
                ),
                title: const Text('파일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: const Text('문서, PDF 등', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 갤러리에서 사진/동영상 선택
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // 먼저 사진 또는 동영상 선택 다이얼로그 표시
      final mediaType = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 헤더
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '미디어 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // 사진 선택
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo, color: Colors.blue),
                  ),
                  title: const Text('사진'),
                  subtitle: const Text('갤러리에서 사진 선택'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                
                // 동영상 선택
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.purple),
                  ),
                  title: const Text('동영상'),
                  subtitle: const Text('갤러리에서 동영상 선택'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

      if (mediaType == null) return;

      if (mediaType == 'image') {
        // 사진 선택
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          await _uploadAndSendImage(image);
        }
      } else if (mediaType == 'video') {
        // 동영상 선택
        final XFile? video = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 3),
        );

        if (video != null) {
          await _uploadAndSendVideo(video);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 미디어 선택 실패: $e');
      }
      _showSnackBar('미디어를 선택할 수 없습니다', isError: true);
    }
  }

  /// 카메라로 사진 촬영
  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendImage(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 사진 촬영 실패: $e');
      }
      _showSnackBar('사진을 촬영할 수 없습니다', isError: true);
    }
  }

  /// 카메라로 동영상 촬영
  Future<void> _pickVideoFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 3),
      );

      if (video != null) {
        await _uploadAndSendVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 동영상 촬영 실패: $e');
      }
      _showSnackBar('동영상을 촬영할 수 없습니다', isError: true);
    }
  }

  /// 파일 선택 및 업로드
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        // 파일 업로드 시작 (스낵바 제거)

        // Firebase Storage에 업로드
        final String fileName = 'chat_files/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        if (kIsWeb) {
          if (file.bytes != null) {
            await storageRef.putData(file.bytes!);
          } else {
            _showSnackBar('파일을 읽을 수 없습니다', isError: true);
            return;
          }
        } else {
          if (file.path != null) {
            await storageRef.putFile(File(file.path!));
          } else {
            _showSnackBar('파일 경로를 찾을 수 없습니다', isError: true);
            return;
          }
        }

        final String fileUrl = await storageRef.getDownloadURL();

        if (kDebugMode) {
          debugPrint('✅ 파일 업로드 성공: $fileUrl');
        }

        // 프로필 사진 가져오기
        String? profilePhoto;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .get();
          if (userDoc.exists) {
            profilePhoto = userDoc.data()?['profilePhoto'] as String?;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 프로필 사진 조회 실패: $e');
          }
        }

        // 파일 메시지 전송
        final success = await _chatService.sendMessage(
          widget.chatRoom.id,
          widget.currentUserId,
          widget.currentUserNickname,
          '${file.name}|$fileUrl',
          MessageType.file,
          senderProfilePhoto: profilePhoto,
        );

        if (!success) {
          _showSnackBar('파일 전송 실패', isError: true);
        }
        // 성공 시 스낵바 제거 - 메시지가 즉시 채팅창에 표시됨
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 파일 업로드 실패: $e');
      }
      _showSnackBar('파일 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// 이미지 업로드 및 메시지 전송
  Future<void> _uploadAndSendImage(XFile image) async {
    try {
      // 이미지 업로드 시작 (스낵바 제거)

      // Firebase Storage에 업로드
      final String fileName = 'chat_images/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(File(image.path));
      }

      final String imageUrl = await storageRef.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ 이미지 업로드 성공: $imageUrl');
      }

      // 프로필 사진 가져오기
      String? profilePhoto;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        if (userDoc.exists) {
          profilePhoto = userDoc.data()?['profilePhoto'] as String?;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ 프로필 사진 조회 실패: $e');
        }
      }

      // 이미지 메시지 전송
      final success = await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        imageUrl,
        MessageType.image,
        senderProfilePhoto: profilePhoto,
      );

      if (!success) {
        _showSnackBar('이미지 전송 실패', isError: true);
      }
      // 성공 시 스낵바 제거 - 메시지가 즉시 채팅창에 표시됨
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 이미지 업로드 실패: $e');
      }
      _showSnackBar('이미지 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// 동영상 업로드 및 메시지 전송
  Future<void> _uploadAndSendVideo(XFile video) async {
    try {
      // 동영상 업로드 시작 (스낵바 제거)

      // Firebase Storage에 업로드
      final String fileName = 'chat_videos/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${video.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        final bytes = await video.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(File(video.path));
      }

      final String videoUrl = await storageRef.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ 동영상 업로드 성공: $videoUrl');
      }

      // 프로필 사진 가져오기
      String? profilePhoto;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        if (userDoc.exists) {
          profilePhoto = userDoc.data()?['profilePhoto'] as String?;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ 프로필 사진 조회 실패: $e');
        }
      }

      // 동영상 메시지 전송
      final success = await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        videoUrl,
        MessageType.video,
        senderProfilePhoto: profilePhoto,
      );

      if (!success) {
        _showSnackBar('동영상 전송 실패', isError: true);
      }
      // 성공 시 스낵바 제거 - 메시지가 즉시 채팅창에 표시됨
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 동영상 업로드 실패: $e');
      }
      _showSnackBar('동영상 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// 메시지 복사 메뉴 표시 (카카오톡 스타일)
  void _showCopyMenu(BuildContext context, ChatMessage message) {
    String copyText = '';
    bool isMedia = false; // 이미지/동영상 여부
    
    // 메시지 타입에 따라 복사할 텍스트 결정
    switch (message.type) {
      case MessageType.text:
        copyText = message.content;
        break;
      case MessageType.image:
        copyText = message.content; // 이미지 URL
        isMedia = true;
        break;
      case MessageType.video:
        copyText = message.content; // 동영상 URL
        isMedia = true;
        break;
      case MessageType.file:
        // 파일명|URL 형식에서 URL만 추출
        final parts = message.content.split('|');
        copyText = parts.length > 1 ? parts[1] : message.content;
        break;
      default:
        copyText = message.content;
    }
    
    // 복사 메뉴 다이얼로그 (카카오톡 스타일)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 핸들
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 이미지/동영상일 때 저장하기 버튼
            if (isMedia)
              ListTile(
                leading: Icon(
                  message.type == MessageType.image ? Icons.download : Icons.video_library,
                  color: Colors.blue,
                ),
                title: Text(
                  message.type == MessageType.image ? '이미지 저장하기' : '동영상 저장하기',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveMediaToGallery(copyText, message.type);
                },
              ),
            
            // 복사 버튼 (텍스트는 "복사하기", 미디어는 "URL 복사하기")
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.black87),
              title: Text(
                isMedia ? 'URL 복사하기' : '복사하기',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                // 클립보드에 복사
                await Clipboard.setData(ClipboardData(text: copyText));
                
                // 다이얼로그 닫기
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // 복사 완료 피드백 (간단한 스낵바)
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('복사되었습니다'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            
            // 취소 버튼
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text(
                '취소',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              onTap: () => Navigator.pop(context),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 이미지/동영상을 갤러리에 저장
  Future<void> _saveMediaToGallery(String url, MessageType type) async {
    try {
      if (kDebugMode) {
        print('💾 미디어 저장 시작: $url (타입: $type)');
      }
      
      // 네트워크에서 파일 다운로드
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final fileName = 'qrchat_${DateTime.now().millisecondsSinceEpoch}.${type == MessageType.image ? 'jpg' : 'mp4'}';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        // gal 패키지로 갤러리에 저장
        await Gal.putImage(file.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(type == MessageType.image ? '이미지가 갤러리에 저장되었습니다' : '동영상이 갤러리에 저장되었습니다'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (kDebugMode) {
          print('✅ 미디어 저장 성공: ${file.path}');
        }
        
        // 임시 파일 삭제
        await file.delete();
      } else {
        throw Exception('다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 미디어 저장 실패: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 스낵바 표시
  /// 시간 포맷 (1:1과 동일)
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(time);
    
    // 1분 미만: "방금"
    if (diff.inSeconds < 60) {
      return '방금';
    }
    
    // 1시간 미만: "오전/오후 HH:MM" 형식으로 정확한 시간 표시
    if (diff.inHours < 1) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        return '오전 ${hour == 0 ? 12 : hour}:$minute';
      } else {
        return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
      }
    }
    
    // 24시간 이내 (오늘): "오전/오후 HH:MM"
    if (diff.inDays < 1 && time.day == now.day) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        return '오전 ${hour == 0 ? 12 : hour}:$minute';
      } else {
        return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
      }
    }
    
    // 어제: "어제"
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year && 
        time.month == yesterday.month && 
        time.day == yesterday.day) {
      return '어제';
    }
    
    // 7일 이내: "n일 전"
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    
    // 올해: "M월 D일"
    if (time.year == now.year) {
      return '${time.month}월 ${time.day}일';
    }
    
    // 작년 이전: "YYYY년 M월 D일"
    return '${time.year}년 ${time.month}월 ${time.day}일';
  }

  /// 전체 화면 이미지 보기
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// URL이 포함된 텍스트 메시지 (카카오톡 스타일 링크)
  Widget _buildTextMessageWithLinks(String content, bool isMe) {
    // URL 정규식 패턴
    final urlPattern = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    
    // URL이 없으면 일반 텍스트 반환
    if (!urlPattern.hasMatch(content)) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      );
    }
    
    // URL과 텍스트를 분리하여 표시
    final spans = <TextSpan>[];
    final matches = urlPattern.allMatches(content);
    int lastMatchEnd = 0;
    
    for (final match in matches) {
      // URL 앞의 일반 텍스트
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ));
      }
      
      // URL 링크 (파란색 + 밑줄)
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: isMe ? Colors.lightBlueAccent : Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            // Google Safe Browsing으로 유해 URL 검사
            final isSafe = await SafeBrowsingService.isUrlSafe(url);
            
            if (!isSafe) {
              // 유해 사이트 차단 다이얼로그
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        SizedBox(width: 8),
                        Text('⚠️ 유해 사이트 차단'),
                      ],
                    ),
                    content: Text(SafeBrowsingService.getBlockedUrlMessage(url)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
            
            // 안전한 URL이면 새창에서 열기 (카카오톡 스타일)
            url_launcher.openUrlInNewTab(url);
          },
      ));
      
      lastMatchEnd = match.end;
    }
    
    // 마지막 URL 뒤의 텍스트
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
        ),
      ));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).primaryColor
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  /// 🎨 이미지 메시지 빌더 (스티커 vs 일반 이미지 구분)
  Widget _buildImageMessage(String imageUrl) {
    // Firebase Storage의 stickers 폴더 = 스티커로 간주
    final isSticker = imageUrl.contains('/stickers/');
    
    // 🔥 스티커는 SizedBox로 강제 크기 지정!
    return SizedBox(
      width: isSticker ? 75 : 200,
      height: isSticker ? 75 : 200,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,  // 원본 비율 유지
        width: isSticker ? 75 : 200,  // 🔥 이미지 자체 크기도 지정!
        height: isSticker ? 75 : 200,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: isSticker ? 75 : 200,
            height: isSticker ? 75 : 200,
            color: isSticker ? Colors.transparent : Colors.grey[200],  // 🎨 스티커는 투명 배경
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: isSticker ? 75 : 200,
            height: isSticker ? 75 : 200,
            color: isSticker ? Colors.transparent : Colors.grey[200],  // 🎨 스티커는 투명 배경
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text('이미지 로드 실패', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
