import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 이용약관 화면
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          '이용약관',
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
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QRChat 이용약관',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '서비스 이용 전 반드시 확인해주세요',
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

              // 제1조 목적
              _buildArticle(
                number: '제1조',
                title: '목적',
                content: '본 약관은 QR 기반 비회원 메신저 서비스 큐알쳇(QRChat)(이하 "서비스")의 이용과 관련하여 서비스 제공자와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
              ),

              const SizedBox(height: 20),

              // 제2조 서비스의 성격
              _buildArticle(
                number: '제2조',
                title: '서비스의 성격',
                content: '',
                bulletPoints: [
                  '본 서비스는 회원가입 절차 없이 이용 가능한 비식별 메신저입니다.',
                  '서비스는 이용자의 개인정보를 수집하거나 서버에 저장하지 않습니다.',
                  '모든 데이터(닉네임, 채팅내용, 파일 등)는 이용자의 단말기 내부에만 저장됩니다.',
                  '서비스 제공자는 이용자의 대화내용, 통화내용, 파일 및 접속기록을 확인하거나 보관할 수 없습니다.',
                ],
              ),

              const SizedBox(height: 20),

              // 제3조 이용자의 책임
              _buildArticle(
                number: '제3조',
                title: '이용자의 책임',
                content: '',
                bulletPoints: [
                  '이용자는 자신의 단말기 분실, 삭제, 초기화로 인한 데이터 손실에 대해 스스로 책임을 집니다.',
                  '서비스는 계정 복구 기능을 제공하지 않습니다.',
                  'QR 주소 공유로 인해 발생하는 문제는 이용자의 관리 책임에 속합니다.',
                  '불법 촬영물, 범죄모의, 협박, 사기 등 법률 위반 행위에 서비스를 이용해서는 안 됩니다.',
                ],
              ),

              const SizedBox(height: 20),

              // 제4조 서비스 제공자의 책임 제한
              _buildArticle(
                number: '제4조',
                title: '서비스 제공자의 책임 제한',
                content: '',
                bulletPoints: [
                  '서비스 제공자는 이용자 데이터를 보관하지 않으므로 데이터 복구 의무가 없습니다.',
                  '이용자의 단말기 해킹, 악성코드, OS 취약점으로 인한 피해에 대해 책임지지 않습니다.',
                  '네트워크 환경, 통신사, 기기 상태에 따른 통화 품질 문제는 서비스 책임이 아닙니다.',
                  '이용자 간 분쟁에 서비스 제공자는 개입하지 않습니다.',
                ],
              ),

              const SizedBox(height: 20),

              // 제5조 서비스 중단
              _buildArticle(
                number: '제5조',
                title: '서비스 중단',
                content: '다음 경우 서비스 제공자는 사전 통지 없이 기능 제공을 중단할 수 있습니다.',
                bulletPoints: [
                  'OS 정책 변경',
                  '보안 취약점 발생',
                  '법적 요구',
                  '기술적 유지보수',
                ],
              ),

              const SizedBox(height: 20),

              // 제6조 금지행위
              _buildArticle(
                number: '제6조',
                title: '금지행위',
                content: '다음 행위를 금지합니다.',
                bulletPoints: [
                  '타인의 사칭',
                  '불법정보 유통',
                  '해킹/역공학 시도',
                  '서비스 구조 악용',
                  '자동화 공격 및 트래픽 유발 행위',
                ],
              ),

              const SizedBox(height: 20),

              // 제7조 약관 변경
              _buildArticle(
                number: '제7조',
                title: '약관 변경',
                content: '법령 또는 서비스 구조 변경 시 약관은 업데이트될 수 있으며 앱 내 공지로 효력이 발생합니다.',
              ),

              const SizedBox(height: 20),

              // 제8조 준거법
              _buildArticle(
                number: '제8조',
                title: '준거법',
                content: '본 약관은 대한민국 법령에 따릅니다.',
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
                        '서비스를 이용함으로써 본 약관에 동의한 것으로 간주됩니다.',
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
            ...bulletPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
