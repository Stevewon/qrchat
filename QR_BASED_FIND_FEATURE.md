# 🔍 QR 주소 기반 닉네임/비밀번호 찾기 기능

## 📋 기능 개요

로그인 화면에 **QR 주소**를 입력하면 가입 시 사용한 **닉네임**과 **비밀번호**를 찾을 수 있는 기능을 추가했습니다.

## ✨ 주요 기능

### 1️⃣ **닉네임 찾기**
- QR 주소 입력 → 가입된 닉네임 표시
- 찾은 닉네임을 로그인 입력란에 자동 입력

### 2️⃣ **비밀번호 찾기**
- QR 주소 입력 → 가입된 비밀번호 표시
- 찾은 비밀번호를 로그인 입력란에 자동 입력

## 🎯 사용 방법

### **모바일 앱**

#### 닉네임 찾기:
1. 로그인 화면 접속
2. **"닉네임 찾기"** 버튼 클릭
3. 가입 시 사용한 **QR 주소** 입력 (예: `https://example.com/qr?token=abc123`)
4. **"찾기"** 버튼 클릭
5. ✅ 닉네임이 표시됨
6. **"입력하고 닫기"** 클릭 시 자동으로 닉네임 입력란에 입력됨

#### 비밀번호 찾기:
1. 로그인 화면 접속
2. **"비밀번호 찾기"** 버튼 클릭
3. 가입 시 사용한 **QR 주소** 입력
4. **"찾기"** 버튼 클릭
5. ✅ 비밀번호가 표시됨
6. **"입력하고 닫기"** 클릭 시 자동으로 비밀번호 입력란에 입력됨

## 🖥️ UI 구성

```
┌─────────────────────────────┐
│         QRChat              │
│         로그인              │
├─────────────────────────────┤
│ [닉네임 입력란]             │
│ [비밀번호 입력란]           │
├─────────────────────────────┤
│     [로그인 버튼]           │
├─────────────────────────────┤
│ [닉네임 찾기] | [비밀번호 찾기] │  ← 새로 추가!
├─────────────────────────────┤
│ 계정이 없으신가요? [회원가입] │
└─────────────────────────────┘
```

## 🔧 기술 구현

### **Backend (Firestore 쿼리)**

#### 닉네임 찾기 메서드:
```dart
static Future<String?> findNicknameByQrUrl(String qrUrl) async {
  final querySnapshot = await _firestore
      .collection('users')
      .where('qrCodeUrl', isEqualTo: qrUrl)
      .limit(1)
      .get();

  if (querySnapshot.docs.isEmpty) {
    return null;
  }

  final userData = querySnapshot.docs.first.data();
  return userData['nickname'] ?? '';
}
```

#### 비밀번호 찾기 메서드:
```dart
static Future<String?> findPasswordByQrUrl(String qrUrl) async {
  final querySnapshot = await _firestore
      .collection('users')
      .where('qrCodeUrl', isEqualTo: qrUrl)
      .limit(1)
      .get();

  if (querySnapshot.docs.isEmpty) {
    return null;
  }

  final userData = querySnapshot.docs.first.data();
  return userData['password'] ?? '';
}
```

### **Frontend (Flutter UI)**

