import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/friend.dart';
import '../models/securet_user.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';
import '../services/app_badge_service.dart';
import '../services/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// 그룹 채팅 화면
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

class _GroupChatScreenState extends State<GroupChatScreen> with WidgetsBindingObserver {
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<SecuretUser> _participants = [];
  bool _isLoading = true;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🟢 [GroupChatScreen] initState 시작');
    debugPrint('   채팅방 ID: ${widget.chatRoom.id}');
    debugPrint('   채팅방 이름: ${widget.chatRoom.groupName}');
    debugPrint('   참여자 수: ${widget.chatRoom.participantIds.length}');
    
    // ⭐ 앱 라이프사이클 감지 리스너 추가
    WidgetsBinding.instance.addObserver(this);
    
    // ⭐ 현재 채팅방을 활성 상태로 설정 (알림 음소거)
    LocalNotificationService.setActiveChatRoom(widget.chatRoom.id);
    
    _listenToMessages();
    _loadParticipants();
    _markMessagesAsRead();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('🔵 [앱 라이프사이클] 상태 변경: $state');
    debugPrint('🔵 [앱 라이프사이클] ★★★ v9.3.10 라이프사이클 감지 작동 중! ★★★');
    
    if (state == AppLifecycleState.resumed) {
      // ⭐ 백그라운드에서 포그라운드로 돌아왔을 때
      debugPrint('   📱 포그라운드로 복귀 - 전체 데이터 재로드');
      
      // 🔴 CRITICAL: 비동기 재로드 작업
      _reloadDataOnResume();
    }
  }
  
  /// 포그라운드 복귀 시 데이터 재로드 (비동기)
  Future<void> _reloadDataOnResume() async {
    if (!mounted) return;
    
    debugPrint('🔵 [재로드] 시작...');
    
    // 🔴 CRITICAL: 메시지 목록 클리어 (캐시 제거)
    if (mounted) {
      setState(() {
        _messages.clear(); // 기존 메시지 완전 삭제
        _isLoading = true; // 로딩 상태 표시
      });
    }
    
    // 🔴 CRITICAL 순서: 1) 참여자 정보 먼저 로드
    debugPrint('🔵 [재로드] Step 1: 참여자 정보 로드');
    await _loadParticipants(); // ✅ await 추가!
    debugPrint('✅ [재로드] Step 1 완료: 참여자 ${_participants.length}명');
    
    // 🔴 CRITICAL: 참여자 정보가 로드될 때까지 대기
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 🔴 CRITICAL 순서: 2) 메시지 스트림 재구독
    debugPrint('🔵 [재로드] Step 2: 메시지 스트림 재구독');
    _messagesSubscription?.cancel(); // 기존 스트림 취소
    _listenToMessages(); // 메시지 스트림 재구독
    
    // 🔴 CRITICAL 순서: 3) 읽음 처리
    debugPrint('🔵 [재로드] Step 3: 읽음 처리');
    await _markMessagesAsRead();
    
    debugPrint('✅ [v9.3.12] 포그라운드 복귀: 전체 재로드 완료');
  }

  @override
  void dispose() {
    // ⭐ 라이프사이클 리스너 제거
    WidgetsBinding.instance.removeObserver(this);
    
    // ⭐ 채팅방 나갈 때 활성 상태 해제
    LocalNotificationService.setActiveChatRoom(null);
    
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// 참여자 정보 로드
  Future<void> _loadParticipants() async {
    try {
      debugPrint('🔵 [그룹 채팅] 참여자 정보 로드 시작');
      
      // 🔥 CRITICAL: SecuretUser 정보 직접 로드 (qrUrl 포함)
      final participantUsers = <SecuretUser>[];
      
      for (final participantId in widget.chatRoom.participantIds) {
        if (participantId == widget.currentUserId) continue; // 자신 제외
        
        try {
          final user = await _friendService.getUserById(participantId);
          if (user != null) {
            participantUsers.add(user);
            debugPrint('   ✅ 참여자 로드: ${user.nickname}');
            debugPrint('      프로필: ${user.profilePhoto != null ? "있음" : "없음"}');
            debugPrint('      QR URL: ${user.qrUrl != null && user.qrUrl!.isNotEmpty ? "있음" : "없음"}');
          } else {
            debugPrint('   ⚠️ 참여자 조회 실패: $participantId');
          }
        } catch (e) {
          debugPrint('   ❌ 참여자 조회 오류: $e');
        }
      }
      
      debugPrint('   📊 로드된 참여자 수: ${participantUsers.length}');
      
      setState(() {
        _participants = participantUsers; // 🔥 SecuretUser 직접 사용 (qrUrl 포함)
      });
      
      debugPrint('   ✅ 참여자 정보 로드 완료');
    } catch (e) {
      debugPrint('⚠️ [그룹 채팅] 참여자 정보 로드 실패: $e');
    }
  }

  /// Firebase 실시간 메시지 스트림 구독
  void _listenToMessages() {
    setState(() {
      _isLoading = true;
    });

    debugPrint('🔵 [그룹 채팅] 메시지 스트림 시작: ${widget.chatRoom.id}');
    debugPrint('   채팅방 이름: ${widget.chatRoom.groupName}');
    debugPrint('   참여자 수: ${widget.chatRoom.participantIds.length}');

    _messagesSubscription = _chatService.getChatMessagesStream(widget.chatRoom.id).listen(
      (messages) {
        if (mounted) {
          debugPrint('🔵 [그룹 채팅] 메시지 수신: ${messages.length}개');
          if (messages.isNotEmpty) {
            debugPrint('   최근 메시지: ${messages.last.content}');
            debugPrint('   발신자: ${messages.last.senderNickname}');
          }
          
          setState(() {
            _messages = messages;
            _isLoading = false;
          });

          // 스크롤을 맨 아래로
          if (_messages.isNotEmpty) {
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

          // 읽음 처리
          _markMessagesAsRead();
        }
      },
      onError: (error) {
        debugPrint('❌ [그룹 채팅] 메시지 스트림 오류: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('메시지 로딩 실패: $error', isError: true);
        }
      },
    );
  }

  /// 메시지 읽음 처리
  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatRoom.id, widget.currentUserId);
    
    // ⭐ 앱 배지 업데이트
    await AppBadgeService.updateBadge(widget.currentUserId);
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    
    if (content.isEmpty) return;

    // 로딩 표시를 위해 먼저 클리어
    _messageController.clear();
    
    // 디버그 로그
    debugPrint('🔵 [그룹 채팅] 메시지 전송 시작');
    debugPrint('   채팅방 ID: ${widget.chatRoom.id}');
    debugPrint('   발신자 ID: ${widget.currentUserId}');
    debugPrint('   발신자 닉네임: ${widget.currentUserNickname}');
    debugPrint('   메시지 내용: $content');
    debugPrint('   참여자 수: ${widget.chatRoom.participantIds.length}');

    try {
      // ⭐ 현재 사용자의 프로필 사진 가져오기
      String? currentUserProfilePhoto;
      try {
        final currentUser = await _friendService.getUserById(widget.currentUserId);
        currentUserProfilePhoto = currentUser?.profilePhoto;
        debugPrint('   📸 프로필 사진: ${currentUserProfilePhoto ?? "null"}');
      } catch (e) {
        debugPrint('   ⚠️ 프로필 사진 조회 실패: $e');
      }
      
      final success = await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        content,
        MessageType.text,
        senderProfilePhoto: currentUserProfilePhoto,
      );

      if (success) {
        debugPrint('✅ [그룹 채팅] 메시지 전송 성공');
        debugPrint('   📱 알림이 ${widget.chatRoom.participantIds.length - 1}명에게 전송됩니다');
      } else {
        debugPrint('❌ [그룹 채팅] 메시지 전송 실패 (success = false)');
        _showSnackBar('메시지 전송에 실패했습니다', isError: true);
      }
    } catch (e) {
      debugPrint('❌ [그룹 채팅] 메시지 전송 예외: $e');
      debugPrint('   스택 트레이스: ${StackTrace.current}');
      _showSnackBar('메시지 전송 중 오류: $e', isError: true);
    }
  }

  /// Securet 다이렉트 통화 - 특정 사람 선택
  void _startSecuretDirectCall() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
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
                    size: 28,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '누구와 1:1 보안 통화를 하시겠습니까?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 참여자 목록
            ...widget.chatRoom.participantIds
                .where((id) => id != widget.currentUserId)
                .map((participantId) {
              final index = widget.chatRoom.participantIds.indexOf(participantId);
              final nickname = widget.chatRoom.participantNicknames[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(nickname),
                subtitle: const Text('Securet 보안 통화 시작'),
                trailing: const Icon(Icons.phone, color: Colors.green),
                onTap: () {
                  Navigator.pop(context);
                  _initiateSecuretCall(participantId, nickname);
                },
              );
            }),

            const SizedBox(height: 12),
            
            // 안내 문구
            Container(
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
          ],
        ),
      ),
    );
  }

  /// Securet 통화 시작
  Future<void> _initiateSecuretCall(String participantId, String participantNickname) async {
    debugPrint('\n🔵 [Securet 통화] 시작');
    debugPrint('   참여자 ID: $participantId');
    debugPrint('   참여자 닉네임: $participantNickname');
    
    // 상대방의 Securet QR URL 가져오기
    final participantUser = await _friendService.getUserById(participantId);
    
    debugPrint('   사용자 정보 조회 결과: ${participantUser != null ? "성공" : "실패"}');
    
    if (participantUser == null) {
      debugPrint('❌ [Securet 통화] 사용자 정보 null');
      _showSnackBar('사용자 정보를 가져올 수 없습니다', isError: true);
      return;
    }

    debugPrint('   QR URL: ${participantUser.qrUrl}');
    debugPrint('   QR URL 길이: ${participantUser.qrUrl?.length ?? 0}');
    debugPrint('   프로필 사진: ${participantUser.profilePhoto}');
    debugPrint('   Token: ${participantUser.token}');
    debugPrint('   OS: ${participantUser.os}');
    debugPrint('   VOIP: ${participantUser.voip}');
    
    final qrUrl = participantUser.qrUrl;
    if (qrUrl == null || qrUrl.isEmpty) {
      debugPrint('❌ [Securet 통화] QR URL이 비어있음');
      debugPrint('   - qrUrl == null: ${qrUrl == null}');
      debugPrint('   - qrUrl.isEmpty: ${qrUrl?.isEmpty ?? "null"}');
      debugPrint('   - 사용자 전체 정보:');
      debugPrint('     * ID: ${participantUser.id}');
      debugPrint('     * 닉네임: ${participantUser.nickname}');
      debugPrint('     * QR URL: ${participantUser.qrUrl}');
      
      _showSnackBar(
        '❌ QR URL 없음\n'
        'Firebase에 QR URL이 저장되지 않았습니다.\n'
        '사용자: $participantNickname\n'
        'Securet 앱에서 QR 등록 필요',
        isError: true,
      );
      return;
    }

    debugPrint('✅ [Securet 통화] QR URL 확인 완료 - 바로 실행');
    debugPrint('   URL: ${qrUrl.substring(0, qrUrl.length > 50 ? 50 : qrUrl.length)}...');
    
    // 로딩 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('$participantNickname님과 Securet 통화 연결 중...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // 다이얼로그 없이 바로 Securet 앱 실행
    await _launchSecuretCall(qrUrl);
  }

  /// Securet 앱으로 통화 시작 (QR URL 사용)
  Future<void> _launchSecuretCall(String qrUrl) async {
    try {
      // QR URL에서 파라미터 추출
      final uri = Uri.parse(qrUrl);
      final token = uri.queryParameters['token'] ?? '';
      final voip = uri.queryParameters['voip'] ?? '';
      final os = uri.queryParameters['os'] ?? '';
      
      if (token.isEmpty) {
        _showSnackBar('잘못된 QR URL입니다', isError: true);
        return;
      }

      // Securet 앱 딥링크 생성
      final securetUrl = Uri.parse('securet://call?token=$token&voip=$voip&os=$os');
      
      if (await canLaunchUrl(securetUrl)) {
        await launchUrl(securetUrl, mode: LaunchMode.externalApplication);
      } else {
        // Securet 앱이 없으면 다운로드 페이지로
        final downloadUrl = Uri.parse('https://securet.kr');
        if (await canLaunchUrl(downloadUrl)) {
          await launchUrl(downloadUrl, mode: LaunchMode.externalApplication);
          _showSnackBar('Securet 앱을 먼저 설치해주세요');
        }
      }
    } catch (e) {
      _showSnackBar('Securet 통화 시작 중 오류가 발생했습니다', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.groupName ?? '그룹 채팅',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${widget.chatRoom.participantIds.length}명',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'members') {
                _showMembers();
              } else if (value == 'delete') {
                _confirmDeleteChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 12),
                    Text('참여자 보기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
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
          // 그룹 채팅 안내
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '일반 대화는 여기서! 중요한 대화는 🔒 Securet 통화로!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
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
    );
  }

  /// 빈 상태 빌드
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '첫 메시지를 보내보세요!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 목록 빌드
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

  /// 메시지 버블 빌드 (프로필 사진 + Securet 통화)
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    // 🔔 시스템 메시지 특별 처리 (프로필 사진 없이 중앙 표시)
    // 시스템 메시지 감지: ID, 닉네임, 또는 메시지 내용으로 판단
    
    // 🐛 디버그: 시스템 메시지 감지 로그
    if (kDebugMode) {
      debugPrint('🔍 [시스템 메시지 감지] senderId: ${message.senderId}, nickname: "${message.senderNickname}", content: ${message.content.substring(0, message.content.length > 20 ? 20 : message.content.length)}...');
    }
    
    final isSystemMessage = 
        message.senderId == 'system' || 
        message.senderNickname == '시스템' || 
        message.senderNickname == 'system' ||
        message.senderNickname.trim().isEmpty ||
        message.content.contains('초대했습니다') ||
        message.content.contains('나갔습니다') ||
        message.content.contains('그룹 이름을') ||
        message.content.contains('그룹에 참여했습니다');
    
    if (kDebugMode) {
      debugPrint('🔍 [시스템 메시지 감지] isSystemMessage: $isSystemMessage');
    }
    
    if (isSystemMessage) {
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
              height: 1.3,
            ),
          ),
        ),
      );
    }
    
    // 🔥 CRITICAL FIX: 참여자 목록에서 올바른 사용자 정보 가져오기 (SecuretUser 사용)
    SecuretUser? sender;
    String displayNickname = message.senderNickname;
    String? displayProfilePhoto = message.senderProfilePhoto;
    
    if (!isMe) {
      // 🐛 디버그: 참여자 목록 상태
      if (kDebugMode) {
        debugPrint('🔍 [메시지 표시] 참여자 목록 크기: ${_participants.length}');
        debugPrint('🔍 [메시지 표시] 발신자 ID: ${message.senderId}');
        debugPrint('🔍 [메시지 표시] 발신자 닉네임: ${message.senderNickname}');
      }
      
      // 참여자 목록에서 발신자 정보 찾기
      try {
        sender = _participants.firstWhere((p) => p.id == message.senderId);
        // 참여자 정보가 있으면 그걸 사용 (더 정확함)
        if (sender.nickname.isNotEmpty && sender.nickname != '시스템' && sender.nickname != 'system') {
          displayNickname = sender.nickname;
        }
        if (sender.profilePhoto != null && sender.profilePhoto!.isNotEmpty) {
          displayProfilePhoto = sender.profilePhoto;
        }
        
        if (kDebugMode) {
          debugPrint('✅ [메시지 표시] 참여자 정보 사용: ${sender.nickname}, QR URL: ${sender.qrUrl != null && sender.qrUrl!.isNotEmpty ? "있음" : "없음"}');
        }
      } catch (e) {
        // 참여자 목록에 없으면 메시지의 원본 정보 사용
        if (kDebugMode) {
          debugPrint('⚠️ [메시지 표시] 참여자 목록에 없음, 메시지 정보 사용: ${message.senderNickname}');
          debugPrint('   현재 참여자 목록:');
          for (final p in _participants) {
            debugPrint('   - ${p.id}: ${p.nickname}');
          }
        }
      }
    }
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 프로필 사진 (본인 제외, 왼쪽에만 표시)
            if (!isMe) ...[
              GestureDetector(
                onTap: () => _initiateSecuretCall(message.senderId, displayNickname),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
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
            GestureDetector(
              onLongPress: !isMe ? () => _showMessageContextMenu(message) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // 발신자 이름 (본인 제외)
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
                    
                    // 메시지 버블
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
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

  /// 입력 영역 빌드
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 참여자 보기
  void _showMembers() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 헤더 (아이콘 추가)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '참여자 (${widget.chatRoom.participantIds.length}명)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.chatRoom.participantIds.asMap().entries.map((entry) {
              final index = entry.key;
              final participantId = entry.value;
              final nickname = widget.chatRoom.participantNicknames[index];
              final isMe = participantId == widget.currentUserId;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isMe 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMe
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: isMe 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[700],
                    ),
                  ),
                  title: Text(
                    nickname,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: isMe 
                      ? null 
                      : const Text(
                          '탭하여 Securet 통화 시작',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                  trailing: isMe
                      ? Chip(
                          label: const Text('나', style: TextStyle(fontSize: 12)),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        )
                      : // 🆕 Securet 통화 버튼
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _initiateSecuretCall(participantId, nickname);
                          },
                          tooltip: 'Securet 보안 통화',
                        ),
                  // 🆕 리스트 타일 전체 탭 (본인 제외)
                  onTap: !isMe 
                      ? () {
                          Navigator.pop(context);
                          _initiateSecuretCall(participantId, nickname);
                        }
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 🆕 메시지 컨텍스트 메뉴 (길게 누르기)
  void _showMessageContextMenu(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 - 프로필 사진 포함
            Row(
              children: [
                // 🆕 프로필 사진
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: message.senderProfilePhoto != null && message.senderProfilePhoto!.isNotEmpty
                        ? NetworkImage(message.senderProfilePhoto!)
                        : null,
                    child: message.senderProfilePhoto == null || message.senderProfilePhoto!.isEmpty
                        ? Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderNickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message.content.length > 30
                            ? '${message.content.substring(0, 30)}...'
                            : message.content,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔒 Securet 보안 통화 버튼
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    _initiateSecuretCall(message.senderId, message.senderNickname);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Securet 보안 통화 시작',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '종단간 암호화 1:1 통화',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 대화 삭제 확인
  Future<void> _confirmDeleteChat() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 그룹 채팅을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.'),
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

    if (result == true) {
      final success = await _chatService.deleteChatRoom(widget.chatRoom.id);
      
      if (success && mounted) {
        Navigator.pop(context, true);
      } else {
        _showSnackBar('대화 삭제에 실패했습니다', isError: true);
      }
    }
  }

  /// 시간 포맷팅
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${timestamp.year}-${timestamp.month}-${timestamp.day}';
    }
  }
}
