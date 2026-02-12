import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/securet_user.dart';
import '../services/securet_auth_service.dart';
import '../services/firebase_friend_service.dart';

class QRScannerScreen extends StatefulWidget {
  final VoidCallback? onFriendAdded;
  
  const QRScannerScreen({super.key, this.onFriendAdded});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final FirebaseFriendService _friendService = FirebaseFriendService();
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  SecuretUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await SecuretAuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 QR 스캔'),
        centerTitle: true,
      ),
      body: _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera Scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (!_isProcessing) {
              _handleQRCodeDetected(capture);
            }
          },
        ),
        
        // Overlay with scanning frame
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Scanning frame
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 40),
              
              // Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text(
                      '친구의 QR 코드를 스캔하세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'QR 코드를 프레임 안에 위치시키면\n자동으로 스캔됩니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Loading overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _handleQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _currentUser == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final barcode = barcodes.first;
      final qrData = barcode.rawValue;

      if (qrData == null || qrData.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Validate Securet QR URL
      if (!SecuretAuthService.isValidSecuretUrl(qrData)) {
        if (mounted) {
          _showErrorDialog('유효하지 않은 QR 코드', 'Securet QR 코드가 아닙니다.');
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Parse QR URL to get user info
      final scannedUser = SecuretUser.fromQRUrl(qrData, '', '');
      if (scannedUser == null) {
        if (mounted) {
          _showErrorDialog('QR 코드 오류', 'QR 코드를 읽을 수 없습니다.');
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (kDebugMode) {
        debugPrint('\n🔍 ========== QR 스캔 정보 ==========');
        debugPrint('QR URL: $qrData');
        debugPrint('추출된 Securet 닉네임 (참고용): ${scannedUser.nickname}');
        debugPrint('========== QR 스캔 정보 ==========\n');
      }

      // Check if scanning own QR code (QR URL로 비교)
      if (qrData == _currentUser!.qrUrl) {
        if (mounted) {
          _showErrorDialog('본인 QR 코드', '자신의 QR 코드는 스캔할 수 없습니다.');
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Check if user exists in system (QR 채팅 앱에 등록된 사용자 필수)
      final allUsers = await _friendService.getAllUsers();
      
      // ⭐ 중요: QR URL로 사용자 검색 (Securet 닉네임 무시!)
      SecuretUser? foundUser;
      try {
        foundUser = allUsers.firstWhere(
          (u) => u.qrUrl == qrData,  // QR URL로 검색
        );
      } catch (e) {
        // 사용자를 찾지 못한 경우
        if (mounted) {
          _showErrorDialog(
            '사용자 없음',
            '이 QR 코드는 QR채팅에 등록되지 않은 사용자입니다.\n\n먼저 QR채팅 앱에 가입하고 이 QR 코드로 로그인해야 합니다.',
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // foundUser를 non-nullable로 변환
      final targetUser = foundUser;

      if (kDebugMode) {
        debugPrint('\n👤 ========== 사용자 검색 결과 ==========');
        debugPrint('스캔한 QR URL: $qrData');
        debugPrint('QR에서 추출한 Securet 닉네임 (무시됨): ${scannedUser.nickname}');
        debugPrint('Firestore에서 찾은 사용자 ID: ${targetUser.id}');
        debugPrint('Firestore에서 찾은 QR채팅 닉네임: ${targetUser.nickname}');
        debugPrint('Firestore QR URL: ${targetUser.qrUrl}');
        debugPrint('========== 사용자 검색 결과 ==========\n');
      }

      // Check if already friends
      final friends = await _friendService.getFriends(_currentUser!.id);
      final isAlreadyFriend = friends.any((f) => f.nickname == targetUser.nickname);

      if (isAlreadyFriend) {
        if (kDebugMode) {
          print('ℹ️ 이미 친구입니다: ${targetUser.nickname}');
        }
        
        if (mounted) {
          // 처리 상태 해제
          setState(() {
            _isProcessing = false;
          });
          
          // "이미 친구" 정보 다이얼로그 표시
          _showInfoDialog('이미 친구입니다', '${targetUser.nickname}님은 이미 친구 목록에 있습니다.');
        }
        return;
      }

      // Auto-accept: Add friend immediately without confirmation
      if (mounted) {
        await _addFriendAutomatically(targetUser);
      }

    } catch (e) {
      if (mounted) {
        _showErrorDialog('오류 발생', 'QR 코드 처리 중 오류가 발생했습니다.');
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 자동으로 친구 추가 (QR 스캔 = 자동 수락)
  /// 자동으로 친구 추가 (QR 스캔 = 자동 수락)
  /// 친구 자동 추가 - 확인 다이얼로그 버전
  Future<void> _addFriendAutomatically(SecuretUser targetUser) async {
    try {
      if (kDebugMode) {
        print('🔄 친구 추가 시작: ${targetUser.nickname}');
      }

      // 양방향 친구 관계 추가
      await _friendService.addFriend(
        _currentUser!.id,
        _currentUser!.nickname,
        targetUser.id,
        targetUser.nickname,
      );

      if (kDebugMode) {
        print('✅ 친구 추가 성공: ${targetUser.nickname}');
      }

      if (!mounted) return;

      // 처리 상태 해제 (다이얼로그 표시를 위해)
      setState(() {
        _isProcessing = false;
      });

      // 성공 다이얼로그 표시 (사용자가 확인 버튼을 누를 때까지 대기)
      if (mounted) {
        _showSuccessDialog(targetUser.nickname);
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ 친구 추가 오류: $e');
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        _showErrorDialog('오류 발생', '친구 추가 중 오류가 발생했습니다.');
      }
    }
  }

  void _showSuccessDialog(String nickname) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('친구 추가 완료'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                '$nickname님이\n친구 목록에 추가되었습니다!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '친구 목록으로 이동합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  if (kDebugMode) print('✅ 확인 버튼 클릭');

                  // 1단계: 카메라 완전히 중지
                  await _scannerController?.stop();
                  if (kDebugMode) print('✅ 카메라 중지 완료');

                  // 2단계: 다이얼로그 닫기
                  if (mounted) {
                    Navigator.of(context).pop();
                    if (kDebugMode) print('✅ 다이얼로그 닫기 완료');
                  }

                  // 3단계: 친구 추가 완료 콜백 호출 (친구 탭으로 전환)
                  if (widget.onFriendAdded != null) {
                    widget.onFriendAdded!();
                    if (kDebugMode) print('✅ 친구 탭으로 자동 전환 완료');
                  }

                } catch (e) {
                  if (kDebugMode) print('❌ 화면 전환 오류: $e');
                  
                  // 에러 시에도 다이얼로그 닫고 친구 탭으로 전환
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  if (widget.onFriendAdded != null) {
                    widget.onFriendAdded!();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  if (kDebugMode) print('✅ 정보 다이얼로그 확인 버튼 클릭');

                  // 카메라 중지
                  await _scannerController?.stop();
                  if (kDebugMode) print('✅ 카메라 중지 완료');

                  // 다이얼로그 닫기
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  // 친구 추가 완료 콜백 호출 (친구 탭으로 전환)
                  if (widget.onFriendAdded != null) {
                    widget.onFriendAdded!();
                    if (kDebugMode) print('✅ 친구 탭으로 자동 전환 완료');
                  }

                } catch (e) {
                  if (kDebugMode) print('❌ 정보 다이얼로그 닫기 오류: $e');
                  
                  // 에러 시에도 친구 탭으로 전환
                  if (widget.onFriendAdded != null) {
                    widget.onFriendAdded!();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('확인', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = false;
                });
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