#### 로그인 화면 버튼:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    TextButton(
      onPressed: _findNickname,
      child: const Text('닉네임 찾기'),
    ),
    Text('|'),
    TextButton(
      onPressed: _findPassword,
      child: const Text('비밀번호 찾기'),
    ),
  ],
)
```

## 📊 동작 흐름

### **닉네임 찾기**
```
사용자 → [닉네임 찾기] 클릭
      → QR 주소 입력 다이얼로그
      → QR 주소 입력 (예: https://example.com/qr?token=abc)
      → [찾기] 클릭
      → Firestore 쿼리 (qrCodeUrl == 입력값)
      → ✅ 닉네임 찾음!
      → 다이얼로그 표시: "찾은 닉네임: 바보바보"
      → [입력하고 닫기] 클릭
      → 닉네임 입력란에 자동 입력
```

### **비밀번호 찾기**
```
사용자 → [비밀번호 찾기] 클릭
      → QR 주소 입력 다이얼로그
      → QR 주소 입력
      → [찾기] 클릭
      → Firestore 쿼리 (qrCodeUrl == 입력값)
      → ✅ 비밀번호 찾음!
      → 다이얼로그 표시: "찾은 비밀번호: 1234"
      → [입력하고 닫기] 클릭
      → 비밀번호 입력란에 자동 입력
```

## ⚠️ 예외 처리

### **1. QR 주소로 계정을 찾을 수 없는 경우**
```
❌ 해당 QR 주소로 가입된 계정을 찾을 수 없습니다
```

### **2. QR 주소를 입력하지 않은 경우**
- 다이얼로그가 닫히고 아무 동작도 하지 않음

### **3. Firestore 오류**
```
❌ 닉네임 찾기 오류

[오류 메시지 표시]
```

## 🔐 보안 고려사항

- **QR 주소는 고유값**이므로 한 계정만 조회됨
- Firestore 보안 규칙에서 읽기 권한 확인 필요
- 비밀번호가 평문으로 저장되므로 실제 서비스에서는 **암호화** 필요

## 📱 테스트 시나리오

### **테스트 1: 정상 닉네임 찾기**
1. 로그인 화면 → "닉네임 찾기" 클릭
2. 유효한 QR 주소 입력: `https://example.com/qr?token=test123`
3. ✅ 결과: 닉네임 "바보바보" 표시
4. "입력하고 닫기" 클릭
5. ✅ 닉네임 입력란에 "바보바보" 자동 입력됨

### **테스트 2: 정상 비밀번호 찾기**
1. 로그인 화면 → "비밀번호 찾기" 클릭
2. 유효한 QR 주소 입력
3. ✅ 결과: 비밀번호 "1234" 표시
4. "입력하고 닫기" 클릭
5. ✅ 비밀번호 입력란에 "1234" 자동 입력됨

### **테스트 3: 존재하지 않는 QR 주소**
1. 로그인 화면 → "닉네임 찾기" 클릭
2. 잘못된 QR 주소 입력: `https://invalid.com/qr`
3. ❌ 오류 메시지: "해당 QR 주소로 가입된 계정을 찾을 수 없습니다"

### **테스트 4: 찾기 후 로그인**
1. "닉네임 찾기" → QR 주소 입력 → 닉네임 자동 입력
2. "비밀번호 찾기" → QR 주소 입력 → 비밀번호 자동 입력
3. "로그인" 버튼 클릭
4. ✅ 로그인 성공 → 홈 화면으로 이동

## 📝 변경된 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/services/securet_auth_service.dart` | `findNicknameByQrUrl()`, `findPasswordByQrUrl()` 메서드 추가 |
| `lib/screens/login_screen.dart` | `_findNickname()`, `_findPassword()` 메서드 추가, UI 버튼 추가 |

## 🔗 주요 링크

- **GitHub 커밋**: https://github.com/Stevewon/qrchat/commit/48a5c32
- **GitHub 저장소**: https://github.com/Stevewon/qrchat
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67/overview
- **Firestore Users**: https://console.firebase.google.com/project/qrchat-b7a67/firestore/data/~2Fusers

## 💡 향후 개선 사항

1. **비밀번호 암호화**: 현재 평문 저장 → bcrypt 등으로 암호화
2. **SMS/이메일 인증**: QR 주소 외에 추가 인증 수단
3. **찾기 횟수 제한**: 무차별 대입 공격 방지
4. **QR 코드 스캔**: 텍스트 입력 대신 카메라로 QR 스캔
5. **최근 검색 기록**: 자주 찾는 QR 주소 저장

## 🎉 완료!

이제 사용자가 **QR 주소**만 있으면 언제든지 **닉네임**과 **비밀번호**를 찾을 수 있습니다!
