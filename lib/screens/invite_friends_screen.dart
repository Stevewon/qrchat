import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/securet_auth_service.dart';

/// 친구 초대 화면
/// 
/// 사용자가 친구들에게 앱 다운로드 링크를 공유할 수 있습니다.
/// - SMS/문자 메시지로 초대
/// - 카카오톡/텔레그램 등으로 초대
/// - 추천인 코드 복사
class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  String _referralCode = '';
  String _appDownloadUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralInfo();
  }

  /// 추천인 정보 로드
  Future<void> _loadReferralInfo() async {
    try {
      final user = await SecuretAuthService.getCurrentUser();
      
      if (user != null && mounted) {
        setState(() {
          // 추천인 코드는 사용자 ID의 앞 8자리 사용
          _referralCode = user.id.substring(0, 8).toUpperCase();
          // TODO: 실제 앱 다운로드 URL로 변경 (Play Store/App Store)
          _appDownloadUrl = 'https://qrchat-b7a67.web.app';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('추천인 정보 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 초대 메시지 생성
  String _getInviteMessage() {
    return '''🎉 QRChat에 초대합니다!

QRChat은 Securet 기반의 안전한 메신저입니다.

✨ 주요 기능:
• 🔐 보안 채팅 & 통화
• 💬 그룹 채팅
• 🎨 스티커 & 동영상 공유
• 💰 QKEY 포인트 적립

📲 지금 다운로드:
$_appDownloadUrl

🎁 추천인 코드: $_referralCode
(가입 시 입력하면 보너스!)

함께 안전하게 대화해요! 😊''';
  }

  /// 추천인 코드 복사
  Future<void> _copyReferralCode() async {
    await Clipboard.setData(ClipboardData(text: _referralCode));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 추천인 코드가 복사되었습니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 링크 복사
  Future<void> _copyInviteLink() async {
    final link = '$_appDownloadUrl?ref=$_referralCode';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 초대 링크가 복사되었습니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 초대 메시지 공유 (SMS, 카카오톡 등)
  Future<void> _shareInvite() async {
    try {
      final message = _getInviteMessage();
      
      // share_plus를 사용하여 공유
      // 사용자가 SMS, 카카오톡, 텔레그램 등을 선택할 수 있습니다
      await Share.share(
        message,
        subject: '🎉 QRChat 초대',
      );
    } catch (e) {
      debugPrint('초대 공유 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 공유에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '친구 초대',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 일러스트 및 설명
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 아이콘
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        const Text(
                          '친구를 초대하고\nQKEY를 받으세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '💰 친구 1명당 100 QKEY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 추천인 코드 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              color: Color(0xFF667eea),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '내 추천인 코드',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF667eea), width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _referralCode,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF667eea),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              
                              IconButton(
                                onPressed: _copyReferralCode,
                                icon: const Icon(
                                  Icons.copy,
                                  color: Color(0xFF667eea),
                                ),
                                tooltip: '복사',
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          '친구가 가입할 때 이 코드를 입력하면\n서로 보너스 QKEY를 받을 수 있어요!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 초대 방법
                  const Text(
                    '초대 방법',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 링크 공유 버튼
                  _buildActionButton(
                    icon: Icons.share,
                    title: '초대 메시지 공유',
                    subtitle: 'SMS, 카카오톡, 텔레그램 등',
                    color: const Color(0xFF667eea),
                    onTap: _shareInvite,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 링크 복사 버튼
                  _buildActionButton(
                    icon: Icons.link,
                    title: '초대 링크 복사',
                    subtitle: '링크를 복사해서 직접 전송',
                    color: const Color(0xFF4CAF50),
                    onTap: _copyInviteLink,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 혜택 안내
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFF9800),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '초대 혜택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildBenefitItem('친구가 추천인 코드 입력 → 친구 50 QKEY 적립'),
                        const SizedBox(height: 8),
                        _buildBenefitItem('친구가 첫 채팅 시작 → 나에게 100 QKEY 적립'),
                        const SizedBox(height: 8),
                        _buildBenefitItem('초대 인원 제한 없음 (무제한 적립 가능)'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 주의사항
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '안내사항',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 추천인 코드는 가입 시 1회만 입력 가능합니다\n'
                          '• QKEY는 친구가 첫 채팅을 시작한 후 지급됩니다\n'
                          '• 부정한 방법으로 적립 시 계정이 제한될 수 있습니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.6,
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

  /// 액션 버튼 위젯
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
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
            
            Icon(
              Icons.chevron_right,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  /// 혜택 아이템 위젯
  Widget _buildBenefitItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFFFF9800),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE65100),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
