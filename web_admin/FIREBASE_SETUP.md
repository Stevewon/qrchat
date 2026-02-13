# 🔥 Firebase 설정 완료 안내

## ✅ 수정 완료

Firebase 설정이 실제 프로젝트 설정으로 업데이트되었습니다!

### 변경 사항
```javascript
// 이전 (잘못된 설정)
projectId: "qrchat-68c0d"
apiKey: "AIzaSyDHwYDu1ZDP2xRHgSWUbp2yz2VvSIZXI7A"

// 현재 (올바른 설정)  
projectId: "qrchat-b7a67"
apiKey: "AIzaSyDEoFb4ovEEyrSKs7Se9JToLzHA26A6ga8"
```

---

## 🔧 Firebase Console 추가 설정 필요

### 1️⃣ Authentication - 웹 앱 활성화

**Firebase Console 접속**
```
https://console.firebase.google.com/project/qrchat-b7a67/authentication/providers
```

**Google 로그인 활성화**
1. Authentication → Sign-in method
2. Google → 사용 설정 (Enable)
3. 프로젝트 공개용 이름 입력
4. 프로젝트 지원 이메일 선택
5. 저장

**승인된 도메인 추가** (필요 시)
1. Authentication → Settings → Authorized domains
2. 다음 도메인 추가:
   - `localhost`
   - `*.sandbox.novita.ai` (개발용)
   - 실제 배포 도메인 (프로덕션)

---

### 2️⃣ Firestore Database - 보안 규칙 설정

**Firestore Rules**
```
https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules
```

**추천 보안 규칙**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // QKEY 트랜잭션 - 인증된 사용자는 읽기 가능, 관리자만 수정 가능
    match /qkey_transactions/{transactionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.email in [
                        'your-admin-email@gmail.com',  // ⚠️ 실제 관리자 이메일로 변경!
                        'admin@qrchat.com'
                      ];
    }
    
    // 사용자 데이터 - 본인 또는 관리자만 수정 가능
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && 
                       (request.auth.uid == userId || 
                        request.auth.token.email in [
                          'your-admin-email@gmail.com',
                          'admin@qrchat.com'
                        ]);
      allow delete: if request.auth != null && 
                       request.auth.token.email in [
                         'your-admin-email@gmail.com'
                       ];
    }
    
    // 기타 컬렉션들...
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

### 3️⃣ 웹 앱 등록 확인

**프로젝트 설정**
```
https://console.firebase.google.com/project/qrchat-b7a67/settings/general
```

**웹 앱이 등록되어 있는지 확인**
- "앱" 섹션에서 웹 앱(🌐) 아이콘 확인
- 없으면 "앱 추가" → "웹" 선택
- 앱 닉네임: "QRChat Admin Dashboard"
- Firebase Hosting 설정: 선택 사항

---

## 🚀 이제 사용 가능!

### 접속 URL
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/web_admin/admin_dashboard.html
```

### 사용 순서
1. ✅ 페이지 새로고침 (Ctrl + F5)
2. ✅ "Google로 로그인" 클릭
3. ✅ Google 계정 선택
4. ✅ 로그인 성공!
5. ✅ QKEY 출금 관리 시작

---

## ⚠️ 문제 해결

### 여전히 API Key 오류가 발생하는 경우

**1. 브라우저 캐시 삭제**
```
Chrome: Ctrl + Shift + Delete
Firefox: Ctrl + Shift + Delete
Safari: Cmd + Option + E
```

**2. Firebase Console에서 API Key 확인**
```
https://console.firebase.google.com/project/qrchat-b7a67/settings/general
→ "내 앱" 섹션
→ 웹 앱 선택
→ SDK 설정 및 구성
→ Config 복사
```

**3. 수동으로 설정 교체**
만약 위 설정이 작동하지 않으면:
1. `web_admin/admin_dashboard.html` 파일 열기
2. `firebaseConfig` 객체 찾기 (약 700번째 줄)
3. Firebase Console에서 복사한 설정으로 교체
4. 저장 후 페이지 새로고침

---

## 📞 추가 지원

문제가 계속되면:
1. 브라우저 개발자 도구 열기 (F12)
2. Console 탭 확인
3. 에러 메시지 캡처
4. GitHub Issues에 제보

---

**🎉 설정 완료! 이제 PC에서 편리하게 관리하세요!**
