# 🚀 Firebase Hosting 배포 가이드

QRChat 관리자 대시보드를 Firebase Hosting에 배포하는 방법입니다.

## 📋 목차
- [로컬에서 수동 배포](#로컬에서-수동-배포)
- [GitHub Actions 자동 배포](#github-actions-자동-배포)
- [배포 후 확인](#배포-후-확인)
- [문제 해결](#문제-해결)

---

## 🖥️ 로컬에서 수동 배포

### 1단계: 프로젝트 클론
```bash
git clone https://github.com/Stevewon/qrchat.git
cd qrchat
```

### 2단계: Firebase CLI 설치
```bash
npm install -g firebase-tools
```

### 3단계: Firebase 로그인
```bash
firebase login
```
- 브라우저가 열리면 Google 계정으로 로그인
- Firebase 프로젝트에 접근 권한이 있는 계정 사용

### 4단계: 배포
```bash
firebase deploy --only hosting
```

### 5단계: 배포 완료
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/qrchat-b7a67/overview
Hosting URL: https://qrchat-b7a67.web.app
```

---

## 🤖 GitHub Actions 자동 배포

### 1단계: Firebase 토큰 생성

로컬 환경에서 다음 명령어 실행:
```bash
firebase login:ci
```

출력된 토큰을 복사하세요:
```
✔  Success! Use this token to login on a CI server:

1//0gxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Example: firebase deploy --token "$FIREBASE_TOKEN"
```

### 2단계: GitHub Secrets 설정

1. GitHub 저장소로 이동: https://github.com/Stevewon/qrchat
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret** 클릭
4. 다음 정보 입력:
   - **Name**: `FIREBASE_TOKEN`
   - **Value**: 1단계에서 복사한 토큰
5. **Add secret** 클릭

### 3단계: 자동 배포 확인

이제 `web_admin/` 폴더의 파일을 수정하고 `main` 브랜치에 푸시하면 자동으로 배포됩니다:

```bash
git add .
git commit -m "Update admin dashboard"
git push origin main
```

GitHub Actions 탭에서 배포 진행 상황 확인:
https://github.com/Stevewon/qrchat/actions

---

## ✅ 배포 후 확인

### 1. 관리자 대시보드 접속
- 메인 URL: https://qrchat-b7a67.web.app
- 대체 URL: https://qrchat-b7a67.firebaseapp.com

### 2. Google 로그인 테스트
- **Google로 로그인** 버튼 클릭
- Firebase에 등록된 관리자 계정으로 로그인
- ✅ `auth/unauthorized-domain` 오류 없음 (자동으로 승인된 도메인)

### 3. 기능 테스트
- [ ] 대시보드 통계 정상 표시
- [ ] QKEY 출금 요청 목록 로드
- [ ] 탭 전환 (대기중, 승인됨, 완료됨, 거부됨)
- [ ] 출금 요청 승인 기능
- [ ] 출금 요청 거부 기능
- [ ] 지갑 주소 복사 기능
- [ ] 실시간 업데이트 확인

---

## 🔧 문제 해결

### 배포 오류: "Permission denied"
```bash
# 해결: Firebase에 다시 로그인
firebase logout
firebase login
```

### 배포 오류: "Project not found"
```bash
# 해결: 프로젝트 ID 확인
firebase use qrchat-b7a67
```

### Google 로그인 오류: "unauthorized-domain"
✅ Firebase Hosting을 사용하면 이 문제가 자동으로 해결됩니다!
- `qrchat-b7a67.web.app`
- `qrchat-b7a67.firebaseapp.com`

두 도메인 모두 Firebase에서 자동으로 승인됩니다.

### 출금 요청이 표시되지 않음
1. Firebase Console에서 Firestore 규칙 확인:
   https://console.firebase.google.com/project/qrchat-b7a67/firestore/rules

2. 관리자 이메일이 포함되어 있는지 확인:
```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    // QKEY 트랜잭션 관리자만 읽기/쓰기 가능
    match /qkey_transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        request.auth.token.email == 'admin@example.com';
    }
  }
}
```

3. 실제 관리자 이메일로 변경:
```javascript
request.auth.token.email == 'your-admin-email@gmail.com';
```

---

## 📚 추가 자료

- [Firebase Hosting 문서](https://firebase.google.com/docs/hosting)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [QRChat GitHub 저장소](https://github.com/Stevewon/qrchat)
- [Firebase Console](https://console.firebase.google.com/project/qrchat-b7a67)

---

## 🎯 다음 단계

배포 완료 후:
1. ✅ 관리자 대시보드 접속 확인
2. ✅ Google 로그인 성공 확인
3. ✅ QKEY 출금 관리 기능 테스트
4. 🚀 Phase 4 기능 개발 시작
   - 통계 대시보드 (일/주/월별)
   - 자동 승인 규칙
   - 푸시 알림
   - QKEY 마켓플레이스

---

**마지막 업데이트**: 2026-02-13  
**버전**: QRChat v9.47.0  
**작성자**: QRChat Development Team
