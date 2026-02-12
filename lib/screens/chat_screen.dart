import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // TapGestureRecognizer
import 'package:flutter/services.dart'; // Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart'; // 이미지/동영상 저장
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/friend.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_friend_service.dart';
import '../services/notification_service.dart';
import '../services/app_badge_service.dart';
import '../services/chat_state_service.dart';
import '../widgets/invite_friends_dialog.dart';
import 'debug_log_screen.dart';
import '../utils/url_launcher.dart' as url_launcher;
import '../services/safe_browsing_service.dart';

/// 1:1 채팅 화면
class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final String currentUserNickname;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.currentUserNickname,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  int _previousMessageCount = 0; // 이전 메시지 개수 (알림음 재생용)
  bool _showEmojiPicker = false; // 이모티콘 패널 표시 여부
  StreamSubscription? _messagesSubscription;
  StreamSubscription<ChatRoom?>? _chatRoomSubscription;
  late ChatRoom _currentChatRoom; // 채팅방 정보 (업데이트 가능)
  
  // 업로드 중인 임시 메시지 목록 (카카오톡 스타일)
  final List<Map<String, dynamic>> _uploadingMessages = [];
  
  // 자주 사용하는 이모지 목록
  final List<String> _frequentEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
    '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
    '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
    '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '😶‍🌫️', '🥴',
    '😵', '😵‍💫', '🤯', '🤠', '🥳', '😎', '🤓', '🧐',
    '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '🙏',
    '💪', '🦾', '🦿', '🦵', '🦶', '👂', '🦻', '👃',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤',
    '🤍', '💔', '❤️‍🔥', '❤️‍🩹', '💕', '💞', '💓', '💗',
    '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉',
  ];


  @override
  void initState() {
    super.initState();
    _currentChatRoom = widget.chatRoom;
    
    // ⭐ 채팅방 진입 추적 (알림 차단용)
    ChatStateService().enterChatRoom(widget.chatRoom.id);
    
    // 채팅방 정보 실시간 업데이트
    _listenToChatRoom();
    
    // 먼저 메시지 리스닝 시작
    _listenToMessages();
    
    // 그 다음 읽음 처리 (약간의 딜레이 후)
    Future.delayed(const Duration(milliseconds: 500), () {
      _markMessagesAsRead();
    });
  }
  @override
  void dispose() {
    // ⭐ 채팅방 나가기 추적 (알림 재개용)
    ChatStateService().exitChatRoom();
    
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _chatRoomSubscription?.cancel();
    super.dispose();
  }

  /// Firebase 실시간 채팅방 정보 스트림 구독
  void _listenToChatRoom() {
    _chatRoomSubscription = _chatService.getChatRoomStream(widget.chatRoom.id).listen(
      (chatRoom) {
        if (chatRoom != null && mounted) {
          setState(() {
            _currentChatRoom = chatRoom;
          });
          
          if (kDebugMode) {
            debugPrint('🔄 [채팅방 업데이트] 참여자 수: ${chatRoom.participantIds.length}');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ [채팅방 스트림 오류] $error');
        }
      },
    );
  }

  /// Firebase 실시간 메시지 스트림 구독
  void _listenToMessages() {
    setState(() {
      _isLoading = true;
    });

    _messagesSubscription = _chatService.getChatMessagesStream(widget.chatRoom.id).listen(
      (messages) {
        if (mounted) {
          if (kDebugMode) {
            final log1 = '📨 [메시지 스트림] 수신: ${messages.length}개';
            debugPrint(log1);
            DebugLogger.log(log1);
            
            for (var msg in messages) {
              final log2 = '   - ${msg.content}: readBy=${msg.readBy.length}명 ${msg.readBy.join(", ")}';
              debugPrint(log2);
              DebugLogger.log(log2);
            }
          }
          
          // 새 메시지가 도착했는지 확인
          // ⚠️ 채팅방 안에 있을 때는 알림음 재생 안 함 (사용자가 이미 메시지를 보고 있음)
          if (_previousMessageCount > 0 && messages.length > _previousMessageCount) {
            if (kDebugMode) {
              final log3 = '📨 [새 메시지 도착] 채팅방 안에서는 알림음 재생 안 함';
              debugPrint(log3);
              DebugLogger.log(log3);
            }
          }
          
          setState(() {
            _messages = messages;
            _isLoading = false;
            _previousMessageCount = messages.length; // 메시지 개수 업데이트
          });

          // 스크롤을 맨 아래로
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          // 읽음 처리
          _markMessagesAsRead();
        }
      },
      onError: (error) {
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
    final log1 = '📖 [ChatScreen] _markMessagesAsRead 호출';
    final log2 = '   채팅방 ID: ${widget.chatRoom.id}';
    final log3 = '   사용자 ID: ${widget.currentUserId}';
    
    if (kDebugMode) {
      debugPrint(log1);
      debugPrint(log2);
      debugPrint(log3);
      DebugLogger.log(log1);
      DebugLogger.log(log2);
      DebugLogger.log(log3);
    }
    
    await _chatService.markMessagesAsRead(widget.chatRoom.id, widget.currentUserId);
    
    // ⭐ 앱 배지 업데이트
    await AppBadgeService.updateBadge(widget.currentUserId);
    
    final log4 = '✅ [ChatScreen] _markMessagesAsRead 완료';
    if (kDebugMode) {
      debugPrint(log4);
      DebugLogger.log(log4);
    }
  }

  /// 상대방 프로필 사진 가져오기 (1:1 채팅인 경우)
  Future<String?> _getOtherUserProfilePhoto() async {
    // 그룹 채팅인 경우 null 반환
    if (_currentChatRoom.type == ChatRoomType.group) {
      return null;
    }
    
    try {
      // 상대방 ID 찾기
      final otherUserId = _currentChatRoom.participantIds.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );
      
      if (otherUserId.isEmpty) return null;
      
      // Firestore에서 상대방 프로필 사진 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      
      if (userDoc.exists) {
        final profilePhoto = userDoc.data()?['profilePhoto'] as String?;
        if (kDebugMode) {
          debugPrint('📸 [채팅 헤더] 상대방 프로필 사진: ${profilePhoto ?? "없음"}');
        }
        return profilePhoto;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [채팅 헤더] 프로필 사진 조회 실패: $e');
      }
    }
    
    return null;
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    
    if (content.isEmpty) return;

    // 입력 필드 초기화
    _messageController.clear();

    // 현재 사용자의 프로필 사진 가져오기
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

    // 메시지 전송 (프로필 사진 포함)
    final success = await _chatService.sendMessage(
      widget.chatRoom.id,
      widget.currentUserId,
      widget.currentUserNickname,
      content,
      MessageType.text,
      senderProfilePhoto: profilePhoto,
    );

    if (!success) {
      _showSnackBar('메시지 전송에 실패했습니다', isError: true);
    }
    // Firebase 스트림이 자동으로 새 메시지를 받아옴
  }

  /// 첨부 옵션 다이얼로그 표시 (카카오톡 스타일)
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
                    color: Colors.purple.withOpacity(0.1),
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
              // 카메라 (사진 촬영)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
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
              
              // 동영상 촬영 (NEW)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
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
                    color: Colors.orange.withOpacity(0.1),
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
              
              const SizedBox(height: 40), // 하단 여유 공간 추가
            ],
          ),
        ),
      ),
    );
  }

  /// 갤러리에서 이미지 선택
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo, color: Colors.blue[700]),
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
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.videocam, color: Colors.purple[700]),
                  ),
                  title: const Text('동영상'),
                  subtitle: const Text('갤러리에서 동영상 선택'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
                
                const SizedBox(height: 40),  // 하단 여유 공간
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
        maxDuration: const Duration(minutes: 3), // 최대 3분
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

  /// 갤러리에서 동영상 선택
  Future<void> _pickVideoFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        await _uploadAndSendVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 동영상 선택 실패: $e');
      }
      _showSnackBar('동영상을 선택할 수 없습니다', isError: true);
    }
  }

  /// 동영상 업로드 및 메시지 전송
  Future<void> _uploadAndSendVideo(XFile video) async {
    // 임시 메시지 ID 생성
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // 임시 업로드 메시지 추가 (카카오톡 스타일)
    setState(() {
      _uploadingMessages.add({
        'id': tempId,
        'type': 'video',
        'timestamp': DateTime.now(),
      });
    });
    
    try {
      // Firebase Storage에 업로드
      final String fileName = 'chat_videos/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${video.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        // 웹: 바이트 배열로 업로드
        final bytes = await video.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        // 모바일: 파일로 업로드
        await storageRef.putFile(File(video.path));
      }

      // 다운로드 URL 가져오기
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

      // 동영상 메시지 전송 (video 타입으로 전송)
      final success = await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        videoUrl, // 동영상 URL을 content로 전송
        MessageType.video,
        senderProfilePhoto: profilePhoto,
      );

      // 임시 메시지 제거 (업로드 완료)
      setState(() {
        _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
      });

      if (!success) {
        _showSnackBar('동영상 전송 실패', isError: true);
      }
      // 성공 시 실제 메시지가 채팅창에 표시됨
    } catch (e) {
      // 임시 메시지 제거 (에러 발생)
      setState(() {
        _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
      });
      
      if (kDebugMode) {
        debugPrint('❌ 동영상 업로드 실패: $e');
      }
      _showSnackBar('동영상 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// 이미지 업로드 및 메시지 전송
  Future<void> _uploadAndSendImage(XFile image) async {
    // 임시 메시지 ID 생성
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // 임시 업로드 메시지 추가 (카카오톡 스타일)
    setState(() {
      _uploadingMessages.add({
        'id': tempId,
        'type': 'image',
        'timestamp': DateTime.now(),
      });
    });
    
    try {
      // Firebase Storage에 업로드
      final String fileName = 'chat_images/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        // 웹: 바이트 배열로 업로드
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        // 모바일: 파일로 업로드
        await storageRef.putFile(File(image.path));
      }

      // 다운로드 URL 가져오기
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
        imageUrl, // 이미지 URL을 content로 전송
        MessageType.image,
        senderProfilePhoto: profilePhoto,
      );

      // 임시 메시지 제거 (업로드 완료)
      setState(() {
        _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
      });

      if (!success) {
        _showSnackBar('이미지 전송 실패', isError: true);
      }
      // 성공 시 실제 메시지가 채팅창에 표시됨
    } catch (e) {
      // 임시 메시지 제거 (에러 발생)
      setState(() {
        _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
      });
      
      if (kDebugMode) {
        debugPrint('❌ 이미지 업로드 실패: $e');
      }
      _showSnackBar('이미지 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// 파일 선택 및 업로드
  Future<void> _pickFile() async {
    String? tempId; // 임시 메시지 ID
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        // 임시 메시지 ID 생성
        tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        
        // 임시 업로드 메시지 추가 (카카오톡 스타일)
        setState(() {
          _uploadingMessages.add({
            'id': tempId,
            'type': 'file',
            'filename': file.name,
            'timestamp': DateTime.now(),
          });
        });

        // Firebase Storage에 업로드
        final String fileName = 'chat_files/${widget.chatRoom.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        if (kIsWeb) {
          // 웹: 바이트 배열로 업로드
          if (file.bytes != null) {
            await storageRef.putData(file.bytes!);
          } else {
            // 임시 메시지 제거
            setState(() {
              _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
            });
            _showSnackBar('파일을 읽을 수 없습니다', isError: true);
            return;
          }
        } else {
          // 모바일: 파일로 업로드
          if (file.path != null) {
            await storageRef.putFile(File(file.path!));
          } else {
            // 임시 메시지 제거
            setState(() {
              _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
            });
            _showSnackBar('파일 경로를 찾을 수 없습니다', isError: true);
            return;
          }
        }

        // 다운로드 URL 가져오기
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

        // 파일 메시지 전송 (파일명 포함)
        final content = '${file.name}|$fileUrl'; // 파일명과 URL을 구분자로 결합
        final success = await _chatService.sendMessage(
          widget.chatRoom.id,
          widget.currentUserId,
          widget.currentUserNickname,
          content,
          MessageType.file,
          senderProfilePhoto: profilePhoto,
        );

        // 임시 메시지 제거 (업로드 완료)
        setState(() {
          _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
        });

        if (!success) {
          _showSnackBar('파일 전송 실패', isError: true);
        }
        // 성공 시 실제 메시지가 채팅창에 표시됨
      }
    } catch (e) {
      // 임시 메시지 제거 (에러 발생)
      if (tempId != null) {
        setState(() {
          _uploadingMessages.removeWhere((msg) => msg['id'] == tempId);
        });
      }
      
      if (kDebugMode) {
        debugPrint('❌ 파일 업로드 실패: $e');
      }
      _showSnackBar('파일 업로드 실패: ${e.toString()}', isError: true);
    }
  }

  /// Securet 옵션 표시 (비밀대화, 보안통화)
  void _showSecuretOptions() async {
    // 상대방 정보 가져오기
    final otherUserId = _currentChatRoom.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    
    if (otherUserId.isEmpty) {
      _showSnackBar('상대방 정보를 찾을 수 없습니다', isError: true);
      return;
    }
    
    // Firestore에서 상대방의 Securet 정보 가져오기
    String? otherUserQrUrl;
    String? otherUserNickname;
    
    try {
      if (kDebugMode) {
        debugPrint('🔍 [Securet 옵션] 상대방 ID 조회 시작: $otherUserId');
        DebugLogger.log('🔍 [Securet] 상대방 ID: $otherUserId');
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      
      if (userDoc.exists) {
        otherUserQrUrl = userDoc.data()?['qrUrl'] as String?;
        otherUserNickname = userDoc.data()?['nickname'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [Securet 옵션] 상대방 ID: $otherUserId');
          debugPrint('🔍 [Securet 옵션] 상대방 닉네임: $otherUserNickname');
          debugPrint('🔍 [Securet 옵션] 상대방 QR URL: $otherUserQrUrl');
          
          DebugLogger.log('✅ [Securet] 사용자 정보 조회 성공');
          DebugLogger.log('   닉네임: $otherUserNickname');
          DebugLogger.log('   QR URL: ${otherUserQrUrl ?? "(없음)"}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [Securet 옵션] 사용자 문서가 존재하지 않음: $otherUserId');
          DebugLogger.log('⚠️ [Securet] 사용자 문서 없음: $otherUserId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Securet 옵션] 사용자 정보 조회 실패: $e');
        DebugLogger.log('❌ [Securet] 사용자 정보 조회 실패: $e');
      }
    }
    
    // QR URL 검증 강화
    if (otherUserQrUrl == null || otherUserQrUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ [Securet 옵션] QR URL이 없습니다!');
        DebugLogger.log('❌ [Securet] QR URL 없음 - 상대방이 Securet 등록을 하지 않았을 수 있습니다');
      }
      _showSnackBar(
        '상대방이 Securet을 등록하지 않았습니다\n상대방에게 Securet QR 등록을 요청해주세요',
        isError: true,
      );
      return;
    }
    
    // URL 형식 검증
    if (!otherUserQrUrl.startsWith('http://') && !otherUserQrUrl.startsWith('https://')) {
      if (kDebugMode) {
        debugPrint('❌ [Securet 옵션] 잘못된 URL 형식: $otherUserQrUrl');
        DebugLogger.log('❌ [Securet] URL 형식 오류: $otherUserQrUrl');
      }
      _showSnackBar(
        'Securet URL 형식이 올바르지 않습니다\n(Firebase에서 qrUrl 필드를 확인해주세요)',
        isError: true,
      );
      return;
    }
    
    if (!mounted) return;
    
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
              
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Securet 보안 연결',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 설명
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  otherUserNickname != null
                      ? '$otherUserNickname님과 보안 통신을 시작합니다'
                      : '상대방과 보안 통신을 시작합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 비밀대화 버튼
              _buildSecuretOptionTile(
                icon: Icons.lock,
                title: '비밀대화',
                subtitle: '종단간 암호화 메시지',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _launchSecuretChat(otherUserQrUrl);
                },
              ),
              
              const Divider(height: 1),
              
              // 보안통화 버튼
              _buildSecuretOptionTile(
                icon: Icons.phone,
                title: '보안통화',
                subtitle: '암호화된 음성/영상 통화',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _launchSecuretCall(otherUserQrUrl);
                },
              ),
              
              const SizedBox(height: 40), // 하단 여유 공간 추가
            ],
          ),
        ),
      ),
    );
  }
  
  /// 그룹 채팅에서 Securet 보안 통화할 사용자 선택
  void _showGroupSecuretOptions() async {
    // 그룹 참여자 목록 가져오기 (자신 제외)
    final participants = _currentChatRoom.participantIds
        .where((id) => id != widget.currentUserId)
        .toList();
    
    if (participants.isEmpty) {
      _showSnackBar('대화 상대를 찾을 수 없습니다', isError: true);
      return;
    }
    
    // Firestore에서 각 참여자의 정보 가져오기
    final List<Map<String, dynamic>> participantInfoList = [];
    
    for (final userId in participants) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          participantInfoList.add({
            'userId': userId,
            'nickname': data?['nickname'] ?? 'Unknown',
            'qrUrl': data?['qrUrl'] as String?,
            'profilePhoto': data?['profilePhoto'] as String?,
          });
          
          if (kDebugMode) {
            debugPrint('🔍 [그룹 Securet] 사용자 추가: ${data?['nickname']} (${data?['qrUrl']})');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [그룹 Securet] 사용자 정보 조회 실패: $e');
        }
      }
    }
    
    if (participantInfoList.isEmpty) {
      _showSnackBar('참여자 정보를 가져올 수 없습니다', isError: true);
      return;
    }
    
    if (!mounted) return;
    
    // 사용자 선택 다이얼로그 표시 (DraggableScrollableSheet 사용)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        bottom: true,
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,  // 초기 높이 92%
          minChildSize: 0.7,       // 최소 높이 70%
          maxChildSize: 0.95,      // 최대 높이 95%
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // 헤더 (컴팩트)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Securet 보안 통화',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '누구와 1:1 보안 통화를 하시겠습니까?',
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
                
                const SizedBox(height: 16),
                
                // 참여자 리스트 (스크롤 가능)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 200), // 하단 여백 200px
                    itemCount: participantInfoList.length,
                    itemBuilder: (context, index) {
                      final participant = participantInfoList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage: participant['profilePhoto'] != null && 
                                           participant['profilePhoto']!.isNotEmpty
                              ? NetworkImage(participant['profilePhoto']!)
                              : null,
                          child: participant['profilePhoto'] == null || 
                                 participant['profilePhoto']!.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          participant['nickname'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Securet 보안 통화 시작'),
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {
                            Navigator.pop(context);
                            final qrUrl = participant['qrUrl'] as String?;
                            
                            if (kDebugMode) {
                              debugPrint('📞 [그룹 Securet 통화] 선택된 사용자: ${participant['nickname']}');
                              debugPrint('📞 [그룹 Securet 통화] QR URL: $qrUrl');
                            }
                            
                            if (qrUrl == null || qrUrl.isEmpty) {
                              _showSnackBar('${participant['nickname']}님의 Securet 정보가 없습니다', isError: true);
                              return;
                            }
                            
                            // Securet 보안 통화 시작
                            _launchSecuretCall(qrUrl);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          final qrUrl = participant['qrUrl'] as String?;
                          final nickname = participant['nickname'];
                          
                          if (kDebugMode) {
                            debugPrint('💬 [그룹 Securet] 선택된 사용자: $nickname');
                            debugPrint('💬 [그룹 Securet] QR URL: $qrUrl');
                          }
                          
                          if (qrUrl == null || qrUrl.isEmpty) {
                            _showSnackBar('${nickname}님의 Securet 정보가 없습니다', isError: true);
                            return;
                          }
                          
                          // Securet 옵션 다이얼로그 표시
                          _showIndividualSecuretOptions(nickname, qrUrl);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 개별 사용자 Securet 옵션 다이얼로그
  void _showIndividualSecuretOptions(String nickname, String qrUrl) {
    // 변수를 명시적으로 캡처
    final capturedQrUrl = qrUrl;
    final capturedNickname = nickname;
    
    if (kDebugMode) {
      debugPrint('🔐 [개별 Securet 다이얼로그] 닉네임: $capturedNickname');
      debugPrint('🔐 [개별 Securet 다이얼로그] QR URL: $capturedQrUrl');
    }
    
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
              
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Securet 보안 통화',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$capturedNickname님과 보안 통화를 시작합니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 보안 통화 안내
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('종단간 암호화', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('보안 음성 통화', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('통화 내용 비공개', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Securet 앱이 필요합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 통화 시작 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          
                          if (kDebugMode) {
                            debugPrint('📞 [통화 시작 버튼] QR URL: $capturedQrUrl');
                          }
                          
                          _launchSecuretCall(capturedQrUrl);
                        },
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text('통화 시작', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Securet 옵션 타일 위젯
  Widget _buildSecuretOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  /// Securet 비밀대화 시작
  Future<void> _launchSecuretChat(String? otherUserQrUrl) async {
    if (otherUserQrUrl == null || otherUserQrUrl.isEmpty) {
      _showSnackBar('상대방의 Securet 정보가 없습니다', isError: true);
      return;
    }
    
    try {
      if (kDebugMode) {
        debugPrint('🔐 [Securet] 비밀대화 - 원본 URL: $otherUserQrUrl');
        DebugLogger.log('🔐 [Securet 비밀대화] URL: $otherUserQrUrl');
      }
      
      // URL 형식 검증
      if (!otherUserQrUrl.startsWith('http://') && !otherUserQrUrl.startsWith('https://')) {
        if (kDebugMode) {
          debugPrint('❌ [Securet] 잘못된 URL 형식: $otherUserQrUrl');
          DebugLogger.log('❌ [Securet] 잘못된 URL 형식: $otherUserQrUrl');
        }
        _showSnackBar('Securet URL 형식이 올바르지 않습니다', isError: true);
        return;
      }
      
      // ⚡ 가입 시 입력한 원본 Securet URL을 그대로 새 탭/외부 브라우저에서 열기
      await url_launcher.openUrlInNewTab(otherUserQrUrl);
      
      if (kDebugMode) {
        debugPrint('✅ [Securet] 비밀대화 연결 성공');
        DebugLogger.log('✅ [Securet] 비밀대화 연결 성공');
      }
      
      // Securet 비밀대화 실행 (스낵바 제거 - 즉시 새 탭/앱으로 전환)
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Securet] 비밀대화 실행 실패: $e');
        DebugLogger.log('❌ [Securet] 비밀대화 실행 실패: $e');
      }
      _showSnackBar('Securet 연결 실패: ${e.toString()}', isError: true);
    }
  }
  
  /// Securet 보안통화 시작
  Future<void> _launchSecuretCall(String? otherUserQrUrl) async {
    if (otherUserQrUrl == null || otherUserQrUrl.isEmpty) {
      _showSnackBar('상대방의 Securet 정보가 없습니다', isError: true);
      return;
    }
    
    try {
      if (kDebugMode) {
        debugPrint('📞 [Securet] 보안통화 - 원본 URL: $otherUserQrUrl');
        DebugLogger.log('📞 [Securet 보안통화] URL: $otherUserQrUrl');
      }
      
      // URL 형식 검증
      if (!otherUserQrUrl.startsWith('http://') && !otherUserQrUrl.startsWith('https://')) {
        if (kDebugMode) {
          debugPrint('❌ [Securet] 잘못된 URL 형식: $otherUserQrUrl');
          DebugLogger.log('❌ [Securet] 잘못된 URL 형식: $otherUserQrUrl');
        }
        _showSnackBar('Securet URL 형식이 올바르지 않습니다', isError: true);
        return;
      }
      
      // ⚡ 가입 시 입력한 원본 Securet URL을 그대로 새 탭/외부 브라우저에서 열기
      await url_launcher.openUrlInNewTab(otherUserQrUrl);
      
      if (kDebugMode) {
        debugPrint('✅ [Securet] 보안통화 연결 성공');
        DebugLogger.log('✅ [Securet] 보안통화 연결 성공');
      }
      
      if (kIsWeb) {
        _showSnackBar('Securet 보안통화 새 탭에서 열림', isError: false);
      } else {
        _showSnackBar('Securet 앱으로 전환됨', isError: false);
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Securet] 보안통화 실행 실패: $e');
        DebugLogger.log('❌ [Securet] 보안통화 실행 실패: $e');
      }
      
      // 에러 메시지 개선
      String errorMessage = 'Securet 연결 실패';
      if (e.toString().contains('설치되어 있지 않습니다') || 
          e.toString().contains('처리할 앱이 없습니다')) {
        errorMessage = 'Securet 앱이 설치되어 있지 않습니다.\n\nGoogle Play에서 Securet 앱을 설치해 주세요.';
      } else if (e.toString().contains('URL을 열 수 없습니다')) {
        errorMessage = 'Securet URL을 열 수 없습니다.\n\n상대방의 QR URL을 확인해 주세요.';
      } else {
        errorMessage = 'Securet 연결 실패: ${e.toString()}';
      }
      
      _showSnackBar(errorMessage, isError: true);
    }
  }

  /// Securet 보안 대화로 전환
  void _switchToSecuret() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Securet 보안 대화'),
          ],
        ),
        content: const Text(
          '중요한 대화는 Securet 보안 메신저를 전환하여 사용하시기 바랍니다.\n\n'
          '• 종단간 암호화\n'
          '• 보안 쪽지\n'
          '• 보안 대화\n'
          '• 보안 통화',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Securet 연동 기능은 추후 구현 예정입니다');
            },
            icon: const Icon(Icons.security),
            label: const Text('Securet으로 전환'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
    // 채팅방 제목 (1:1은 상대방 이름, 그룹은 그룹 이름)
    final chatTitle = _currentChatRoom.getTitle(widget.currentUserNickname);
    // 참가자 수
    final participantCount = _currentChatRoom.participantIds.length;
    
    if (kDebugMode) {
      debugPrint('🔄 [ChatScreen] build() 호출 - 채팅방 타입: ${_currentChatRoom.type}, 참여자: $participantCount명');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: _getOtherUserProfilePhoto(),
          builder: (context, snapshot) {
            return Row(
              children: [
                // 프로필 사진 (1:1은 상대방 사진, 그룹은 그룹 아이콘) - 클릭 가능
                GestureDetector(
                  onTap: _currentChatRoom.type == ChatRoomType.oneToOne
                      ? _showSecuretOptions
                      : _showGroupSecuretOptions, // 그룹 채팅에서 사용자 선택
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: _currentChatRoom.type == ChatRoomType.oneToOne && 
                                     snapshot.hasData && 
                                     snapshot.data != null && 
                                     snapshot.data!.isNotEmpty
                        ? NetworkImage(snapshot.data!)
                        : null,
                    child: (_currentChatRoom.type == ChatRoomType.group || 
                           !snapshot.hasData || 
                           snapshot.data == null || 
                           snapshot.data!.isEmpty)
                        ? Icon(
                            _currentChatRoom.type == ChatRoomType.group 
                                ? Icons.group 
                                : Icons.person,
                            color: Theme.of(context).primaryColor,
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
                        chatTitle,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentChatRoom.type == ChatRoomType.group
                            ? '$participantCount명'
                            : '온라인',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // 디버그 로그 버튼 (개발 모드에서만 표시)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugLogScreen(),
                  ),
                );
              },
              tooltip: '디버그 로그',
            ),
          // 친구 초대 버튼 (항상 표시)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteFriendsDialog,
            tooltip: '친구 초대',
          ),
          // Securet 보안 대화 전환 버튼
          IconButton(
            icon: const Icon(Icons.security, color: Colors.green),
            onPressed: _switchToSecuret,
            tooltip: 'Securet 보안 대화',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteChat();
              }
            },
            itemBuilder: (context) => [
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
    // 실제 메시지 + 업로드 중 임시 메시지 합치기
    final totalItemCount = _messages.length + _uploadingMessages.length;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        // 실제 메시지 표시
        if (index < _messages.length) {
          final message = _messages[index];
          final isMe = message.senderId == widget.currentUserId;
          return _buildMessageBubble(message, isMe);
        } 
        // 업로드 중 임시 메시지 표시
        else {
          final uploadingIndex = index - _messages.length;
          final uploadingMsg = _uploadingMessages[uploadingIndex];
          return _buildUploadingMessageBubble(uploadingMsg);
        }
      },
    );
  }
  
  /// 업로드 중 메시지 버블 (카카오톡 스타일 점 3개 애니메이션)
  Widget _buildUploadingMessageBubble(Map<String, dynamic> uploadingMsg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업로드 중 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const _UploadingIndicator(),
          ),
        ],
      ),
    );
  }

  /// 메시지 버블 빌드 (카카오톡 스타일: 프로필 사진 + 닉네임)
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상대방 메시지일 때 프로필 사진 표시 (왼쪽) - 클릭 가능
          if (!isMe) ...[
          // 상대방 메시지일 때 프로필 사진 표시 (왼쪽) - 동적 로딩
          if (!isMe) ...[
            _buildProfilePhoto(message),
            const SizedBox(width: 8),
          ],
          ],
          
          // 메시지 내용 영역
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 상대방 메시지일 때 닉네임 표시
                if (!isMe) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderNickname,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
                
                // 메시지 버블 (길게 누르면 복사 메뉴)
                GestureDetector(
                  onLongPress: () => _showCopyMenu(context, message),
                  child: Container(
                    // 이미지/동영상은 padding 없음 (카카오톡 스타일)
                    padding: (message.type == MessageType.image || message.type == MessageType.video)
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    decoration: BoxDecoration(
                      // 이미지/동영상은 배경색 없음 (카카오톡 스타일)
                      color: (message.type == MessageType.image || message.type == MessageType.video)
                          ? Colors.transparent
                          : (isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200]),
                      // 이미지/동영상은 둥근 모서리 없음 (카카오톡 스타일)
                      borderRadius: (message.type == MessageType.image || message.type == MessageType.video)
                          ? BorderRadius.zero
                          : BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 메시지 타입에 따라 다른 위젯 표시
                        if (message.type == MessageType.text)
                          // 텍스트 메시지 (URL 자동 링크)
                          _buildTextMessageWithLinks(message.content, isMe)
                        else if (message.type == MessageType.image)
                          // 이미지 메시지
                          _buildImageMessage(message.content, isMe)
                        else if (message.type == MessageType.file)
                          // 파일 메시지
                          _buildFileMessage(message.content, isMe)
                        else if (message.type == MessageType.video)
                          // 동영상 메시지
                          _buildVideoMessage(message.content, isMe)
                        else if (message.type == MessageType.securet)
                          // Securet 메시지 (기존 로직)
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // 시간 및 읽지 않은 사용자 수 표시
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 읽음 알림 제거 (카카오톡 스타일 - 채팅방 안에서는 표시 안 함)
                      // 시간만 표시
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 입력 영역 빌드
  Widget _buildInputArea() {
    return Column(
      children: [
        // 이모티콘 패널
        // 메시지 입력 영역
        Container(
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
                // + 버튼 (카카오톡 스타일)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  onPressed: _showAttachmentOptions,
                  color: Colors.grey[700],
                ),
                
                // 텍스트 입력 필드
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
                
                // 😊 이모티콘/스티커 버튼 (카카오톡 스타일)
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
          ),
        ),
      ],
    );
  }

  /// 스티커 선택 바텀시트 (카카오톡 스타일)
  /// 이모티콘/스티커 선택 바텀시트 (카카오톡 스타일 탭)
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
                  Tab(icon: Icon(Icons.emoji_emotions), text: '이모티콘'),
                  Tab(icon: Icon(Icons.pets), text: '스티커'),
                ],
              ),
              
              // 탭 컨텐츠
              SizedBox(
                height: 350,
                child: TabBarView(
                  children: [
                    // 😊 일반 이모티콘 탭
                    _buildEmojiGrid(),
                    
                    // 🐱 Firebase 스티커 탭
                    _buildFirebaseStickerGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 😊 일반 이모티콘 그리드
  Widget _buildEmojiGrid() {
    // 자주 사용하는 이모티콘 (확장 가능)
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

  /// 🐱 Firebase 스티커 그리드
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

  /// 기본 스티커 그리드 (Firebase 연결 실패 시 폴백)
  Widget _buildDefaultStickerGrid() {
    // 🎬 투명 배경 애니메이션 스티커 20종 (WebP/APNG 형식 - 카카오톡 스타일)
    final List<Map<String, String>> transparentStickers = [
      // Telegram Sticker 형식 (투명 배경 WebP)
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

  /// 🐱 고양이 스티커 그리드 (이전 버전 - 더 이상 사용 안 함)
  
  /// 스티커를 이미지 메시지로 전송
  Future<void> _sendSticker(String stickerUrl) async {
    if (kDebugMode) {
      debugPrint('🎨 스티커 전송: $stickerUrl');
    }
    
    try {
      // 스티커를 이미지 메시지로 전송
      final success = await _chatService.sendMessage(
        widget.chatRoom.id,
        widget.currentUserId,
        widget.currentUserNickname,
        stickerUrl,  // 스티커 URL
        MessageType.image,  // 이미지 타입으로 전송
      );
      
      if (success) {
        if (kDebugMode) {
          debugPrint('✅ 스티커 전송 완료');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ 스티커 전송 실패');
        }
        
        if (mounted) {
          _showSnackBar('스티커 전송 실패', isError: true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 스티커 전송 오류: $e');
      }
      
      if (mounted) {
        _showSnackBar('스티커 전송 실패', isError: true);
      }
    }
  }

  /// 대화 삭제 확인
  Future<void> _confirmDeleteChat() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 대화를 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.'),
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
        Navigator.pop(context, true); // 삭제 성공 플래그 전달
      } else {
        _showSnackBar('대화 삭제에 실패했습니다', isError: true);
      }
    }
  }

  /// 친구 초대 다이얼로그 표시
  Future<void> _showInviteFriendsDialog() async {
    try {
      // 1. 내 친구 목록 가져오기
      final allFriends = await _friendService.getFriends(widget.currentUserId);
      
      // 2. 현재 채팅방에 없는 친구들만 필터링
      final availableFriends = allFriends.where((friend) {
        return !_currentChatRoom.participantIds.contains(friend.friendId);
      }).toList();

      if (!mounted) return;

      if (availableFriends.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대할 수 있는 친구가 없습니다'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 3. 친구 선택 다이얼로그 표시
      final selectedFriends = await showDialog<List<Friend>>(
        context: context,
        builder: (context) => InviteFriendsDialog(
          availableFriends: availableFriends,
          currentChatRoom: _currentChatRoom,
        ),
      );

      if (selectedFriends == null || selectedFriends.isEmpty) {
        return; // 취소 또는 선택 안 함
      }

      if (!mounted) return;

      // 4. 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 5. 친구 초대 실행
      final newParticipantIds = selectedFriends.map((f) => f.friendId).toList();
      final newParticipantNicknames = selectedFriends.map((f) => f.friendNickname).toList();

      final updatedChatRoom = await _chatService.inviteFriendsToChatRoom(
        _currentChatRoom.id,
        newParticipantIds,
        newParticipantNicknames,
        widget.currentUserNickname,
      );

      if (!mounted) return;

      // 6. 로딩 닫기
      Navigator.of(context).pop();

      // 7. 채팅방 정보 업데이트
      setState(() {
        _currentChatRoom = updatedChatRoom;
      });

      // 8. 성공 로그 (스낵바 제거)
      final invitedNames = newParticipantNicknames.join(', ');

      if (kDebugMode) {
        debugPrint('✅ 친구 초대 성공: $invitedNames');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 초대 실패: $e');
      }

      if (!mounted) return;

      // 로딩 다이얼로그가 열려있으면 닫기
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('친구 초대 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 이미지 메시지 위젯
  /// 이미지 메시지 위젯 (카카오톡 스타일 - 테두리 없음, 원본 비율 유지)
  Widget _buildImageMessage(String imageUrl, bool isMe) {
    // 🐱 스티커 판별 (Emojipedia 또는 Giphy URL인 경우 스티커로 간주)
    final bool isSticker = imageUrl.contains('em-content.zobj.net') || 
                           imageUrl.contains('media.giphy.com');
    
    return GestureDetector(
      onTap: isSticker ? null : () {  // 🔥 스티커는 확대 안 됨!
        // 일반 이미지만 풀스크린 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
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
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 48),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      // 🐱 스티커는 작게, 일반 이미지는 크게
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSticker ? 75 : MediaQuery.of(context).size.width * 0.6,  // 스티커: 75px (50% 감소), 일반: 60%
          maxHeight: isSticker ? 75 : MediaQuery.of(context).size.height * 0.4,  // 스티커: 75px (50% 감소), 일반: 40%
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,  // 원본 비율 유지 (카카오톡 스타일)
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
      ),
    );
  }

  /// 파일 메시지 위젯
  /// 파일 메시지 위젯 (카카오톡 스타일 - 테두리 없는 가로 형태)
  Widget _buildFileMessage(String content, bool isMe) {
    // content 형식: "파일명|파일URL"
    final parts = content.split('|');
    final fileName = parts.isNotEmpty ? parts[0] : '파일';
    final fileUrl = parts.length > 1 ? parts[1] : '';

    return GestureDetector(
      onTap: () {
        if (fileUrl.isNotEmpty) {
          url_launcher.openUrlInNewTab(fileUrl);
        }
      },
      // 카카오톡 스타일: 가로형, 테두리 없음
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,  // 화면의 60%
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : Colors.grey[100],  // 배경색만 있고 테두리 없음
        ),
        child: Row(
          children: [
            // 파일 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[50] : Colors.grey[200],
              ),
              child: Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.blue : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // 파일 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.black87 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '파일',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 다운로드 아이콘
            Icon(
              Icons.file_download_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 동영상 메시지 위젯
  Widget _buildVideoMessage(String videoUrl, bool isMe) {
    return GestureDetector(
      onTap: () {
        // 동영상 재생 (URL 열기)
        url_launcher.openUrlInNewTab(videoUrl);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 동영상 아이콘
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_filled,
                color: isMe ? Colors.white : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            // 동영상 정보
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '동영상',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '탭하여 재생',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.play_arrow,
              color: isMe ? Colors.white : Colors.grey[700],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 사진 위젯 (동적 로딩)
  Widget _buildProfilePhoto(ChatMessage message) {
    // 이미 프로필 사진이 있으면 바로 표시
    if (message.senderProfilePhoto != null && message.senderProfilePhoto!.isNotEmpty) {
      return _buildCircleAvatar(message.senderProfilePhoto);
    }

    // 프로필 사진이 없으면 Firestore에서 가져오기
    return FutureBuilder<String?>(
      future: _getUserProfilePhoto(message.senderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCircleAvatar(null); // 로딩 중에는 기본 아이콘
        }
        return _buildCircleAvatar(snapshot.data);
      },
    );
  }

  /// CircleAvatar 빌드
  Widget _buildCircleAvatar(String? profilePhotoUrl) {
    return GestureDetector(
      onTap: _currentChatRoom.type == ChatRoomType.oneToOne
          ? _showSecuretOptions
          : null,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
            ? NetworkImage(profilePhotoUrl)
            : null,
        child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
            ? const Icon(Icons.person, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  /// Firestore에서 사용자 프로필 사진 가져오기
  Future<String?> _getUserProfilePhoto(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data()?['profilePhoto'] as String?;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 프로필 사진 조회 실패: $e');
      }
    }
    return null;
  }


  /// 읽지 않은 사용자 수 표시
  Widget _buildUnreadCount(ChatMessage message) {
    // 참여자 수 계산
    final totalParticipants = _currentChatRoom.participantIds.length;
    
    // 읽지 않은 사용자 수 계산
    final unreadCount = message.getUnreadCount(totalParticipants);
    
    if (kDebugMode) {
      final log1 = '📊 [읽지 않은 수] 메시지: ${message.content}';
      debugPrint(log1);
      DebugLogger.log(log1);
      final log2 = '📊 [읽지 않은 수] 총 참여자: $totalParticipants';
      debugPrint(log2);
      DebugLogger.log(log2);
      debugPrint('📊 [읽지 않은 수] 읽은 사용자: ${message.readBy.length} (${message.readBy.join(", ")})');
      debugPrint('📊 [읽지 않은 수] 발신자: ${message.senderId}');
      final log5 = '📊 [읽지 않은 수] 읽지 않은 수: $unreadCount';
      debugPrint(log5);
      DebugLogger.log(log5);
    }
    
    // 읽지 않은 사용자가 없으면 빈 위젯 반환
    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }
    
    // 읽지 않은 사용자 수 표시
    return Text(
      '$unreadCount',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
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
      case MessageType.securet:
        copyText = message.content;
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
                    SnackBar(
                      content: Text(isMedia ? 'URL이 복사되었습니다' : '복사되었습니다'),
                      duration: const Duration(seconds: 1),
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
  
  /// 이미지/동영상 갤러리에 저장
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
  
  /// 시간 포맷팅
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    // 1분 미만: "방금"
    if (diff.inSeconds < 60) {
      return '방금';
    }
    
    // 1시간 미만: "HH:MM" 형식으로 정확한 시간 표시 (카카오톡 스타일)
    if (diff.inHours < 1) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      
      // 오전/오후 구분
      if (hour < 12) {
        return '오전 ${hour == 0 ? 12 : hour}:$minute';
      } else {
        return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
      }
    }
    
    // 24시간 이내 (오늘): "오전/오후 HH:MM"
    if (diff.inDays < 1 && timestamp.day == now.day) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      
      if (hour < 12) {
        return '오전 ${hour == 0 ? 12 : hour}:$minute';
      } else {
        return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
      }
    }
    
    // 어제: "어제"
    final yesterday = now.subtract(const Duration(days: 1));
    if (timestamp.year == yesterday.year && 
        timestamp.month == yesterday.month && 
        timestamp.day == yesterday.day) {
      return '어제';
    }
    
    // 7일 이내: "n일 전"
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    
    // 올해: "M월 D일"
    if (timestamp.year == now.year) {
      return '${timestamp.month}월 ${timestamp.day}일';
    }
    
    // 작년 이전: "YYYY년 M월 D일"
    return '${timestamp.year}년 ${timestamp.month}월 ${timestamp.day}일';
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
      return Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: isMe ? Colors.white : Colors.black87,
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
    
    // URL 뒤의 남은 텍스트
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
        ),
      ));
    }
    
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 15),
    );
  }
}

/// 카카오톡 스타일 업로드 중 애니메이션 위젯 (점 3개)
class _UploadingIndicator extends StatefulWidget {
  const _UploadingIndicator();

  @override
  State<_UploadingIndicator> createState() => _UploadingIndicatorState();
}

class _UploadingIndicatorState extends State<_UploadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0, progress),
            const SizedBox(width: 4),
            _buildDot(1, progress),
            const SizedBox(width: 4),
            _buildDot(2, progress),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index, double progress) {
    // 각 점의 활성화 시점 계산 (0 -> 1 -> 2 순서로)
    final dotProgress = (progress * 3) - index;
    final opacity = (dotProgress >= 0 && dotProgress < 1) ? 1.0 : 0.3;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
