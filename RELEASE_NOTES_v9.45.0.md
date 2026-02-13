# QRChat v9.45.0 Release Notes

**릴리즈 날짜**: 2026-02-13 09:44 UTC  
**버전**: 9.45.0 (Build 9450)  
**플랫폼**: Android  
**빌드 도구**: Flutter 3.41.0 / Dart 3.11.0

---

## 🎉 주요 신기능: QKEY 포인트 시스템

### 💰 QKEY란?
QRChat의 자체 포인트 시스템으로, 채팅 활동을 통해 자동으로 적립되며 실제 암호화폐로 출금할 수 있습니다!

---

## ✨ 핵심 기능

### 1. 📈 자동 적립 시스템
- **적립 조건**: 로그인 후 채팅 시작
- **적립 주기**: 5분마다 자동 적립
- **적립량**: 10 QKEY / 5분
- **적립 방식**: 1:1 채팅 및 그룹 채팅 모두 동일
- **알림**: 적립 시 골드 색상의 스낵바 표시 (🎉 +10 QKEY 적립!)

### 2. 💳 QKEY 카드 (프로필 화면)
**위치**: 프로필 → Securet 배지 아래

**디자인**:
- 골드 그라데이션 카드 (Color(0xFFFFB300) → Color(0xFFFFA000))
- 그림자 효과로 프리미엄 강조
- 실시간 잔액 표시
- 하단에 "채팅 5분마다 10 QKEY 적립" 안내
- "출금 신청" 버튼 (카드 전체 클릭 가능)

**카드 구성**:
```
┌─────────────────────────────────┐
│ 💰 QKEY 포인트        1,250 QKEY │
│                                 │
│ ℹ️ 채팅 5분마다 10 QKEY 적립      │
│                    출금 신청 → │
└─────────────────────────────────┘
```

### 3. 🏦 출금 신청 기능
**최소 출금**: 1,000 QKEY  
**출금 단위**: 1,000 QKEY (1,000 / 2,000 / 3,000 ... 단위)

**출금 절차**:
1. QKEY 카드 클릭
2. 출금 금액 입력 (1,000의 배수)
3. 지갑 주소 입력 (암호화폐 지갑)
4. 출금 신청 버튼 클릭
5. 관리자 승인 대기 → 완료

**출금 다이얼로그 구성**:
- 현재 잔액 표시 (블루 박스)
- 출금 금액 입력 필드
- 지갑 주소 입력 필드 (2줄)
- 출금 안내 (주황색 박스)
  - 최소 출금: 1,000 QKEY
  - 출금 단위: 1,000 QKEY
  - 관리자 승인 후 처리
  - 지갑 주소 정확히 입력

### 4. 📊 거래 내역 관리
**Firestore 컬렉션**: `qkey_transactions`

**거래 타입**:
- `earn`: 채팅 활동 적립
- `withdraw`: 출금 신청
- `bonus`: 관리자 보너스 지급
- `penalty`: 패널티 차감

**출금 상태**:
- `pending`: 대기 중
- `approved`: 승인됨 (관리자가 승인)
- `rejected`: 거부됨 (잔액 복구)
- `completed`: 완료됨 (전송 완료)

---

## 🔧 기술 구현

### 데이터 모델

#### QKeyTransaction Model
```dart
class QKeyTransaction {
  final String id;
  final String userId;
  final QKeyTransactionType type;      // earn, withdraw, bonus, penalty
  final int amount;                     // QKEY 수량
  final int balanceAfter;               // 거래 후 잔액
  final DateTime timestamp;
  final String? description;
  
  // 출금 관련
  final WithdrawStatus? withdrawStatus; // pending, approved, rejected, completed
  final String? walletAddress;          // 지갑 주소
  final String? adminNote;              // 관리자 메모
  final String? adminId;                // 처리 관리자
  final DateTime? processedAt;          // 처리 시간
}
```

### QKeyService 주요 메서드

