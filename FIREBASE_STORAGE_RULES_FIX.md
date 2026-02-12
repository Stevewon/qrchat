# Firebase Storage Rules - 동영상 업로드 수정

## 문제
- 이미지는 정상 업로드되지만 동영상 업로드 실패
- 코드에서 `chat_videos/` 경로 사용 중

## 해결책

Firebase Storage Rules를 다시 확인하고 수정하세요:

**Storage Rules 페이지:**
https://console.firebase.google.com/project/qrchat-b7a67/storage/rules

**기존 코드 전체 삭제 후 아래 코드로 교체:**

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // 스티커 파일
    match /stickers/{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // 프로필 사진
    match /profile_photos/{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // 채팅 이미지
    match /chat_images/{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // 채팅 동영상 ⭐ 이 부분 추가
    match /chat_videos/{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // 채팅 첨부 파일
    match /chat_attachments/{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // 모든 파일 (백업용)
    match /{allPaths=**} {
      allow read: if true;
      allow write: if true;
    }
  }
}
```

## 추가 확인사항

만약 위 규칙을 적용해도 안 되면:

1. **파일 크기 확인**: 동영상이 너무 크지 않은지 확인 (50MB 이하 권장)
2. **타임아웃 증가**: 업로드 시간이 오래 걸릴 수 있음
3. **네트워크 상태**: Wi-Fi 연결 권장

## 테스트 방법

1. Storage Rules 수정 후 "게시" 클릭
2. 앱에서 작은 동영상(5초 이하, 10MB 이하)으로 테스트
3. 콘솔 로그 확인 (adb logcat 또는 Android Studio)
