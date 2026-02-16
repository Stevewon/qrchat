import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/friend_request.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';

/// 친구 요청 화면 (카카오톡 스타일 - 실시간 업데이트)
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    _loadCurrentUser();
  }

  /// 프로필 사진 가져오기
  Future<String?> _getProfilePhoto(String userId) async {
    try {
      final user = await _friendService.getFriendById(userId);
      return user?.profilePhoto;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
      });
      
      if (kDebugMode) {
        debugPrint('📱 친구 요청 화면 로드: ${user.nickname} (${user.id})');
      }
    }
  }

  /// 친구 요청 수락
  Future<void> _acceptRequest(FriendRequest request) async {
    try {
      if (kDebugMode) {
        debugPrint('✅ 친구 요청 수락 시작: ${request.fromUserNickname}');
      }
      
      await _friendService.acceptFriendRequest(request.id);
      
      // 친구 추가 성공 시 즉시 목록 제거 (스낵바 제거)
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 수락 실패: $e');
      }
      
      if (mounted) {
        _showSnackBar('친구 요청 수락에 실패했습니다');
      }
    }
  }

  /// 친구 요청 거절
  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 거절 시작: ${request.fromUserNickname}');
      }
      
      await _friendService.rejectFriendRequest(request.id);
      
      // 친구 요청 거절 시 즉시 목록에서 제거 (스낵바 제거)
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 친구 요청 거절 실패: $e');
      }
      
      if (mounted) {
        _showSnackBar('친구 요청 거절에 실패했습니다');
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.grey[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 요청'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<FriendRequest>>(
              stream: _friendService.getFriendRequestsStream(_currentUserId!),
              builder: (context, snapshot) {
                // 로딩 중
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 에러 발생
                if (snapshot.hasError) {
                  if (kDebugMode) {
                    debugPrint('❌ 친구 요청 스트림 에러: ${snapshot.error}');
                  }
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '친구 요청을 불러올 수 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // 재시도
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data ?? [];

                // 요청이 없음
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '받은 친구 요청이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 친구 요청 목록 표시
                if (kDebugMode) {
                  debugPrint('📨 친구 요청 ${requests.length}건 표시');
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                );
              },
            ),
        ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 프로필 사진
            FutureBuilder<String?>(
              future: _getProfilePhoto(request.fromUserId),
              builder: (context, snapshot) {
                return CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: snapshot.hasData && 
                                 snapshot.data != null && 
                                 snapshot.data!.isNotEmpty
                      ? NetworkImage(snapshot.data!)
                      : null,
                  child: snapshot.hasData && 
                         snapshot.data != null && 
                         snapshot.data!.isNotEmpty
                      ? null
                      : const Icon(Icons.person, size: 28, color: Colors.blue),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromUserNickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(request.createdAt, locale: 'ko'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // 수락/거절 버튼
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('수락'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _rejectRequest(request),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('거절'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
