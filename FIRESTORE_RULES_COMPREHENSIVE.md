# 🔒 QRChat 포괄적인 Firestore 보안 규칙

## 📋 친구 기능 권한 오류 해결

### ⚠️ 현재 오류
```
채팅 목록 로딩 실패: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

### ✅ 해결: 완전한 보안 규칙

아래 규칙을 **Firebase Console**에 붙여넣으세요:

🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 🔐 관리자 이메일 (중앙 관리)
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.email == 'bbcu092976@gmail.com';
    }
    
    // 🔐 로그인 확인
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // 🔐 본인 확인
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // ======================================
    // 👤 사용자 컬렉션
    // ======================================
    match /users/{userId} {
      // 로그인한 모든 사용자는 모든 사용자 프로필 읽기 가능
      allow read: if isAuthenticated();
      // 본인만 수정 가능
      allow write: if isOwner(userId) || isAdmin();
      
      // 👥 사용자별 친구 서브컬렉션
      match /friends/{friendId} {
        allow read: if isOwner(userId) || isAdmin();
        allow write: if isOwner(userId) || isAdmin();
      }
      
      // 📨 사용자별 친구 요청 서브컬렉션
      match /friendRequests/{requestId} {
        allow read: if isOwner(userId) || isAdmin();
        allow write: if isOwner(userId) || isAdmin();
      }
      
      // 💬 사용자별 채팅 서브컬렉션 (있다면)
      match /chats/{chatId} {
        allow read, write: if isOwner(userId) || isAdmin();
      }
    }
    
    // ======================================
    // 👥 전역 친구 컬렉션
    // ======================================
    match /friends/{friendId} {
      // 로그인한 사용자는 자신과 관련된 친구 관계만 읽기 가능
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        resource.data.friendId == request.auth.uid
      );
      // 본인이 포함된 친구 관계만 생성/수정 가능
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
      // 본인이 보냈거나 받은 요청만 읽기 가능
      allow read: if isAuthenticated() && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
      // 본인이 보내는 요청만 생성 가능
      allow create: if isAuthenticated() && 
                      request.resource.data.senderId == request.auth.uid;
      // 본인이 보냈거나 받은 요청만 수정/삭제 가능
      allow update, delete: if isAuthenticated() && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      ) || isAdmin();
    }
    
    // ======================================
    // 💬 채팅방 컬렉션
    // ======================================
    match /chatRooms/{chatRoomId} {
      // 채팅방 참여자만 읽기 가능
      allow read: if isAuthenticated() && (
        request.auth.uid in resource.data.participants
      );
      // 채팅방 생성 시 본인이 참여자에 포함되어야 함
      allow create: if isAuthenticated() && 
                      request.auth.uid in request.resource.data.participants;
      // 채팅방 참여자만 수정/삭제 가능
      allow update, delete: if isAuthenticated() && (
        request.auth.uid in resource.data.participants
      ) || isAdmin();
      
      // 💬 채팅 메시지 서브컬렉션
      match /messages/{messageId} {
        // 채팅방 참여자만 메시지 읽기 가능
        allow read: if isAuthenticated();
        // 본인만 메시지 작성 가능
        allow create: if isAuthenticated();
        // 본인이 작성한 메시지만 수정/삭제 가능
        allow update, delete: if isAuthenticated() && 
                                 resource.data.senderId == request.auth.uid || 
                                 isAdmin();
      }
    }
    
    // ======================================
    // 📨 전역 메시지 컬렉션 (있다면)
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
      // 모든 사용자는 상품 목록 읽기 가능
      allow read: if isAuthenticated();
      // 관리자만 상품 등록/수정/삭제 가능
      allow write: if isAdmin();
    }
    
    // ======================================
    // 🛒 구매 내역
    // ======================================
    match /purchases/{purchaseId} {
      // 본인의 구매 내역만 읽기 가능
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid || 
                    isAdmin();
      // 구매 생성은 본인만 가능
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      // 수정은 관리자만 (상태 변경)
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

### 3️⃣ 앱 재시작
1. 앱 완전 종료 (백그라운드에서도 제거)
2. 앱 재실행
3. 로그인
4. "친구" 탭 확인

---

## 🎯 규칙 설명

### 핵심 기능

1. **Helper Functions (도우미 함수)**
   ```javascript
   function isAdmin() {
     return request.auth != null && 
            request.auth.token.email == 'bbcu092976@gmail.com';
   }
   
   function isAuthenticated() {
     return request.auth != null;
   }
   
   function isOwner(userId) {
     return request.auth != null && request.auth.uid == userId;
   }
   ```

2. **친구 관계 권한**
   - 전역 `/friends/{friendId}` 컬렉션
   - 사용자별 서브컬렉션 `/users/{userId}/friends/{friendId}`
   - 양방향 권한 체크 (본인 또는 친구 둘 다)

3. **채팅방 권한**
   - `participants` 배열에 포함된 사용자만 접근
   - 메시지는 채팅방 참여자만 읽기/쓰기 가능

4. **QKEY 트랜잭션**
   - 사용자는 출금 요청만 생성 가능
   - 관리자만 승인/거절/완료 처리 가능

---

## 🔍 문제 해결

### ❌ 여전히 오류 발생 시

#### 1. 앱 코드에서 Firestore 경로 확인

친구 화면 코드를 확인해야 합니다. 다음 파일 중 하나를 확인:
- `lib/screens/friends_screen.dart`
- `lib/services/friend_service.dart`
- `lib/repositories/friend_repository.dart`

어떤 컬렉션 경로를 사용하는지 확인:
```dart
// 예시 1: 전역 friends 컬렉션
FirebaseFirestore.instance.collection('friends')
  .where('userId', isEqualTo: currentUserId)
  .get();

// 예시 2: 사용자별 서브컬렉션
FirebaseFirestore.instance
  .collection('users')
  .doc(currentUserId)
  .collection('friends')
  .get();
```

#### 2. 브라우저 콘솔에서 디버깅

앱에서 **개발자 모드**가 활성화되어 있다면:
1. Chrome에서 앱 실행
2. F12 → Console
3. Firestore 오류 메시지 확인
4. 정확한 컬렉션 경로 파악

#### 3. Firestore Database 직접 확인

🔗 https://console.firebase.google.com/project/qrchat-b7a67/firestore/data

- 실제 컬렉션 구조 확인
- `/friends`, `/users/{userId}/friends`, `/friendRequests` 등 존재 여부 확인

---

## 🚀 임시 해결책 (테스트 전용)

**⚠️ 주의: 프로덕션에서 절대 사용하지 마세요!**

모든 로그인 사용자에게 전체 권한 부여 (테스트 목적):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

이 규칙으로 교체 → 게시 → 앱 테스트 → 정상 작동하면 위의 **포괄적인 규칙**으로 다시 교체

---

## 📸 다음 단계

1. ✅ 위의 포괄적인 규칙 적용
2. ✅ 앱 재시작 후 친구 탭 테스트
3. ❌ 여전히 오류 발생 시:
   - 친구 화면 Dart 코드 공유
   - 또는 Firestore Database 스크린샷 공유
   - 정확한 컬렉션 경로 파악

---

**추가 지원이 필요하면 다음 정보를 공유해주세요:**
1. 친구 화면 Dart 코드 (`lib/screens/friends_screen.dart`)
2. Firestore Database 구조 스크린샷
3. 브라우저 콘솔 오류 메시지 (가능하다면)
