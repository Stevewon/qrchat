import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_friend_service.dart';
import '../services/securet_auth_service.dart';
import '../constants/app_colors.dart';

/// QR 주소로 친구 추가 화면
/// 
/// 사용자가 친구의 닉네임과 QR 주소를 직접 입력하여 친구를 추가할 수 있습니다.
class AddFriendByQRAddressScreen extends StatefulWidget {
  const AddFriendByQRAddressScreen({super.key});

  @override
  State<AddFriendByQRAddressScreen> createState() => _AddFriendByQRAddressScreenState();
}

class _AddFriendByQRAddressScreenState extends State<AddFriendByQRAddressScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _qrAddressController = TextEditingController();
  
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserNickname;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _qrAddressController.dispose();
    super.dispose();
  }

  /// 현재 사용자 정보 로드
  Future<void> _loadCurrentUser() async {
    final user = await SecuretAuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
        _currentUserNickname = user.nickname;
      });
    }
  }

  /// QR 주소로 친구 추가
  Future<void> _addFriendByQRAddress() async {
    final nickname = _nicknameController.text.trim();
    final qrAddress = _qrAddressController.text.trim();

    // 1. 입력 값 검증
    if (nickname.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요', isError: true);
      return;
    }

    if (qrAddress.isEmpty) {
      _showSnackBar('QR 주소를 입력해주세요', isError: true);
      return;
    }

    if (_currentUserId == null || _currentUserNickname == null) {
      _showSnackBar('로그인이 필요합니다', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Firestore에서 QR 주소로 사용자 검색
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('qrUrl', isEqualTo: qrAddress)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('해당 QR 주소를 가진 사용자를 찾을 수 없습니다', isError: true);
        }
        return;
      }

      final targetUserDoc = usersSnapshot.docs.first;
      final targetUserId = targetUserDoc.id;
      final targetUserNickname = targetUserDoc.data()['nickname'] as String?;

      // 3. 본인 체크
      if (targetUserId == _currentUserId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('자신을 친구로 추가할 수 없습니다', isError: true);
        }
        return;
      }

      // 4. 닉네임 일치 확인 (선택사항: 보안 강화)
      if (targetUserNickname != null && targetUserNickname != nickname) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showConfirmDialog(
            '닉네임 불일치',
            '입력한 닉네임($nickname)과 QR 주소의 실제 닉네임($targetUserNickname)이 다릅니다.\n\n계속하시겠습니까?',
            () => _sendFriendRequest(targetUserId, targetUserNickname),
          );
        }
        return;
      }

      // 5. 이미 친구인지 확인
      final friends = await _friendService.getFriends(_currentUserId!);
      final isAlreadyFriend = friends.any((friend) => friend.friendId == targetUserId);

      if (isAlreadyFriend) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('이미 친구입니다', isError: false);
        }
        return;
      }

      // 6. 친구 요청 전송
      await _sendFriendRequest(targetUserId, targetUserNickname ?? nickname);
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('친구 추가 실패: $e', isError: true);
      }
    }
  }

  /// 친구 요청 전송
  Future<void> _sendFriendRequest(String targetUserId, String targetNickname) async {
    try {
      await _friendService.sendFriendRequest(
        _currentUserId!,
        _currentUserNickname!,
        targetUserId,
        targetNickname,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('친구 요청을 보냈습니다', isError: false);
        
        // 입력 필드 초기화
        _nicknameController.clear();
        _qrAddressController.clear();
        
        // 화면 닫기 (선택사항)
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('친구 요청 실패: $e', isError: true);
      }
    }
  }

  /// 확인 다이얼로그 표시
  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시
  void _showSnackBar(String message, {required bool isError}) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR 주소로 친구 추가',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '친구의 닉네임과 QR 주소를 입력하여\n친구를 추가할 수 있습니다',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 닉네임 입력
              const Text(
                '친구 닉네임',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: '친구의 닉네임을 입력하세요',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF667eea)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 24),

              // QR 주소 입력
              const Text(
                'QR 주소',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qrAddressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'QR 주소를 입력하세요 (예: hbcu009)',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.qr_code, color: Color(0xFF667eea)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),

              const SizedBox(height: 12),

              // 도움말
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QR 주소는 친구의 QR 코드 하단에 표시됩니다\n(예: steve kwon / hbcu009)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addFriendByQRAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '친구 추가',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
