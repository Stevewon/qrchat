# 🚫 QRChat 사용자 강제 차단 기능 가이드

## 📋 목차
1. [기능 개요](#기능-개요)
2. [사용 방법](#사용-방법)
3. [기술 구현](#기술-구현)
4. [배포 가이드](#배포-가이드)
5. [테스트 시나리오](#테스트-시나리오)

---

## 🎯 기능 개요

### 주요 기능
✅ **관리자 웹 대시보드에서 사용자 차단/해제**
- 각 사용자 행에 🚫 차단 / 🔓 차단해제 버튼 추가
- 차단 상태에 따라 시각적으로 구분 (✅ 정상 / 🚫 차단됨)

✅ **차단된 사용자 로그인 차단**
- 차단된 계정으로 로그인 시도 시 명확한 오류 메시지 표시
- 비밀번호 확인 전에 차단 상태 먼저 체크

✅ **동일 QR 코드로 재가입 차단**
- 차단된 사용자의 QR 코드를 DB에 저장
- 동일 QR 코드로 신규 가입 시도 시 차단

✅ **차단 이력 기록**
- `ban_logs` 컬렉션에 모든 차단/해제 기록 저장
- 관리자 이메일, 타임스탬프 등 상세 정보 기록

---

## 📱 사용 방법

### 1️⃣ 웹 관리자 대시보드에서 사용자 차단

1. **관리자 대시보드 접속**
   ```
   https://qrchat-b7a67.web.app/admin_dashboard.html
   ```

2. **Google 계정으로 로그인**
   - 이메일: `hbcu00987@gmail.com` (관리자 계정)

3. **👥 사용자 관리 메뉴 선택**

4. **차단하려는 사용자 찾기**
   - 검색 기능 사용 (닉네임 또는 사용자 ID)
   - 또는 목록에서 직접 찾기

5. **🚫 차단 버튼 클릭**
   - 확인 다이얼로그가 표시됨
   - 차단 시 영향을 확인하고 승인

6. **차단 완료 확인**
   - 사용자 상태가 "🚫 차단됨"으로 변경
   - 차단 버튼이 "🔓 차단해제" 버튼으로 변경

### 2️⃣ 차단된 사용자가 로그인 시도할 때

차단된 사용자가 모바일 앱에서 로그인 시도 시:
```
🚫 차단된 계정입니다

관리자에 의해 차단되었습니다.
차단 해제 전까지 로그인할 수 없습니다.

문의: 관리자에게 연락해주세요.
```

### 3️⃣ 차단된 QR 코드로 재가입 시도할 때

동일한 QR 코드로 신규 가입 시도 시:
```
🚫 차단된 QR 코드입니다

이 QR 코드로는 가입할 수 없습니다.
차단된 계정의 QR 코드입니다.

문의: 관리자에게 연락해주세요.
```

### 4️⃣ 차단 해제

1. 웹 관리자 대시보드 접속
2. 차단된 사용자 찾기
3. **🔓 차단해제 버튼 클릭**
4. 확인 후 차단 해제
5. 사용자가 다시 정상적으로 로그인 가능

---

## 🔧 기술 구현

### Firestore 데이터 구조

#### 1. `users` 컬렉션에 추가된 필드
```javascript
{
  // 기존 필드들...
  "banned": false,              // boolean - 차단 여부
  "bannedAt": Timestamp,        // Timestamp - 차단 시각
  "bannedBy": "admin@email.com", // string - 차단한 관리자 이메일
  "bannedQrCode": "https://...", // string - 차단된 QR 코드 URL
  "unbannedAt": Timestamp,      // Timestamp - 차단 해제 시각
  "unbannedBy": "admin@email.com" // string - 차단 해제한 관리자 이메일
}
```

#### 2. `ban_logs` 컬렉션 (새로 생성)
```javascript
{
  "userId": "user_id_here",       // string - 사용자 ID
  "nickname": "사용자닉네임",      // string - 닉네임
  "qrCodeUrl": "https://...",     // string - QR 코드 URL
  "action": "ban",                // string - 'ban' 또는 'unban'
  "timestamp": Timestamp,         // Timestamp - 작업 시각
  "adminEmail": "admin@email.com" // string - 관리자 이메일
}
```

### 코드 변경 사항

#### 1. 웹 관리자 대시보드 (`web_admin/admin_dashboard.html`)

**사용자 행 생성 시 차단 상태 표시:**
```javascript
function createUserRow(index, userId, user) {
    const isBanned = user.banned === true;
    
    // 상태 표시
    const statusHTML = isBanned 
        ? '<span style="...">🚫 차단됨</span>'
        : '<span style="...">✅ 정상</span>';
    
    // 차단 버튼
    const banButtonHTML = isBanned
        ? `<button onclick="unbanUser('${userId}')">🔓 차단해제</button>`
        : `<button onclick="banUser('${userId}', '...')">🚫 차단</button>`;
    
    // ...
}
```

**사용자 차단 함수:**
```javascript
window.banUser = async (userId, nickname) => {
    // 확인 다이얼로그
    if (!confirm(`⚠️ 사용자 차단\n\n사용자: ${nickname}\n...`)) {
        return;
    }
    
    // 사용자 문서 업데이트
    await updateDoc(doc(db, 'users', userId), {
        banned: true,
        bannedAt: Timestamp.now(),
        bannedBy: window.currentUser.email,
        bannedQrCode: qrCodeUrl
    });
    
    // 차단 로그 기록
    await addDoc(collection(db, 'ban_logs'), {
        userId, nickname, qrCodeUrl,
        action: 'ban',
        timestamp: Timestamp.now(),
        adminEmail: window.currentUser.email
    });
    
    alert(`✅ ${nickname} 사용자가 차단되었습니다`);
    loadUsers();
};
```

**사용자 차단 해제 함수:**
```javascript
window.unbanUser = async (userId) => {
    // 사용자 문서 업데이트
    await updateDoc(doc(db, 'users', userId), {
        banned: false,
        unbannedAt: Timestamp.now(),
        unbannedBy: window.currentUser.email
    });
    
    // 차단 해제 로그 기록
    await addDoc(collection(db, 'ban_logs'), {
        userId, nickname: userData.nickname,
        action: 'unban',
        timestamp: Timestamp.now(),
        adminEmail: window.currentUser.email
    });
    
    alert(`✅ 차단이 해제되었습니다`);
    loadUsers();
};
```

#### 2. Flutter 모바일 앱 (`lib/services/securet_auth_service.dart`)

**로그인 시 차단 확인:**
```dart
// 사용자 찾기
final doc = querySnapshot.docs.first;
final userData = doc.data();
final isBanned = userData['banned'] == true;

// 차단 여부 확인
if (isBanned) {
    throw Exception('🚫 차단된 계정입니다\n\n관리자에 의해 차단되었습니다.\n...');
}

// 비밀번호 확인
if (storedPassword != password) {
    throw Exception('비밀번호가 일치하지 않습니다');
}
```

**회원가입 시 차단된 QR 코드 확인:**
```dart
// 차단된 QR 코드인지 확인
final bannedUsersSnapshot = await _firestore
    .collection('users')
    .where('bannedQrCode', isEqualTo: qrUrl)
    .limit(1)
    .get();

if (bannedUsersSnapshot.docs.isNotEmpty) {
    throw Exception('🚫 차단된 QR 코드입니다\n\n이 QR 코드로는 가입할 수 없습니다.\n...');
}

// 회원가입 진행
await _firestore.collection('users').doc(user.id).set({
    // ...기존 필드들
    'banned': false,  // 기본값
});
```

#### 3. 회원가입 화면 예외 처리 (`lib/screens/register_screen.dart`)

```dart
try {
    final success = await SecuretAuthService.registerWithSecuret(
        qrUrl, nickname, password
    );
    
    if (success) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen())
        );
    }
} catch (e) {
    setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
}
```

---

## 🚀 배포 가이드

### 1️⃣ 로컬에서 최신 코드 가져오기

```bash
cd C:\Users\sayto\qrchat
git pull origin main
```

**예상 출력:**
```
From https://github.com/Stevewon/qrchat
   a4453e8..3acf64b  main -> origin/main
Updating a4453e8..3acf64b
Fast-forward
 lib/screens/register_screen.dart      |  30 ++++--
 lib/services/securet_auth_service.dart|  46 +++++++--
 web_admin/admin_dashboard.html        | 106 +++++++++++++++++---
 3 files changed, 140 insertions(+), 14 deletions(-)
```

### 2️⃣ Firebase Hosting에 배포

```bash
firebase deploy --only hosting
```

**예상 출력:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/qrchat-b7a67/overview
Hosting URL: https://qrchat-b7a67.web.app
```

### 3️⃣ 브라우저 캐시 강제 삭제

- **방법 1:** Ctrl + Shift + R (강제 새로고침)
- **방법 2:** Ctrl + Shift + Delete → 캐시 삭제 → 전체 기간
- **방법 3:** 시크릿 모드 (Ctrl + Shift + N)로 테스트

### 4️⃣ Firestore 보안 규칙 업데이트 (선택사항)

Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 기본 규칙 (임시 - 추후 강화 필요)
    match /{document=**} {
      allow read, write: if true;
    }
    
    // ban_logs 컬렉션 (관리자만 쓰기 가능)
    match /ban_logs/{logId} {
      allow read: if true;
      allow write: if request.auth != null 
                   && request.auth.token.email == 'hbcu00987@gmail.com';
    }
  }
}
```

---

## ✅ 테스트 시나리오

### 시나리오 1: 정상 사용자 차단

1. ✅ 관리자 대시보드 접속 및 로그인
2. ✅ 👥 사용자 관리 메뉴 이동
3. ✅ 테스트 사용자 검색 (예: "바보바보")
4. ✅ 🚫 차단 버튼 클릭
5. ✅ 확인 다이얼로그에서 승인
6. ✅ 사용자 상태가 "🚫 차단됨"으로 변경 확인
7. ✅ 사용자 목록 새로고침하여 변경사항 확인

### 시나리오 2: 차단된 사용자 로그인 시도

1. ✅ 모바일 앱 열기
2. ✅ 차단된 사용자의 닉네임과 비밀번호 입력
3. ✅ 로그인 버튼 클릭
4. ✅ 오류 메시지 확인:
   ```
   🚫 차단된 계정입니다
   
   관리자에 의해 차단되었습니다.
   차단 해제 전까지 로그인할 수 없습니다.
   
   문의: 관리자에게 연락해주세요.
   ```

### 시나리오 3: 차단된 QR 코드로 재가입 시도

1. ✅ 모바일 앱에서 회원가입 화면으로 이동
2. ✅ 차단된 사용자의 QR 코드 스캔
3. ✅ 새로운 닉네임과 비밀번호 입력
4. ✅ 가입 버튼 클릭
5. ✅ 오류 메시지 확인:
   ```
   🚫 차단된 QR 코드입니다
   
   이 QR 코드로는 가입할 수 없습니다.
   차단된 계정의 QR 코드입니다.
   
   문의: 관리자에게 연락해주세요.
   ```

### 시나리오 4: 차단 해제 및 재로그인

1. ✅ 관리자 대시보드에서 차단된 사용자 찾기
2. ✅ 🔓 차단해제 버튼 클릭
3. ✅ 확인 후 차단 해제
4. ✅ 사용자 상태가 "✅ 정상"으로 변경 확인
5. ✅ 모바일 앱에서 동일 계정으로 로그인 시도
6. ✅ 정상적으로 로그인 성공 확인

### 시나리오 5: 차단 이력 확인

1. ✅ Firebase Console 접속
2. ✅ Firestore Database → `ban_logs` 컬렉션 이동
3. ✅ 최근 차단/해제 기록 확인:
   - userId
   - nickname
   - action (ban/unban)
   - timestamp
   - adminEmail

---

## 🔗 주요 링크

### 웹 애플리케이션
- **관리자 대시보드**: https://qrchat-b7a67.web.app/admin_dashboard.html
- **Firebase Hosting**: https://qrchat-b7a67.web.app

### Firebase Console
- **프로젝트 개요**: https://console.firebase.google.com/project/qrchat-b7a67/overview
- **Firestore Database**: https://console.firebase.google.com/project/qrchat-b7a67/firestore
- **users 컬렉션**: https://console.firebase.google.com/project/qrchat-b7a67/firestore/data/~2Fusers
- **ban_logs 컬렉션**: https://console.firebase.google.com/project/qrchat-b7a67/firestore/data/~2Fban_logs

### GitHub
- **저장소**: https://github.com/Stevewon/qrchat
- **최신 커밋**: https://github.com/Stevewon/qrchat/commit/3acf64b

---

## 📝 추가 참고사항

### ⚠️ 주의사항

1. **차단은 신중하게**: 차단 시 해당 사용자는 완전히 서비스 이용이 불가능합니다
2. **QR 코드 차단**: 차단 시 해당 QR 코드로는 영구적으로 재가입이 불가능합니다
3. **차단 이력**: 모든 차단/해제 기록이 `ban_logs`에 영구 보존됩니다

### 💡 활용 팁

1. **대량 차단 관리**: Firebase Console에서 직접 Firestore 쿼리로 여러 사용자 일괄 차단 가능
2. **차단 통계**: `ban_logs` 컬렉션을 분석하여 차단 통계 대시보드 구축 가능
3. **자동 차단**: Cloud Functions를 활용하여 특정 조건(예: 스팸 신고 3회 이상) 시 자동 차단 가능

### 🔮 향후 개선 계획

- [ ] 차단 사유 입력 필드 추가
- [ ] 임시 차단 (시간 제한) 기능
- [ ] 차단 통계 대시보드
- [ ] 차단 이력 조회 UI
- [ ] 자동 차단 규칙 설정
- [ ] 차단 알림 (이메일/푸시)

---

**문서 작성일**: 2026-02-13  
**문서 버전**: v1.0  
**관련 커밋**: [3acf64b](https://github.com/Stevewon/qrchat/commit/3acf64b)
