# 🔒 QRChat 로그인 오류 해결 - Firestore 규칙

## ⚠️ 문제: 로그인 화면에서 권한 오류 발생

```
❌ 로그인 오류
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

**원인:** 로그인 전에 Firestore 데이터를 읽으려고 시도하지만, 현재 규칙이 인증된 사용자만 허용

---

## 🚀 즉시 해결: 2단계 접근

### 1단계: 임시 테스트 규칙 (즉시 적용)

🔗 **https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules**

**임시 규칙 (로그인 테스트용):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 모든 인증된 사용자에게 전체 권한 부여
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**적용:**
1. 위 규칙 복사
2. Firebase Console → Firestore → 규칙 → 붙여넣기
3. **"게시(Publish)"** 클릭
4. 1분 대기
5. 앱 재시작 → 로그인 시도

---

### 2단계: 프로덕션 규칙 (로그인 성공 후 적용)

임시 규칙으로 로그인이 성공하면, 아래의 **보안이 강화된 규칙**으로 교체:

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
      // 모든 인증된 사용자는 모든 사용자 프로필 읽기 가능
      allow read: if isAuthenticated();
      // 본인만 수정 가능 (또는 관리자)
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(userId) || isAdmin();
      
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
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || 
        isAdmin()
      );
      allow write: if isAdmin();
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
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      allow create: if isAdmin();
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
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

**핵심 변경 사항:**
```javascript
match /users/{userId} {
  allow read: if isAuthenticated();     // 모든 사용자 읽기 가능
  allow create: if isAuthenticated();   // 신규 사용자 생성 가능
  allow update, delete: if isOwner(userId) || isAdmin();  // 본인/관리자만 수정
}
```

---

## 🔍 로그인 흐름 분석

### 정상적인 로그인 프로세스

1. **사용자가 이메일/비밀번호 입력**
2. **Firebase Auth 로그인 시도** (Firestore 규칙과 무관)
3. **로그인 성공** → `request.auth` 생성
4. **Firestore에서 사용자 프로필 읽기** (`/users/{userId}`)
   - ✅ 이제 `request.auth != null`이므로 읽기 허용
5. **앱 메인 화면 진입**

### 문제가 있던 흐름

1. **로그인 전** → `request.auth == null`
2. **Firestore 규칙:** `allow read: if request.auth != null`
3. ❌ **권한 거부** → 로그인 실패

---

## 📝 적용 체크리스트

### 1단계: 임시 규칙 적용
- [ ] Firebase Console 접속
- [ ] 임시 테스트 규칙 붙여넣기
- [ ] "게시(Publish)" 클릭
- [ ] 1분 대기
- [ ] 앱 재시작
- [ ] 로그인 성공 확인 ✅

### 2단계: 프로덕션 규칙 적용
- [ ] 임시 규칙으로 로그인 성공 확인
- [ ] 프로덕션 규칙으로 교체
- [ ] "게시(Publish)" 클릭
- [ ] 앱 재시작
- [ ] 모든 기능 정상 작동 확인

---

## 🔗 중요 링크

| 항목 | URL |
|------|-----|
| **Firestore 규칙 수정** | https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules |
| **Firebase Auth 사용자** | https://console.firebase.google.com/project/qrchat-b7a67/authentication/users |
| **Firestore 데이터** | https://console.firebase.google.com/project/qrchat-b7a67/firestore/data |

---

## 💡 Pro Tips

1. **임시 규칙은 테스트 목적으로만 사용**
   - 로그인 성공 확인 후 즉시 프로덕션 규칙으로 교체

2. **Firebase Auth vs Firestore 규칙**
   - Firebase Auth: 로그인/인증만 담당
   - Firestore 규칙: 데이터베이스 접근 권한 관리
   - 로그인이 성공해도 Firestore 규칙이 잘못되면 데이터 읽기 실패

3. **캐시 초기화**
   - 규칙 변경 후 앱 완전 종료 필수
   - 백그라운드에서도 제거

---

## 🎯 예상 결과

✅ **1단계 (임시 규칙) 적용 후:**
- 로그인 성공
- 친구 목록 표시
- 채팅 목록 표시
- 모든 기능 정상 작동

✅ **2단계 (프로덕션 규칙) 적용 후:**
- 보안 강화
- 본인 데이터만 수정 가능
- 관리자 권한 정상 작동
- 모든 기능 유지

---

**먼저 임시 규칙을 적용해서 로그인이 되는지 확인해주세요!** 🚀
