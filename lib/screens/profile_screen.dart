import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../services/securet_auth_service.dart';
// import '../screens/invite_friends_screen.dart'; // 파일 없음 - 임시 비활성화
import '../services/notification_service.dart';
import '../models/securet_user.dart';
import 'login_screen.dart';
import 'my_qr_code_screen.dart';
import 'admin_sticker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SecuretUser? _currentUser;
  bool _isLoading = true;
  bool _notificationSoundEnabled = true;
  final NotificationService _notificationService = NotificationService();
  String _statusMessage = ''; // 상태 메시지
  String _appVersion = ''; // 앱 버전

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    _loadUserProfile();
    _loadNotificationSettings();
    _loadAppVersion();
  }
  
  /// 앱 버전 로드
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }
  
  /// 알림음 설정 로드
  Future<void> _loadNotificationSettings() async {
    await _notificationService.initialize();
    if (mounted) {
      setState(() {
        _notificationSoundEnabled = _notificationService.isSoundEnabled;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .get();
          
          if (userDoc.exists) {
            final data = userDoc.data();
            final profilePhoto = data?['profilePhoto'] as String?;
            final statusMessage = data?['statusMessage'] as String? ?? '';
            
            if (mounted) {
              setState(() {
                _currentUser = user.copyWith(profilePhoto: profilePhoto);
                _statusMessage = statusMessage;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _currentUser = user;
                _isLoading = false;
              });
            }
          }
        } catch (firestoreError) {
          if (kDebugMode) {
            debugPrint('⚠️ Firestore 조회 실패: $firestoreError');
          }
          if (mounted) {
            setState(() {
              _currentUser = user;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 프로필 로드 실패: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && _currentUser != null) {
        setState(() => _isLoading = true);

        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(image.path));
        }

        final photoUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.id)
            .update({'profilePhoto': photoUrl});

        if (mounted) {
          setState(() {
            _currentUser = _currentUser!.copyWith(profilePhoto: photoUrl);
            _isLoading = false;
          });
          // 프로필 사진 업데이트 성공 (스낵바 제거)
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패: $e')),
        );
      }
    }
  }

  /// 상태 메시지 편집 다이얼로그
  void _showEditStatusMessageDialog() {
    final controller = TextEditingController(text: _statusMessage);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상태 메시지'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          decoration: const InputDecoration(
            hintText: '상태 메시지를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newMessage = controller.text.trim();
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.id)
                    .update({'statusMessage': newMessage});
                
                setState(() {
                  _statusMessage = newMessage;
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  // 상태 메시지 업데이트 성공 (스낵바 제거)
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('업데이트 실패: $e')),
                  );
                }
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await SecuretAuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  /// 회원탈퇴 확인 다이얼로그 (카카오톡 스타일)
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '회원탈퇴',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정말 탈퇴하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '탈퇴 시 삭제되는 정보',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 모든 채팅 내역\n'
                    '• 친구 목록\n'
                    '• 프로필 정보\n'
                    '• 저장된 설정',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '탈퇴한 계정은 복구할 수 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              '탈퇴하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteAccount();
    }
  }

  /// 회원탈퇴 실행
  Future<void> _deleteAccount() async {
    // 로딩 다이얼로그 표시
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '회원탈퇴 처리중...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final result = await SecuretAuthService.deleteAccount();
      
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      }

      if (result['success'] == true) {
        if (mounted) {
          // 로그인 화면으로 이동
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '회원탈퇴 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원탈퇴 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 카카오톡 스타일 프로필 헤더
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.only(top: 60, bottom: 24),
              child: Column(
                children: [
                  // 프로필 사진
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _currentUser?.profilePhoto != null && 
                                        _currentUser!.profilePhoto!.isNotEmpty
                            ? NetworkImage(_currentUser!.profilePhoto!)
                            : null,
                        child: _currentUser?.profilePhoto == null || 
                               _currentUser!.profilePhoto!.isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 닉네임
                  Text(
                    _currentUser?.nickname ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 상태 메시지
                  GestureDetector(
                    onTap: _showEditStatusMessageDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _statusMessage.isEmpty 
                                  ? '해보고 싶은거 다 해봐다 돼지가 인생 먼저냐?'
                                  : _statusMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: _statusMessage.isEmpty 
                                    ? Colors.grey.shade600 
                                    : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 배경 편집 버튼 (카카오톡 스타일)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 20, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                '배경 편집',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
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
          ),
          
          // 구분선
          const SliverToBoxAdapter(
            child: Divider(height: 1, thickness: 8, color: Color(0xFFF0F0F0)),
          ),
          
          // 메뉴 리스트
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              
              // Securet 연동 배지
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.security, size: 18, color: Color(0xFF1976D2)),
                    SizedBox(width: 6),
                    Text(
                      'Securet 연동',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1),
              
              // My QR Code
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: Colors.black87),
                title: const Text('My QR Code', style: TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyQRCodeScreen(user: _currentUser!),
                      ),
                    );
                  }
                },
              ),
              
              const Divider(height: 1, indent: 56),
              
              // 친구 초대 (NEW!)
              // 친구 초대 기능 - 임시 비활성화
              // ListTile(
              //   leading: const Icon(Icons.person_add, color: Colors.green),
              //   title: const Text('친구 초대', style: TextStyle(fontSize: 16)),
              //   subtitle: const Text(
              //     'QRChat을 친구들에게 소개하세요',
              //     style: TextStyle(fontSize: 13, color: Colors.grey),
              //   ),
              //   trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              //   onTap: () {
              //     // Navigator.push(
              //     //   context,
              //     //   MaterialPageRoute(
              //     //     builder: (context) => const InviteFriendsScreen(),
              //     //   ),
              //     // );
              //   },
              // ),
              
              const Divider(height: 1, indent: 56),
              
              // 알림음 설정
              ListTile(
                leading: Icon(
                  _notificationSoundEnabled 
                      ? Icons.notifications_active 
                      : Icons.notifications_off,
                  color: _notificationSoundEnabled ? Colors.teal : Colors.grey,
                ),
                title: const Text('알림음', style: TextStyle(fontSize: 16)),
                subtitle: Text(
                  _notificationSoundEnabled ? '켜짐' : '꺼짐',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                trailing: Switch(
                  value: _notificationSoundEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _notificationSoundEnabled = value;
                    });
                    await _notificationService.setSoundEnabled(value);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? '알림음이 켜졌습니다' : '알림음이 꺼졌습니다'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    if (value) {
                      await _notificationService.playNotificationSound();
                    }
                  },
                ),
              ),
              
              const Divider(height: 1, indent: 56),
              
              // About
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.black87),
                title: const Text('About', style: TextStyle(fontSize: 16)),
                subtitle: Text(
                  _appVersion.isEmpty 
                    ? 'Loading version...' 
                    : 'Version $_appVersion - 🎨 Sticker/Emoji UI improved',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 8, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 16),
              
              // 관리자 스티커 관리 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminStickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('스티커 관리자'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Logout 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 회원탈퇴 버튼 (카카오톡 스타일)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _showDeleteAccountDialog,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '회원탈퇴',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