```dart
// 사용자 잔액 조회
static Future<int> getUserBalance(String userId);

// QKEY 적립 (5분 간격 체크)
static Future<bool> earnQKey(String userId, {String? description});

// 출금 신청
static Future<Map<String, dynamic>> requestWithdraw({
  required String userId,
  required int amount,
  required String walletAddress,
});

// 관리자: 출금 승인/거부
static Future<bool> processWithdraw({
  required String transactionId,
  required String adminId,
  required bool approve,
  String? adminNote,
});

// 사용자 거래 내역 스트림
static Stream<List<QKeyTransaction>> getUserTransactions(String userId);

// 관리자: 모든 출금 신청 조회
static Stream<List<QKeyTransaction>> getAllWithdrawals({WithdrawStatus? status});
```

### 채팅 화면 타이머 구현

```dart
// chat_screen.dart & group_chat_screen.dart
Timer? _qkeyTimer;
DateTime? _lastQKeyEarnTime;

void _startQKeyTimer() {
  _tryEarnQKey(); // 즉시 적립 시도
  
  _qkeyTimer = Timer.periodic(
    const Duration(minutes: QKeyService.earnIntervalMinutes), // 5분
    (timer) {
      _tryEarnQKey();
    },
  );
}

Future<void> _tryEarnQKey() async {
  final success = await QKeyService.earnQKey(
    widget.currentUserId,
    description: '채팅 활동',
  );
  
  if (success && mounted) {
    // 골드 스낵바 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 +10 QKEY 적립!'),
        backgroundColor: Color(0xFFFFB300),
      ),
    );
  }
}
```

---

## 📱 사용자 시나리오

### 시나리오 1: QKEY 적립
1. QRChat 로그인
2. 친구와 채팅 시작
3. **5분 후** → 자동으로 10 QKEY 적립 + 스낵바 표시
4. 계속 채팅 → **매 5분마다** 10 QKEY 적립
5. 프로필 화면에서 실시간 잔액 확인

### 시나리오 2: 출금 신청
1. 프로필 화면의 QKEY 카드 확인 (예: 2,500 QKEY)
2. 카드 클릭 → 출금 다이얼로그
3. 출금 금액 입력: **2000** (1,000 단위)
4. 지갑 주소 입력: `0x1234...abcd`
5. "출금 신청" 버튼 클릭
6. 즉시 잔액 차감 (2,500 → 500)
7. 관리자 승인 대기 (pending)
8. 관리자 승인 → 지갑으로 코인 전송
9. (거부 시 잔액 복구: 500 → 2,500)

### 시나리오 3: 관리자 처리 (향후 구현)
1. 관리자 로그인
2. 출금 신청 목록 확인
3. 사용자 정보 + 지갑 주소 검토
4. 승인 또는 거부 선택
5. 승인: 실제 암호화폐 전송 후 "completed" 처리
6. 거부: 사유 입력 후 잔액 복구

---

## 🎨 UI/UX 개선 사항

### QKEY 카드 디자인
- **색상**: 골드 그라데이션 (FFB300 → FFA000)
- **아이콘**: 💰 monetization_on
- **크기**: 프로필 하단 전체 너비
- **효과**: 그림자 (opacity 0.3, blur 8, offset (0, 4))
- **애니메이션**: 클릭 시 출금 다이얼로그 슬라이드 업

### 적립 알림
- **위치**: 화면 하단 (margin bottom: 80)
- **스타일**: floating SnackBar, 둥근 모서리
- **색상**: 골드 (0xFFFFB300)
- **지속시간**: 2초
- **내용**: "🎉 +10 QKEY 적립!"

---

## 📦 배포 파일
- **APK**: `QRChat-v9.45.0-QKEY-SYSTEM.apk` (69 MB)
- **ZIP**: `QRChat-v9.45.0-QKEY-SYSTEM.zip` (33 MB, 압축률 53%)
- **다운로드**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html

---

## 🔍 테스트 시나리오

