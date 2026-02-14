# 🚨 Firebase Storage 업로드 실패 해결 방법

## ❌ 문제
```
동영상 업로드 실패: [firebase_storage/unauthorized]
이미지 업로드 실패: [firebase_storage/unauthorized]
```

## 🔍 원인
QRChat은 **Firebase Authentication을 사용하지 않고** Firestore 기반 로그인만 사용합니다!
하지만 Firebase Storage 보안 규칙은 `request.auth != null`을 요구하므로 업로드가 거부됩니다.

## ✅ 해결 방법 (2가지 옵션)

---

### 🎯 **옵션 1: Storage 규칙 완전 개방 (빠른 해결, 권장)**

Firebase Console에서 Storage Rules를 다음으로 변경:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;  // 모든 사용자 읽기/쓰기 허용
    }
  }
}
```

**장점:**
- ✅ 즉시 작동
- ✅ 간단함
- ✅ Firebase Auth 불필요

**단점:**
- ⚠️ 보안 취약 (누구나 업로드 가능)
- ⚠️ 프로덕션 환경에서는 비권장

---

### 🔐 **옵션 2: Firebase Auth 통합 (권장, 장기적)**

앱에 Firebase Authentication을 추가하고, 로그인 시 익명 인증 사용:

#### 1) `pubspec.yaml` 확인
```yaml
dependencies:
  firebase_auth: ^4.16.0  # 추가 확인
```

#### 2) 로그인 시 Firebase Auth 익명 로그인 추가
`lib/services/securet_auth_service.dart`의 `login` 메서드에 추가:

```dart
import 'package:firebase_auth/firebase_auth.dart';

static Future<SecuretUser?> login(String nickname, String password) async {
  try {
    // 기존 Firestore 로그인 로직...
    
    // ⭐ Firebase Auth 익명 로그인 추가 (Storage 권한용)
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('✅ Firebase Auth 익명 로그인 완료');
    }
    
    // 나머지 로직...
  } catch (e) {
    // 에러 처리...
  }
}
```

#### 3) Storage Rules 수정
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 채팅 이미지
    match /chat_images/{chatRoomId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null;  // 익명 사용자도 OK
    }
    
    // 채팅 동영상
    match /chat_videos/{chatRoomId}/{videoId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // 기타 모든 파일
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

**장점:**
- ✅ 보안 유지
- ✅ Firebase 권장 방식
- ✅ 프로덕션 환경 적합

**단점:**
- ⚠️ 코드 수정 필요
- ⚠️ 테스트 필요

---

## 🚀 **즉시 해결 (옵션 1 권장)**

### 1️⃣ Firebase Console 접속
```
https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/rules
```

### 2️⃣ "Rules" 탭 클릭

### 3️⃣ 다음 규칙 복사 붙여넣기
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### 4️⃣ "게시" (Publish) 버튼 클릭

### 5️⃣ 앱에서 이미지/동영상 전송 테스트!

---

## 📋 **진단 체크리스트**

- [ ] Firebase Storage Rules에서 `request.auth != null` 제거
- [ ] Rules를 `if true`로 변경
- [ ] "Publish" 버튼 클릭
- [ ] 5~10초 대기 (규칙 적용)
- [ ] 앱 재시작 (선택사항)
- [ ] 이미지 전송 테스트
- [ ] 동영상 전송 테스트

---

## 🔗 **관련 링크**

| 항목 | URL |
|------|-----|
| **Storage Rules** | https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/rules |
| **Storage Files** | https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/files |
| **Firebase Console** | https://console.firebase.google.com/project/qrchat-b7a67 |

---

## ⚠️ **중요 참고 사항**

### 현재 상황:
- ✅ **Firestore**: 로그인 정보 저장 (nickname, password)
- ❌ **Firebase Auth**: 사용하지 않음!
- ⚠️ **Firebase Storage**: Auth 필요함!

### 불일치 문제:
```
Firestore 로그인 (O) → Firebase Auth 로그인 (X) → Storage 업로드 (X)
```

### 해결 후:
```
Option 1: Storage Rules 개방 → Storage 업로드 (O) ✅
Option 2: Firebase Auth 추가 → Storage 업로드 (O) ✅
```

---

## 📝 **마지막 체크**

Firebase Console에서 현재 규칙 확인:
```
https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/rules
```

만약 다음과 같은 규칙이 있다면:
```javascript
allow write: if request.auth != null;  // ❌ 이게 문제!
```

다음으로 변경:
```javascript
allow write: if true;  // ✅ 모두 허용
```

---

**지금 바로 Firebase Console에서 규칙을 수정하고 테스트해주세요!** 🚀
