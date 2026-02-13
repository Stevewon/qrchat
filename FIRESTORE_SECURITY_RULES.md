# 🔒 Firestore 보안 규칙 설정 가이드

## ⚠️ 현재 문제

관리자 대시보드에서 QKEY 출금 요청 목록을 불러올 때 **권한 오류**가 발생합니다.

```
Firebase: Missing or insufficient permissions.
(firestore/permission-denied)
```

**원인:** Firestore 보안 규칙에서 관리자 이메일이 제대로 설정되지 않았거나, 로그인한 계정이 관리자 이메일과 일치하지 않습니다.

---

## ✅ 해결 방법

### 1️⃣ Firebase Console에서 보안 규칙 수정

1. **Firebase Console 열기:**
   - 🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules

2. **현재 규칙 확인:**
   - 왼쪽 메뉴에서 **Firestore Database** 클릭
   - 상단 탭에서 **규칙(Rules)** 클릭
   - 현재 규칙 코드 확인

3. **새로운 규칙으로 교체:**

---

## 📋 추천 보안 규칙

### 🟢 옵션 1: 프로덕션 규칙 (권장)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 👤 사용자 컬렉션
    match /users/{userId} {
      // 로그인한 모든 사용자는 읽기 가능
      allow read: if request.auth != null;
      // 본인만 수정 가능
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 💰 QKEY 트랜잭션 (핵심!)
    match /qkey_transactions/{transactionId} {
      // 읽기: 본인 트랜잭션 또는 관리자
      allow read: if request.auth != null && 
                    (resource.data.userId == request.auth.uid || 
                     request.auth.token.email == 'bbcu092976@gmail.com');
      
      // 쓰기: 관리자만
      allow write: if request.auth != null && 
                     request.auth.token.email == 'bbcu092976@gmail.com';
    }
    
    // 💬 채팅방
    match /chatRooms/{chatRoomId} {
      allow read, write: if request.auth != null;
      
      // 채팅 메시지 서브컬렉션
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // 👥 친구 관계
    match /friends/{friendId} {
      allow read, write: if request.auth != null;
    }
    
    // 📊 통계 (관리자만)
    match /statistics/{statId} {
      allow read: if request.auth != null && 
                    request.auth.token.email == 'bbcu092976@gmail.com';
      allow write: if request.auth != null && 
                     request.auth.token.email == 'bbcu092976@gmail.com';
    }
  }
}
```

---

### 🟡 옵션 2: 테스트 규칙 (임시)

**⚠️ 주의:** 테스트 목적으로만 사용! 프로덕션에서는 사용하지 마세요.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 로그인한 모든 사용자에게 모든 권한 부여
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🛠️ 적용 방법

### 1. Firebase Console에서 직접 수정

1. 🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules
2. 기존 규칙 전체 선택 (Ctrl+A)
3. 위의 **옵션 1** 코드 전체 복사 → 붙여넣기
4. **게시(Publish)** 버튼 클릭
5. 1-2분 대기 (규칙이 전파되는 시간)

### 2. 확인 및 테스트

1. **관리자 대시보드 새로고침:**
   - 🔗 https://qrchat-b7a67.web.app
   - 또는 https://qrchat.io (SSL 발급 완료 후)
   - **Ctrl + F5** (강력 새로고침)
   - 또는 시크릿 모드로 열기

2. **로그인:**
   - **bbcu092976@gmail.com** 계정으로 Google 로그인
   - ⚠️ 다른 계정으로 로그인하면 권한 오류 발생!

3. **대시보드 확인:**
   - 좌측 메뉴에서 **"출금 요청 관리"** 클릭
   - QKEY 출금 요청 목록이 표시되는지 확인
   - 승인/거절 버튼이 작동하는지 테스트

---

## 🔍 문제 해결

### ❌ 여전히 권한 오류가 발생하는 경우

#### 1. 관리자 이메일 확인

**현재 로그인한 계정 확인:**
- 🔗 https://myaccount.google.com/

**Firebase Authentication 사용자 목록:**
- 🔗 https://console.firebase.google.com/project/qrchat-b7a67/authentication/users
- **bbcu092976@gmail.com**이 등록되어 있는지 확인

#### 2. 브라우저 콘솔 확인

1. 대시보드 페이지에서 **F12** 키 → 개발자 도구 열기
2. **Console** 탭 클릭
3. 빨간색 오류 메시지 확인:

```javascript
// 예상 오류
FirebaseError: Missing or insufficient permissions.
  at firestore/permission-denied
  