### 1. 적립 테스트
1. QRChat 로그인 → 채팅 시작
2. **5분 대기**
3. 골드 스낵바 확인: "🎉 +10 QKEY 적립!"
4. 프로필 화면 → QKEY 카드 잔액 확인 (10 QKEY)
5. **5분 더 대기** → 다시 적립 (20 QKEY)

### 2. 출금 테스트
1. 프로필 → QKEY 카드 클릭
2. 잔액 1,000 QKEY 미만 시 → 에러 메시지
3. 1,000 QKEY 이상 시 → 출금 다이얼로그
4. 출금 금액: 1500 입력 → 에러 (1,000 단위 아님)
5. 출금 금액: 1000 입력 + 지갑 주소 입력 → 신청 완료
6. 잔액 즉시 차감 확인

### 3. Firebase 확인
1. Firestore Console 열기
2. `users/{userId}` → `qkeyBalance` 필드 확인
3. `qkey_transactions` 컬렉션 확인
   - type: earn / withdraw
   - withdrawStatus: pending
   - balanceAfter 값 확인

---

## 🏷️ Git 정보
- **Commit 1**: 21ff84f (QKEY 시스템 구현)
- **Commit 2**: 1d9e51f (구문 오류 수정)
- **Tag**: v9.45.0
- **Branch**: main

---

## 📊 버전 히스토리
| 버전 | 내용 |
|------|------|
| v9.42.0 | 그룹방 동영상 버그 수정 |
| v9.43.0 | 친구추가 스낵바 및 푸쉬알림 기능 확인 |
| v9.44.0 | 카카오톡 스타일 프로필 화면 개편 |
| **v9.45.0** | **QKEY 포인트 시스템 추가** |

---

## 🚀 향후 계획

### Phase 1 (현재 구현됨 ✅)
- ✅ QKEY 모델 및 서비스
- ✅ 자동 적립 시스템 (5분당 10 QKEY)
- ✅ 프로필 QKEY 카드
- ✅ 출금 신청 기능

### Phase 2 (다음 버전)
- [ ] 관리자 출금 승인 화면
- [ ] 거래 내역 조회 화면
- [ ] 출금 신청 내역 조회
- [ ] 실시간 환율 표시

### Phase 3 (미래)
- [ ] QKEY 마켓플레이스 (스티커 구매 등)
- [ ] 친구 간 QKEY 선물
- [ ] 보너스 이벤트 시스템
- [ ] VIP 등급 시스템

---

## ⚠️ 주의사항

1. **출금 신청 후 취소 불가**: 신청 즉시 잔액 차감
2. **지갑 주소 정확성**: 잘못된 주소 입력 시 복구 불가
3. **최소 출금량**: 1,000 QKEY 미만 출금 불가
4. **관리자 승인 필요**: 자동 전송이 아닌 수동 처리
5. **적립 간격**: 정확히 5분 간격 (중간에 앱 종료 시 타이머 리셋)

---

## 🆘 FAQ

**Q: 채팅하지 않으면 적립되나요?**  
A: 아니요. 채팅 화면에 진입해야 타이머가 시작됩니다.

**Q: 백그라운드에서도 적립되나요?**  
A: 아니요. 채팅 화면이 활성화되어 있어야 합니다.

**Q: 1:1과 그룹 적립량이 다른가요?**  
A: 아니요. 동일하게 5분당 10 QKEY입니다.

**Q: 여러 채팅방을 동시에 열면?**  
A: 현재 활성화된 채팅 화면만 적립됩니다.

**Q: 출금 거부되면 잔액은?**  
A: 자동으로 복구됩니다 (보너스 거래로 기록).

**Q: 관리자는 언제 승인하나요?**  
A: 수동 처리이므로 영업일 기준 1-3일 소요됩니다.

---

**이 버전은 QRChat에 게임 체인저급 포인트 시스템을 도입하여 사용자 참여도를 획기적으로 높이는 메이저 업데이트입니다!** 🎉
