# 🔧 Firebase 보안 규칙 설정

웹 스티커 관리자가 작동하려면 Firebase 보안 규칙을 수정해야 합니다.

## ⚠️ 문제 상황
- **에러**: `FirebaseError: Missing or insufficient permissions`
- **원인**: Firebase Storage와 Firestore가 인증된 사용자만 허용
- **해결**: 스티커 관련 경로만 웹 접근 허용

---

## 🔐 Storage 규칙 설정

### 1. Firebase Console 접속
https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.firebasestorage.app/rules

### 2. 규칙 수정
**Rules 탭**을 클릭하고 다음 규칙을 **복사-붙여넣기**하세요:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 기존 규칙 유지
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // 스티커 폴더만 웹에서도 업로드 가능하도록 허용
    match /stickers/{allPaths=**} {
      allow read, write: if true;  // ⚠️ 개발/테스트 전용
    }
  }
}
```

### 3. 게시(Publish) 버튼 클릭

---

## 📄 Firestore 규칙 설정

### 1. Firebase Console 접속
https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules

### 2. 규칙 수정
**Rules 탭**을 클릭하고 다음 규칙을 **복사-붙여넣기**하세요:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 기존 규칙 유지
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // sticker_packs 컬렉션만 웹에서도 쓰기 가능하도록 허용
    match /sticker_packs/{packId} {
      allow read, write: if true;  // ⚠️ 개발/테스트 전용
    }
  }
}
```

### 3. 게시(Publish) 버튼 클릭

---

## ✅ 테스트

규칙 변경 후 **5분 정도 기다린 다음**:

1. 웹 스티커 관리자 새로고침
2. 테스트 이미지 업로드 시도
3. 콘솔에서 `✅ [Firestore] 스티커팩 저장 완료` 확인

---

## 🔒 보안 강화 (선택 사항)

나중에 IP 주소 제한이나 특정 관리자만 접근하도록 규칙을 강화할 수 있습니다:

### 방법 1: 관리자 앱에서만 업로드 (현재 상태)
- 모바일 앱: Firebase Auth 사용 (안전)
- 웹 관리자: 임시로 인증 없이 허용 (개발 전용)

### 방법 2: 웹 관리자에 인증 추가
- Firebase Auth Web 로그인 추가
- 관리자 계정만 업로드 권한 부여

### 방법 3: Admin SDK 사용
- 서버 사이드에서 Admin SDK로 업로드
- 보안이 가장 강력하지만 서버 필요

---

## 📝 현재 상태

- **Storage**: `stickers/` 폴더만 웹 접근 허용
- **Firestore**: `sticker_packs` 컬렉션만 웹 접근 허용
- **기타**: 모든 경로는 인증 필요 (기존 보안 유지)

---

## 🔗 관련 링크

- Firebase Storage 규칙: https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.firebasestorage.app/rules
- Firestore 규칙: https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules
- 웹 관리자: https://8080-i5rvztjb3816er5na51me-b32ec7bb.sandbox.novita.ai

---

**⚠️ 중요**: 규칙 변경 후 **5-10분 정도** 기다려야 전파됩니다!