// 또는
Error: User not authenticated
```

4. 오류 내용을 복사해서 공유해주세요.

#### 3. 캐시 및 세션 초기화

```bash
# 방법 1: 시크릿 모드 사용
Ctrl + Shift + N (Chrome)
Command + Shift + N (Mac Chrome)

# 방법 2: 캐시 삭제
F12 → Application/Storage 탭 → Clear site data

# 방법 3: 로그아웃 후 재로그인
대시보드 우측 상단 → Logout → 재로그인
```

#### 4. Firebase Auth Token 갱신

관리자 대시보드 코드에서 토큰 갱신 확인:

```javascript
// admin_dashboard.html 파일에서 확인
firebase.auth().currentUser.getIdToken(true)
  .then(token => console.log('Token refreshed:', token))
  .catch(error => console.error('Token refresh failed:', error));
```

---

## 📊 보안 규칙 설명

### 핵심 로직

```javascript
// QKEY 트랜잭션 규칙
match /qkey_transactions/{transactionId} {
  // 읽기 권한
  allow read: if request.auth != null &&  // 로그인 필수
                (resource.data.userId == request.auth.uid ||  // 본인 데이터
                 request.auth.token.email == 'bbcu092976@gmail.com');  // 또는 관리자
  
  // 쓰기 권한
  allow write: if request.auth != null &&  // 로그인 필수
                  request.auth.token.email == 'bbcu092976@gmail.com';  // 관리자만
}
```

### 변수 설명

- **`request.auth`**: 현재 로그인한 사용자 정보
- **`request.auth.uid`**: 사용자 UID (Firebase Auth)
- **`request.auth.token.email`**: 사용자 이메일 주소
- **`resource.data`**: Firestore에 저장된 문서 데이터
- **`resource.data.userId`**: 트랜잭션 소유자 UID

---

## 🎯 체크리스트

배포 후 아래 항목을 확인하세요:

- [ ] Firebase Console에서 보안 규칙 게시 완료
- [ ] 1-2분 대기 (규칙 전파)
- [ ] https://qrchat-b7a67.web.app 접속
- [ ] **bbcu092976@gmail.com** 계정으로 로그인
- [ ] "출금 요청 관리" 메뉴 클릭
- [ ] QKEY 출금 요청 목록 표시 확인
- [ ] 승인/거절 버튼 작동 확인
- [ ] 실시간 업데이트 동작 확인 (다른 탭에서 상태 변경 시)

---

## 🔗 유용한 링크

- **Firebase Console:** https://console.firebase.google.com/project/qrchat-b7a67
- **Firestore 규칙 편집:** https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules
- **Authentication 사용자:** https://console.firebase.google.com/project/qrchat-b7a67/authentication/users
- **관리자 대시보드:** https://qrchat-b7a67.web.app (또는 https://qrchat.io)
- **Google 계정 확인:** https://myaccount.google.com/

---

## 🚀 다음 단계

보안 규칙 적용 후:

1. ✅ 관리자 대시보드 접속 및 로그인 테스트
2. ✅ QKEY 출금 요청 목록 확인
3. ✅ 승인/거절 기능 테스트
4. ✅ 실시간 업데이트 동작 확인
5. 🔜 **qrchat.io** 도메인 SSL 발급 대기 (1-2시간)
6. 🔜 Phase 4 개발 시작:
   - 일별/주별/월별 통계 대시보드
   - 자동 승인 규칙 설정
   - 푸시 알림 시스템
   - QKEY 마켓플레이스 (스티커, 프리미엄 기능)

---

**문제가 해결되지 않으면 브라우저 콘솔 스크린샷을 공유해주세요!** 📸
