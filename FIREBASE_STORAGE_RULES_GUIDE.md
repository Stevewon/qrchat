# 🚨 Firebase Storage 규칙 수정 필수!

## ❌ 현재 문제
```
- 동영상은 업로드 됨 ✅
- 썸네일이 검은 화면으로 표시 ❌
```

## 🔍 원인
동영상 URL에서 썸네일을 생성하려면 **Firebase Storage에서 동영상을 읽을 수 있어야** 합니다!

현재 Storage 규칙이 `request.auth != null`로 되어 있으면:
- ❌ 앱에서 동영상 URL을 읽을 수 없음
- ❌ video_thumbnail 패키지가 동영상을 다운로드할 수 없음
- ❌ 썸네일 생성 실패 → 검은 화면

## ✅ 해결 방법

### 1️⃣ Firebase Console 열기
```
https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/rules
```

### 2️⃣ "Rules" 탭 클릭

### 3️⃣ 다음 규칙으로 전체 교체
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

### 5️⃣ 10초 대기 후 앱에서 테스트!

---

## 📋 확인 방법

### 앱에서 테스트:
1. ✅ 동영상 전송
2. ✅ 썸네일이 실제 프레임으로 표시되는지 확인
3. ✅ 동영상 클릭 시 재생 확인

### Firebase Storage에서 확인:
```
https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/files
```
- `chat_videos/` 폴더에 동영상 파일 확인

---

## ⚠️ 주의사항

**이 규칙을 적용하지 않으면:**
- ❌ 동영상 썸네일이 계속 검은 화면으로 표시됩니다
- ❌ 이미지 업로드도 실패할 수 있습니다

**적용 후:**
- ✅ 동영상 썸네일이 실제 프레임으로 표시됩니다
- ✅ 이미지/동영상 업로드가 정상 작동합니다

---

## 🔗 관련 링크

| 항목 | URL |
|------|-----|
| **Storage Rules** | https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/rules |
| **Storage Files** | https://console.firebase.google.com/project/qrchat-b7a67/storage/qrchat-b7a67.appspot.com/files |
| **Firebase Console** | https://console.firebase.google.com/project/qrchat-b7a67 |

---

**⏰ 지금 바로 Firebase Console에서 규칙을 수정하세요!**
**그러면 썸네일이 정상적으로 표시됩니다!**
