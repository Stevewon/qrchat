import 'package:flutter/material.dart';

class SharedPreferencesInfoDialog extends StatelessWidget {
  const SharedPreferencesInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('중요 안내'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '📱 현재 상태',
              '각 핸드폰이 독립적인 로컬 저장소를 사용합니다.\nSharedPreferences는 각 디바이스에만 저장됩니다.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '⚠️ 제한사항',
              '• 다른 핸드폰에서 가입한 사용자를 검색할 수 없습니다\n• 친구 요청이 다른 디바이스로 전달되지 않습니다\n• QR 스캔 친구 추가가 상대방에게 전달되지 않습니다',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '✅ 임시 해결책',
              '친구 검색 화면에서 "테스트 사용자 추가" 버튼을 클릭하면\n가상의 사용자 3명(steve, john, alice)이 추가됩니다.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🔥 정식 해결책',
              'Firebase Firestore를 사용하여 서버에 데이터를 저장해야 합니다.\nFirebase 설정 후 다시 빌드하면 실제 멀티 디바이스 기능이 작동합니다.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
