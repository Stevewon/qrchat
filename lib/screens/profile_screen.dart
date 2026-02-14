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
import '../services/qkey_service.dart';
import '../models/securet_user.dart';
import '../models/qkey_transaction.dart';
import 'login_screen.dart';
import 'my_qr_code_screen.dart';
import 'admin_qkey_screen.dart';
import 'sticker_pack_management_screen.dart';
import 'qkey_history_screen.dart';

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
  int _qkeyBalance = 0; // QKEY 잔액

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
    _loadQKeyBalance();
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
  
  /// QKEY 잔액 로드
  Future<void> _loadQKeyBalance() async {
    if (_currentUser == null) {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) return;
      _currentUser = user;
    }
    
    final balance = await QKeyService.getUserBalance(_currentUser!.id);
    if (mounted) {
      setState(() {
        _qkeyBalance = balance;
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

  /// QKEY 출금 신청 다이얼로그
  void _showWithdrawDialog() {
    if (_qkeyBalance < QKeyService.withdrawMinAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최소 출금 가능 금액은 ${QKeyService.withdrawMinAmount} QKEY입니다.\n'
            '(현재 잔액: $_qkeyBalance QKEY)'
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final walletController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet, color: Color(0xFF1976D2)),
            SizedBox(width: 8),
            Text('QKEY 출금 신청'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 잔액
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '현재 잔액',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    Text(
                      '$_qkeyBalance QKEY',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 출금 금액
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '출금 금액 (QKEY)',
                  hintText: '${QKeyService.withdrawUnit}의 배수로 입력',
                  border: const OutlineInputBorder(),
                  suffixText: 'QKEY',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 지갑 주소
              TextField(
                controller: walletController,
                decoration: const InputDecoration(
                  labelText: '지갑 주소',
                  hintText: '암호화폐 지갑 주소를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 12),
              
              // 안내 사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '출금 안내',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 최소 출금: ${QKeyService.withdrawMinAmount} QKEY\n'
                      '• 출금 단위: ${QKeyService.withdrawUnit} QKEY\n'
                      '• 관리자 승인 후 처리됩니다\n'
                      '• 지갑 주소를 정확히 입력해주세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountText = amountController.text.trim();
              final walletAddress = walletController.text.trim();
              
              if (amountText.isEmpty || walletAddress.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 항목을 입력해주세요')),
                );
                return;
              }
              
              final amount = int.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 금액을 입력해주세요')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // 로딩 표시
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final result = await QKeyService.requestWithdraw(
                userId: _currentUser!.id,
                amount: amount,
                walletAddress: walletAddress,
              );
              
              if (mounted) {
                Navigator.pop(context); // 로딩 닫기
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
                
                if (result['success']) {
                  _loadQKeyBalance(); // 잔액 새로고침
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
            ),
            child: const Text('출금 신청'),
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

  /// 설정 바텀시트 표시
  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              
              // 타이틀
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // 메뉴 리스트
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 8),
                    
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
                          : 'Version $_appVersion',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        // About 상세 페이지로 이동 (추후 구현)
                      },
                    ),
                    
                    const Divider(height: 1, indent: 56),
                    
                    // 🎨 스티커팩 관리 (ListTile 형태로 추가)
                    ListTile(
                      leading: const Icon(Icons.collections, color: Colors.purple),
                      title: const Text('스티커팩 관리', style: TextStyle(fontSize: 16)),
                      subtitle: const Text(
                        '스티커 추가, 삭제 및 팩 관리',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context); // 바텀시트 닫기
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StickerPackManagementScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 8, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 16),
                    
                    // 관리자 QKEY 관리 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 바텀시트 닫기
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminQKeyScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.monetization_on),
                        label: const Text('QKEY 출금 관리'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 스티커팩 관리 버튼 (관리자용)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 바텀시트 닫기
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StickerPackManagementScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.collections),
                        label: const Text('스티커팩 관리'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 바텀시트 닫기
                          _logout();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('로그아웃'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 회원탈퇴 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 바텀시트 닫기
                          _showDeleteAccountDialog();
                        },
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // My QR Code 아이콘
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: Colors.black87),
            tooltip: 'My QR Code',
            onPressed: () {
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
          // 우측 상단 톱니바퀴 (설정) 아이콘
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              _showSettingsBottomSheet();
            },
          ),
        ],
      ),
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
              const SizedBox(height: 16),
              
              // Securet 연동 배지 (카드 스타일)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.security, size: 24, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Securet 보안 연동 중',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.verified_user, size: 20, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // QKEY 포인트 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, size: 24, color: Colors.white),
                          const SizedBox(width: 12),
                          const Text(
                            'QKEY 포인트',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_qkeyBalance',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'QKEY',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 정보 텍스트
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '채팅 5분마다 2 QKEY 적립',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 버튼들
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QKeyHistoryScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text(
                                '거래 내역',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFFB300),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showWithdrawDialog,
                              icon: const Icon(Icons.account_balance_wallet, size: 18),
                              label: const Text(
                                '출금 신청',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFFB300),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1),
              
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
