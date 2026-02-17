import 'package:flutter/material.dart';
import '../models/securet_user.dart';
import 'qr_scanner_screen.dart';
import 'add_friend_by_qr_address_screen.dart';
import 'my_qr_code_screen.dart';

/// 친구 추가 메인 화면
/// 
/// QR 코드, 연락처, 카카오톡 ID, 추천친구 탭으로 구성
/// - QR 코드: QR 스캐너 실행
/// - QR 주소: QR 주소로 친구 추가
/// - 카카오톡 ID: 카카오톡 ID로 친구 추가 (추후 구현)
/// - 추천친구: 추천 친구 목록 (추후 구현)
class AddFriendScreen extends StatelessWidget {
  final SecuretUser currentUser;

  const AddFriendScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '친구 추가',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 내 QR 코드 카드
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 QR 코드',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentUser.nickname} / ${_extractQRAddress(currentUser.qrUrl)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyQRCodeScreen(user: currentUser),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // 친구 추가 메뉴
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // QR 코드 스캔
                  _buildMenuCard(
                    context: context,
                    icon: Icons.qr_code_scanner,
                    label: 'QR 코드',
                    description: 'QR 스캔',
                    color: const Color(0xFF667eea),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                  ),

                  // QR 주소로 추가
                  _buildMenuCard(
                    context: context,
                    icon: Icons.link,
                    label: 'QR 주소',
                    description: '주소로 추가',
                    color: const Color(0xFF764ba2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddFriendByQRAddressScreen(),
                        ),
                      );
                    },
                  ),

                  // 카카오톡 ID (추후 구현)
                  _buildMenuCard(
                    context: context,
                    icon: Icons.chat_bubble,
                    label: '카카오톡 ID',
                    description: '준비 중',
                    color: const Color(0xFFFFB300),
                    onTap: () {
                      _showComingSoonDialog(context, '카카오톡 ID로 친구 추가');
                    },
                  ),

                  // 추천친구 (추후 구현)
                  _buildMenuCard(
                    context: context,
                    icon: Icons.people_outline,
                    label: '추천친구',
                    description: '준비 중',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      _showComingSoonDialog(context, '추천친구 기능');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 메뉴 카드 빌더
  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// QR 주소 추출 (qrUrl에서 ID 부분만 추출)
  String _extractQRAddress(String qrUrl) {
    // qrUrl 예시: "securet://qrchat?uid=abc123"
    try {
      final uri = Uri.parse(qrUrl);
      return uri.queryParameters['uid'] ?? qrUrl;
    } catch (e) {
      return qrUrl;
    }
  }

  /// 준비 중 다이얼로그
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 12),
            Text('준비 중'),
          ],
        ),
        content: Text('$feature 기능은 곧 출시될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
