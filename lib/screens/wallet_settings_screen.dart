import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/securet_auth_service.dart';
import '../models/securet_user.dart';
import '../constants/app_colors.dart';

/// 지갑 설정 화면
/// - 1회 입력 후 변경 불가
/// - 복사 기능 제공
class WalletSettingsScreen extends StatefulWidget {
  const WalletSettingsScreen({super.key});

  @override
  State<WalletSettingsScreen> createState() => _WalletSettingsScreenState();
}

class _WalletSettingsScreenState extends State<WalletSettingsScreen> {
  SecuretUser? _currentUser;
  String? _walletAddress;
  bool _isLoading = true;
  bool _hasWallet = false;
  
  final TextEditingController _walletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  /// 지갑 정보 로드
  Future<void> _loadWalletInfo() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final walletAddress = data?['walletAddress'] as String?;

        if (mounted) {
          // 지갑 주소가 있고, 공백이 아니며, 이더리움 형식인지 확인
          final ethereumRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
          final hasValidWallet = walletAddress != null && 
                       walletAddress.trim().isNotEmpty && 
                       ethereumRegex.hasMatch(walletAddress.trim());
          
          setState(() {
            _currentUser = user;
            _walletAddress = hasValidWallet ? walletAddress : null;
            _hasWallet = hasValidWallet;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _currentUser = user;
          _walletAddress = null;
          _hasWallet = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지갑 정보 로드 실패: $e')),
        );
      }
    }
  }

  /// 지갑 주소 저장
  Future<void> _saveWalletAddress() async {
    final address = _walletController.text.trim();
    
    // 1. 빈 값 체크
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 지갑 주소를 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. 이더리움 주소 형식 검증 (0x로 시작하고 42자)
    final ethereumAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    if (!ethereumAddressRegex.hasMatch(address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '❌ 올바른 이더리움 주소 형식이 아닙니다\n\n'
            '✅ 올바른 형식:\n'
            '• 0x로 시작해야 합니다\n'
            '• 총 42자리여야 합니다\n'
            '• 0-9, a-f, A-F만 포함해야 합니다\n\n'
            '예: 0xE0c166B147a742E4FbCf5e5BCf73aCA631f14f0e',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // 3. 경고 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('지갑 주소 등록'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ 중요 안내',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
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
                    Text(
                      '• 지갑 주소는 1회만 입력 가능합니다\n'
                      '• 입력 후에는 절대 변경할 수 없습니다\n'
                      '• 잘못된 주소 입력 시 출금이 불가능합니다\n'
                      '• 신중하게 확인 후 등록해주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade900,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 입력한 주소 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '입력한 주소:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '위 주소가 정확한지 다시 한 번 확인해주세요.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('확인 및 등록'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 저장 처리
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .update({
        'walletAddress': address,
        'walletRegisteredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _walletAddress = address;
          _hasWallet = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 지갑 주소가 등록되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 지갑 주소 복사
  void _copyWalletAddress() {
    if (_walletAddress != null && _walletAddress!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 지갑 주소가 복사되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 텔레그램 지갑 생성 페이지 열기
  Future<void> _openTelegramWallet() async {
    const url = 'https://t.me/quantarium_bot';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 링크를 열 수 없습니다'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.error,
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
        title: const Text(
          '지갑 설정',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 안내 카드
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        '암호화폐 지갑',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'QKEY 출금을 위해 암호화폐 지갑 주소를 등록해주세요.\n'
                    '지갑 주소는 한 번만 등록 가능하며, 변경할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 지갑 주소가 등록된 경우
            if (_hasWallet) ...[
              const Text(
                '등록된 지갑 주소',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '등록 완료',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    SelectableText(
                      _walletAddress!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 복사 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyWalletAddress,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('주소 복사'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 경고 안내
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '변경 불가',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '등록된 지갑 주소는 보안상의 이유로 변경할 수 없습니다.\n'
                      '출금 시 등록된 주소로만 전송됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ✅ 텔레그램 지갑 생성 안내 (등록 후에도 표시)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088CC), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088CC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.telegram, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '새 지갑이 필요하신가요?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '텔레그램 봇을 통해 무료로 암호화폐 지갑을 생성할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openTelegramWallet,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('텔레그램 지갑 생성하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0088CC),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // 지갑 주소가 등록되지 않은 경우
            else ...[
              const Text(
                '지갑 주소 입력',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // 형식 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이더리움 주소 형식: 0x로 시작하는 42자리',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // ✅ 텔레그램 지갑 생성 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088CC), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088CC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.telegram, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '지갑이 없으신가요?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '텔레그램 봇을 통해 무료로 암호화폐 지갑을 생성할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openTelegramWallet,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('텔레그램 지갑 생성하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0088CC),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: _walletController,
                maxLines: 3,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: '0xE0c166B147a742E4FbCf5e5BCf73aCA631f14f0e',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                  helperText: '예시: 0x로 시작하는 40자리 영문+숫자',
                  helperStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveWalletAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '지갑 주소 등록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 주의사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '주의사항',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 지갑 주소는 1회만 등록 가능합니다\n'
                      '• 등록 후에는 절대 변경할 수 없습니다\n'
                      '• 이더리움 주소 형식만 지원합니다 (0x + 40자리)\n'
                      '• 잘못된 주소 입력 시 출금이 불가능합니다\n'
                      '• 반드시 정확한 주소인지 확인 후 등록하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 하단 여백 추가
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
