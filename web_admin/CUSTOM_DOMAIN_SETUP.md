# 🌐 qrchat.io 커스텀 도메인 설정 가이드

Firebase Hosting에 qrchat.io 도메인을 연결하는 방법입니다.

## 📋 설정 단계

### 1단계: Firebase Console에서 커스텀 도메인 추가

1. Firebase Console 열기:
   https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites

2. **커스텀 도메인** 클릭

3. **도메인 추가** 버튼 클릭

4. 도메인 입력:
   ```
   admin.qrchat.io
   ```
   (또는 원하는 서브도메인: dashboard.qrchat.io, manage.qrchat.io 등)

5. **계속** 클릭

---

### 2단계: DNS 레코드 설정

Firebase에서 제공하는 정보를 도메인 DNS 설정에 추가해야 합니다.

#### A 레코드 (권장)
Firebase가 제공하는 IP 주소로 A 레코드 추가:

```
Type: A
Name: admin (또는 @)
Value: Firebase가 제공하는 IP 주소 (예: 151.101.1.195, 151.101.65.195)
TTL: 3600
```

#### 또는 CNAME 레코드 (서브도메인용)
```
Type: CNAME
Name: admin
Value: qrchat-b7a67.web.app
TTL: 3600
```

---

### 3단계: 소유권 확인

Firebase가 TXT 레코드를 제공하면 DNS에 추가:

```
Type: TXT
Name: @ (또는 Firebase가 지정한 이름)
Value: Firebase가 제공하는 값 (예: firebase=qrchat-b7a67...)
TTL: 3600
```

---

### 4단계: SSL 인증서 자동 발급 대기

- Firebase가 자동으로 SSL 인증서 발급 (Let's Encrypt)
- 보통 24시간 이내 완료 (대부분 1-2시간)
- 상태: Firebase Console에서 확인 가능

---

## 🎯 추천 도메인 구조

### 옵션 1: 서브도메인 사용 (권장)
```
admin.qrchat.io     → 관리자 대시보드
app.qrchat.io       → 모바일 웹앱
api.qrchat.io       → API 서버
qrchat.io           → 메인 홈페이지
```

### 옵션 2: 메인 도메인 사용
```
qrchat.io           → 관리자 대시보드
```

---

## 📝 DNS 설정 예시 (전체)

### 관리자 대시보드를 admin.qrchat.io로 설정하는 경우:

```
Type    Name    Value                       TTL
────────────────────────────────────────────────
A       admin   151.101.1.195              3600
A       admin   151.101.65.195             3600
TXT     @       firebase=qrchat-b7a67...   3600
```

또는

```
Type    Name    Value                       TTL
────────────────────────────────────────────────
CNAME   admin   qrchat-b7a67.web.app       3600
TXT     @       firebase=qrchat-b7a67...   3600
```

---

## ✅ 확인 사항

배포 및 DNS 설정 완료 후:

1. **도메인 접속 테스트**
   ```
   https://admin.qrchat.io
   ```

2. **SSL 인증서 확인**
   - 브라우저 주소창의 자물쇠 아이콘 클릭
   - 인증서 정보 확인

3. **리다이렉트 테스트**
   - http:// → https:// 자동 리다이렉트 확인

---

## 🚀 빠른 배포 (Firebase CLI)

DNS 설정 후 배포:

```bash
# 1. 저장소 업데이트
cd /path/to/qrchat
git pull origin main

# 2. Firebase 로그인
firebase login

# 3. 배포
firebase deploy --only hosting

# 4. 커스텀 도메인 접속
# https://admin.qrchat.io
```

---

## 🔧 Firebase Console 링크

- **Hosting 설정**: https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
- **커스텀 도메인 관리**: https://console.firebase.google.com/project/qrchat-b7a67/hosting/main/site

---

## ⚠️ 주의사항

1. **DNS 전파 시간**
   - DNS 변경 후 전파까지 최대 48시간 소요 (보통 1-2시간)
   - `nslookup admin.qrchat.io`로 확인 가능

2. **SSL 인증서 발급**
   - Firebase가 자동으로 발급
   - 최대 24시간 소요 (보통 1-2시간)

3. **도메인 등록기관**
   - qrchat.io가 등록된 곳에서 DNS 설정
   - 예: Namecheap, GoDaddy, Cloudflare 등

---

## 📚 추가 자료

- [Firebase 커스텀 도메인 문서](https://firebase.google.com/docs/hosting/custom-domain)
- [DNS 설정 가이드](https://support.google.com/domains/answer/3290350)

---

**작성일**: 2026-02-13  
**버전**: QRChat v9.47.0
