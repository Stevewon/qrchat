# 🔒 QRChat 최종 Firestore 보안 규칙

## ✅ 관리자 이메일 수정: hbcu00987@gmail.com

### 📋 Firebase Console에 적용할 규칙

🔗 **https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules**

아래 규칙을 **전체 복사** 후 Firebase Console에 붙여넣으세요:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 🔐 Helper Functions
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.email == 'hbcu00987@gmail.com';
    }
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // ======================================
    // 👤 사용자 컬렉션
    // ======================================
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) || isAdmin();
      
      // 사용자별 친구 서브컬렉션
      match /friends/{friendId} {
        allow read, write: if isOwner(userId) || isAdmin();
      }
      
      // 사용자별 친구 요청 서브컬렉션
      match /friendRequests/{requestId} {
        allow read, write: if isOwner(userId) || isAdmin();
      }
      
      // 사용자별 채팅 서브컬렉션
      match /chats/{chatId} {
        allow read, write: if isOwner(userId) || isAdmin();
      }
    }
    
    // ======================================
    // 👥 전역 친구 컬렉션
    // ======================================
    match /friends/{friendId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        resource.data.friendId == request.auth.uid
      );
      allow create: if isAuthenticated() && (
        request.resource.data.userId == request.auth.uid ||
        request.resource.data.friendId == request.auth.uid
      );
      allow update, delete: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        resource.data.friendId == request.auth.uid
      ) || isAdmin();
    }
    
    // ======================================
    // 📨 전역 친구 요청 컬렉션
    // ======================================
    match /friendRequests/{requestId} {
      allow read: if isAuthenticated() && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
      allow create: if isAuthenticated() && 
                      request.resource.data.senderId == request.auth.uid;
      allow update, delete: if isAuthenticated() && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      ) || isAdmin();
    }
    
    // ======================================
    // 💬 채팅방 컬렉션
    // ======================================
    match /chatRooms/{chatRoomId} {
      allow read: if isAuthenticated() && (
        request.auth.uid in resource.data.participants
      );
      allow create: if isAuthenticated() && 
                      request.auth.uid in request.resource.data.participants;
      allow update, delete: if isAuthenticated() && (
        request.auth.uid in resource.data.participants
      ) || isAdmin();
      
      // 💬 채팅 메시지 서브컬렉션
      match /messages/{messageId} {
        allow read, create: if isAuthenticated();
        allow update, delete: if isAuthenticated() && 
                                 resource.data.senderId == request.auth.uid || 
                                 isAdmin();
      }
    }
    
    // ======================================
    // 📨 전역 메시지 컬렉션
    // ======================================
    match /messages/{messageId} {
      allow read: if isAuthenticated() && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
      allow create: if isAuthenticated() && 
                      request.resource.data.senderId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                              resource.data.senderId == request.auth.uid || 
                              isAdmin();
    }
    
    // ======================================
    // 💰 QKEY 트랜잭션 컬렉션
    // ======================================
    match /qkey_transactions/{transactionId} {
      // 읽기: 본인 트랜잭션 또는 관리자
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || 
        isAdmin()
      );
      
      // 쓰기: 관리자만 (승인/거절/완료 처리)
      allow write: if isAdmin();
      
      // 사용자는 출금 요청만 생성 가능
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.type == 'withdraw' &&
                      request.resource.data.status == 'pending';
    }
    
    // ======================================
    // 📊 통계 컬렉션 (관리자 전용)
    // ======================================
    match /statistics/{statId} {
      allow read, write: if isAdmin();
    }
    
    // ======================================
    // 🔔 알림 컬렉션
    // ======================================
    match /notifications/{notificationId} {
      // 본인의 알림만 읽기 가능
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      // 알림 생성은 시스템만 (관리자)
      allow create: if isAdmin();
      // 본인의 알림만 수정 가능 (읽음 처리)
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      // 본인의 알림만 삭제 가능
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid || 
                      isAdmin();
    }
    
    // ======================================
    // 🎁 QKEY 마켓플레이스 (향후)
    // ======================================
    match /marketplace/{itemId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // ======================================
    // 🛒 구매 내역
    // ======================================
    match /purchases/{purchaseId} {
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid || 
                    isAdmin();
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
  }
}
```

---

## 🔧 적용 방법

### 1️⃣ Firebase Console 접속
🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules

### 2️⃣ 규칙 교체
1. 기존 규칙 **전체 선택** (Ctrl+A)
2. 위의 규칙 **복사 & 붙여넣기**
3. **"게시(Publish)"** 버튼 클릭

### 3️⃣ 관리자 대시보드 테스트
1. **PC 웹 관리자 대시보드 접속:**
   - 🔗 https://qrchat-b7a67.web.app
   - 또는 https://qrchat.io (SSL 발급 완료 후)

2. **hbcu00987@gmail.com** 계정으로 Google 로그인

3. **대시보드 기능 확인:**
   - 출금 요청 관리 메뉴 클릭
   - QKEY 출금 요청 목록 확인
   - 승인/거절/완료 버튼 테스트

### 4️⃣ 모바일 앱 테스트
1. **앱 완전 종료** (백그라운드에서도 제거)
2. **앱 재실행**
3. 로그인
4. **"친구"** 탭 확인
5. 오류 메시지 사라졌는지 확인

---

## ⚠️ 중요 사항

### 관리자 계정
- **올바른 이메일:** hbcu00987@gmail.com ✅
- **잘못된 이메일:** ~~bbcu092976@gmail.com~~ ❌

### 권한
- **관리자 (hbcu00987@gmail.com):**
  - QKEY 출금 요청 승인/거절/완료
  - 모든 사용자 데이터 읽기
  - 통계 데이터 읽기/쓰기
  - 알림 생성
  - 마켓플레이스 상품 관리

- **일반 사용자:**
  - 본인 데이터만 읽기/쓰기
  - 친구 목록, 채팅방, 메시지
  - QKEY 출금 요청 생성 (승인은 관리자만)

---

## 🔗 중요 링크

| 항목 | URL |
|------|-----|
| **Firestore 규칙 수정** | https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules |
| **관리자 대시보드** | https://qrchat-b7a67.web.app |
| **Firebase Auth 사용자** | https://console.firebase.google.com/project/qrchat-b7a67/authentication/users |
| **Firestore 데이터** | https://console.firebase.google.com/project/qrchat-b7a67/firestore/data |

---

## 🎯 체크리스트

### ✅ 즉시 처리
- [ ] Firebase Console에서 규칙 수정 (관리자 이메일: hbcu00987@gmail.com)
- [ ] "게시(Publish)" 버튼 클릭
- [ ] 1-2분 대기 (규칙 전파)

### ✅ 웹 관리자 대시보드 테스트
- [ ] https://qrchat-b7a67.web.app 접속
- [ ] hbcu00987@gmail.com 계정으로 로그인
- [ ] "출금 요청 관리" 메뉴 확인
- [ ] QKEY 출금 요청 목록 표시 확인
- [ ] 승인/거절/완료 버튼 작동 확인

### ✅ 모바일 앱 테스트
- [ ] 앱 완전 종료
- [ ] 앱 재실행
- [ ] "친구" 탭 확인
- [ ] "채팅" 탭 확인
- [ ] 권한 오류 사라짐 확인

---

## 💡 Pro Tips

1. **Firebase Auth 확인:**
   - 🔗 https://console.firebase.google.com/project/qrchat-b7a67/authentication/users
   - **hbcu00987@gmail.com**이 등록되어 있는지 확인

2. **다른 계정으로 로그인 시:**
   - 관리자 기능 (QKEY 승인/거절) 작동 안 함
   - 본인 데이터만 접근 가능

3. **캐시 초기화:**
   - 웹: Ctrl + F5 (강력 새로고침) 또는 시크릿 모드
   - 앱: 완전 종료 후 재실행

---

**관리자 이메일이 hbcu00987@gmail.com으로 수정되었습니다!** ✅

위의 규칙을 Firebase Console에 적용해주세요. 🚀
