# QKEY 잔액 불일치 문제 해결 완료 ✅

## 📋 문제 상황

**사용자**: 바보바보 (ID: 1770301221720)
- 앱 표시 잔액: **300 QKEY** ❌
- 실제 잔액: **60 QKEY** ✅
- 거래 내역: 30건 × 2 QKEY = 60 QKEY

## 🔍 원인 분석

Firestore `users` 컬렉션에 **두 개의 QKEY 잔액 필드**가 존재:

1. **`qkeyBalance`** (camelCase)
   - 앱이 실제로 읽는 필드 (`qkey_service.dart` line 31)
   - 값: **300 QKEY** (이전 값 그대로)

2. **`qkey_balance`** (snake_case)
   - 스크립트들이 업데이트하는 필드
   - 값: **60 QKEY** (올바른 값)

### 왜 이런 일이 발생했나?

- 이전에 QKEY 10 → 2로 변경하는 스크립트들이 `qkey_balance` 필드를 업데이트
- 하지만 앱 코드는 `qkeyBalance` (camelCase)를 읽음
- 결과: 앱은 이전 값(300 QKEY)을 계속 표시

## ✅ 해결 방법

### 1. 필드 동기화 스크립트 작성

파일: `sync_qkey_balance_fields.js`

```javascript
// 모든 사용자의 qkeyBalance를 qkey_balance 값으로 동기화
await db.collection('users').doc(userId).update({
  qkeyBalance: qkey_balance
});
```

### 2. 스크립트 실행 결과

```
📊 Found 47 users
✅ Synced users: 7
⏭️  Skipped users (already synced): 40
```

#### 동기화된 사용자 목록:

| 사용자 | 이전 잔액 | 올바른 잔액 |
|--------|-----------|-------------|
| 바보바보 (1770301221720) | 300 QKEY | **60 QKEY** |
| 하루 (1770363136308) | 76 QKEY | **14 QKEY** |
| 법강 (1770434260975) | 52 QKEY | **10 QKEY** |
| sunshine (1770305983347) | 22 QKEY | **4 QKEY** |
| 파가니존다 (1770301216772) | 172 QKEY | **0 QKEY** |
| 한시황제 (1770314258803) | 20 QKEY | **0 QKEY** |
| 도무지2 (1771068120535) | 20 QKEY | **0 QKEY** |

## 🎯 결과

### 데이터베이스 확인:
```
👤 User: 바보바보 (1770301221720)
✅ qkeyBalance: 60 QKEY
✅ qkey_balance: 60 QKEY
Status: ✅ SYNCED!
```

### 앱에서 확인해야 할 사항:

1. **로그아웃 후 다시 로그인** (또는 앱 재시작)
2. 프로필 → QKEY 잔액 확인
3. 예상 결과: **60 QKEY** 표시
4. 거래 내역: 모든 항목이 **+2 QKEY**로 표시

## 📱 사용자 조치 사항

**방법 1: 로그아웃/로그인**
1. 프로필 → 설정 → 로그아웃
2. 다시 로그인
3. QKEY 잔액 확인 (60 QKEY로 표시되어야 함)

**방법 2: 앱 재시작**
1. 앱 완전 종료
2. 앱 다시 실행
3. QKEY 잔액 확인

**방법 3: 캐시 삭제 (최후의 수단)**
1. Android 설정 → 앱 → QRChat
2. 저장공간 → 캐시 삭제
3. 앱 재시작

## 🔧 향후 방지 대책

### 권장사항:
앞으로 Firestore 필드 업데이트 시:
1. **앱 코드에서 사용하는 필드명 확인** (`qkey_service.dart` 참조)
2. **일관된 네이밍 사용** (camelCase 또는 snake_case 중 하나)
3. **테스트 계정으로 먼저 확인**

### 현재 앱 코드:
```dart
// lib/services/qkey_service.dart, line 31
return (data?['qkeyBalance'] as int?) ?? 0;
```
→ `qkeyBalance` (camelCase)를 사용 중

## 📊 통계

- 총 사용자 수: 47명
- 동기화된 사용자: 7명
- QKEY 거래 내역: 65건 (모두 2 QKEY로 통일)
- 수정 완료 일시: 2026-02-14

## ✅ 체크리스트

- [x] 문제 원인 파악 (필드명 불일치)
- [x] 동기화 스크립트 작성
- [x] 스크립트 실행 (7명 동기화 완료)
- [x] 데이터베이스 확인 (60 QKEY 확인)
- [x] Git 커밋 & 푸시
- [ ] 사용자 앱에서 확인 (로그아웃/로그인 필요)

---

**문제 완전 해결! 🎉**

이제 앱을 재시작하거나 로그아웃 후 다시 로그인하면 올바른 QKEY 잔액(60 QKEY)이 표시됩니다.
