import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 개인정보 처리지침 화면 (무수집형)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '개인정보 처리지침',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '개인정보 처리지침',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '무수집형 서비스',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 강조 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.success,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QRChat은 개인정보를 수집하지 않는\n무수집형 서비스입니다',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 제1조 기본 원칙
              _buildArticle(
                number: '제1조',
                title: '기본 원칙',
                content: '큐알쳇은 이용자의 개인정보를 수집하지 않는 것을 기본 원칙으로 설계된 서비스입니다.',
                icon: Icons.rule,
              ),

              const SizedBox(height: 20),

              // 제2조 수집하는 개인정보
              _buildArticle(
                number: '제2조',
                title: '수집하는 개인정보',
                content: '서비스는 아래 정보를 포함하여 어떠한 개인정보도 수집하지 않습니다.',
                bulletPoints: [
                  '이름',
                  '전화번호',
                  '이메일',
                  '생년월일',
                  '위치정보',
                  '기기식별자',
                  '광고식별자',
                  'IP주소',
                  '채팅내용',
                  '통화내용',
                  '접속기록',
                ],
                icon: Icons.block,
              ),

              const SizedBox(height: 20),

              // 제3조 저장 위치
              _buildArticle(
                number: '제3조',
                title: '저장 위치',
                content: '모든 데이터는 이용자의 기기 내부 저장소에만 저장되며 서비스 서버에는 저장되지 않습니다.',
                icon: Icons.phone_android,
              ),

              const SizedBox(height: 20),

              // 제4조 제3자 제공
              _buildArticle(
                number: '제4조',
                title: '제3자 제공',
                content: '서비스는 서버에 데이터를 보관하지 않으므로 제3자에게 제공하거나 위탁하는 행위가 구조적으로 불가능합니다.',
                icon: Icons.share_outlined,
              ),

              const SizedBox(height: 20),

              // 제5조 로그 및 추적
              _buildArticle(
                number: '제5조',
                title: '로그 및 추적',
                content: '서비스는 아래를 수행하지 않습니다.',
                bulletPoints: [
                  '사용자 추적',
                  '행동 분석',
                  '광고 식별',
                  '통계 수집',
                ],
                icon: Icons.search_off,
              ),

              const SizedBox(height: 20),

              // 제6조 권리 및 행사
              _buildArticle(
                number: '제6조',
                title: '권리 및 행사',
                content: '서비스 제공자는 개인정보를 보유하지 않으므로 열람·정정·삭제 요청의 대상 정보가 존재하지 않습니다.',
                icon: Icons.gavel,
              ),

              const SizedBox(height: 20),

              // 제7조 아동의 개인정보
              _buildArticle(
                number: '제7조',
                title: '아동의 개인정보',
                content: '서비스는 개인정보를 처리하지 않으므로 연령 확인 절차를 요구하지 않습니다.',
                icon: Icons.child_care,
              ),

              const SizedBox(height: 20),

              // 제8조 문의
              _buildArticle(
                number: '제8조',
                title: '문의',
                content: '본 서비스는 개인정보를 보관하지 않으므로 데이터 복구 및 조회 요청은 처리할 수 없습니다.',
                icon: Icons.help_outline,
              ),

              const SizedBox(height: 24),

              // 하단 안내
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '본 서비스는 이용자의 개인정보를 서버에 저장하지 않습니다. 모든 데이터는 단말기에만 보관됩니다.',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 조항 빌더
  Widget _buildArticle({
    required String number,
    required String title,
    String? content,
    List<String>? bulletPoints,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조항 번호 및 제목
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 (선택적)
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              
              // 조항 번호 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          // 본문 내용
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],

          // 항목 리스트
          if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bulletPoints.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
