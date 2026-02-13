# QRChat v9.47.0 Release Notes

**Release Date**: 2026-02-13 11:38 KST  
**Build Number**: 9470  
**Code Name**: QKEY History & Transaction Management

---

## 🎉 Phase 3 완료: 사용자 거래 내역 시스템

QRChat v9.47.0에서 **QKEY 포인트 시스템 Phase 3**를 완료하여 사용자가 자신의 QKEY 거래 내역을 상세하게 조회할 수 있게 되었습니다!

---

## ✨ 주요 신규 기능

### 1️⃣ QKEY 거래 내역 화면
- **5개 탭 구성**: 전체 / 적립 / 출금 / 보너스 / 차감
- **실시간 스트림 업데이트**: Firestore Stream으로 자동 갱신
- **잔액 카드**: 현재 QKEY 잔액을 한눈에 확인
- **거래 타입별 색상 구분**:
  - 🟢 적립 (Earn): 초록색
  - 🔵 출금 (Withdraw): 파랑색
  - 🟣 보너스 (Bonus): 보라색
  - 🔴 차감 (Penalty): 빨강색

### 2️⃣ 거래 상세 보기
- **드래그 가능한 바텀시트**: 편리한 UI/UX
- **상세 정보 표시**:
  - 거래 ID (복사 가능)
  - 거래 유형
  - 거래 후 잔액
  - 거래 시간 (초 단위)
  - 설명 (있는 경우)
- **출금 거래 추가 정보**:
  - 출금 상태 (대기중/승인됨/완료/거부)
  - 지갑 주소 (복사 가능)
  - 처리 시간
  - 관리자 메모

### 3️⃣ 프로필 화면 QKEY 카드 개선
- **2개 버튼 배치**:
  - 📊 **거래 내역**: 전체 거래 내역 화면으로 이동
  - 💰 **출금 신청**: 출금 신청 다이얼로그 열기
- **직관적인 UI**: 버튼으로 기능 분리하여 사용성 향상

---

## 🎨 UI/UX 개선

### QKEY 카드 디자인
```
┌─────────────────────────────────────┐
│ 💰 QKEY 포인트         1,250 QKEY   │
│                                     │
│ ℹ️  채팅 5분마다 10 QKEY 적립        │
│                                     │
│ [📊 거래 내역] [💰 출금 신청]         │
└─────────────────────────────────────┘
```

### 거래 내역 카드
- **좌측**: 거래 타입 아이콘 + 색상 배경
- **중앙**: 거래 유형, 설명, 시간
- **우측**: 금액 (+ 또는 -) + 거래 후 잔액
- **출금 상태 뱃지**: 출금 거래인 경우 상태 표시

### 빈 상태 UI
- 거래 내역이 없을 때 친화적인 안내 메시지
- 각 탭별로 다른 아이콘 및 메시지

---

## 📊 QKEY 시스템 전체 구조 (Phase 1-3 완료)

### Phase 1: 기본 시스템 ✅
- ✅ 로그인 후 채팅 시 5분마다 10 QKEY 자동 적립
- ✅ 프로필 화면에서 QKEY 잔액 표시
- ✅ 1,000 QKEY 이상 시 1,000 단위 출금 신청
- ✅ 지갑 주소 입력 및 검증

### Phase 2: 관리자 승인 시스템 ✅
- ✅ 관리자 전용 QKEY 출금 승인 화면
- ✅ 4개 탭 (대기중/승인됨/완료됨/거부됨)
- ✅ 실시간 스트림 업데이트
- ✅ 승인/거부 버튼 및 관리자 메모
- ✅ 거부 시 자동 잔액 복구

### Phase 3: 사용자 거래 내역 ✅ (신규)
- ✅ 사용자별 거래 내역 화면
- ✅ 출금 신청 내역 조회
- ✅ 적립 내역 조회
- ✅ 필터링 및 검색 (5개 탭)
- ✅ 거래 상세 보기 모달
- ✅ ID/지갑주소 복사 기능

---

## 🔧 기술 스택

### 새로운 파일
- `lib/screens/qkey_history_screen.dart` (735줄)
  - QKeyHistoryScreen 위젯
  - 5개 탭 컨트롤러
  - 실시간 Firestore Stream
  - 거래 상세 모달

### 수정된 파일
- `lib/screens/profile_screen.dart`
  - QKeyHistoryScreen import 추가
  - QKEY 카드 UI 개선 (2버튼 레이아웃)

### Firestore 데이터 구조
```
users/{userId}/
  - qkeyBalance: int (잔액)

qkey_transactions/{transactionId}/
  - userId: string
  - type: string (earn/withdraw/bonus/penalty)
  - amount: int
  - balanceAfter: int
  - timestamp: Timestamp
  - description: string?
  - withdrawStatus: string? (pending/approved/rejected/completed)
  - walletAddress: string?
  - adminNote: string?
  - adminId: string?
  - processedAt: Timestamp?
```

---

## 📱 사용자 시나리오

### 시나리오 1: 적립 내역 확인
1. 프로필 화면 접속
2. QKEY 카드에서 **[거래 내역]** 버튼 클릭
3. **적립** 탭 선택
4. 5분마다 쌓인 10 QKEY 적립 내역 확인
5. 거래 카드 클릭 → 상세 정보 확인

### 시나리오 2: 출금 신청 내역 확인
1. QKEY 카드에서 **[거래 내역]** 버튼 클릭
2. **출금** 탭 선택
3. 출금 신청 내역 및 상태 확인:
   - 🟠 대기중
   - 🔵 승인됨
   - 🟢 완료
   - 🔴 거부
4. 거래 카드 클릭 → 지갑 주소, 관리자 메모 등 확인
5. 지갑 주소 복사 버튼 클릭 → 클립보드에 복사

### 시나리오 3: 출금 신청
1. QKEY 카드에서 **[출금 신청]** 버튼 클릭
2. 출금할 금액 입력 (1,000 단위)
3. 지갑 주소 입력
4. **출금 신청** 버튼 클릭
5. 관리자 승인 대기
6. 거래 내역 화면에서 상태 확인

---

## 🚀 다음 단계 (Phase 4 예정)

### QKEY 통계 및 관리 대시보드
- 📊 일별/주별/월별 적립 통계
- 📈 출금 신청 추이 그래프
- 🎁 이벤트 보너스 지급 기능
- 🔔 출금 신청/승인 푸시 알림
- 🛒 QKEY 마켓플레이스 (스티커 구매 등)
- 🎯 출금 자동 승인 규칙 설정

---

## 📦 빌드 정보

- **Flutter**: 3.41.0
- **Dart**: 3.11.0
- **APK Size**: 69 MB
- **ZIP Size**: 33 MB (53% 압축률)
- **Build Time**: ~163초

---

## 🐛 알려진 이슈

- 동영상 메시지 버그 (썸네일 미노출·클릭 불가) - 추후 해결 예정

---

## 📥 다운로드

- **APK**: `QRChat-v9.47.0-QKEY-HISTORY.apk` (69 MB)
- **ZIP**: `QRChat-v9.47.0-QKEY-HISTORY.zip` (33 MB)

---

## 📝 커밋 정보

- **Commit**: `363aa1c`
- **Date**: 2026-02-13 11:38 KST
- **Message**: Feature: Phase 3 완료 - QKEY 거래 내역 화면 통합 (v9.47.0)

---

## 👥 Credits

- **Developer**: Stevewon
- **Project**: QRChat
- **Repository**: https://github.com/Stevewon/qrchat

---

**QRChat v9.47.0 - QKEY Phase 3 완료! 🎉**
