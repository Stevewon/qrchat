# 🌐 qrchat.io 도메인 연결 가이드

## 📋 현재 상태 분석

### ❌ 문제 발견
```
SSL: no alternative certificate subject name matches target host name 'www.qrchat.io'
```

**의미**: 
- 도메인은 존재하나 Firebase Hosting과 연결되지 않음
- SSL 인증서가 없거나 도메인 매핑이 안 됨

---

## ✅ 해결 방법: Firebase Hosting 커스텀 도메인 연결

### 1️⃣ **Firebase Console에서 도메인 추가**

1. Firebase Console 접속:
   ```
   https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
   ```

2. **"커스텀 도메인 추가"** 클릭

3. 도메인 입력: `qrchat.io` 또는 `www.qrchat.io`

4. **소유권 확인** (TXT 레코드 추가 필요)

---

### 2️⃣ **도메인 등록 업체에서 DNS 설정**

도메인을 어디서 구매하셨나요? (예: 가비아, 카페24, GoDaddy 등)

#### **A 레코드 설정 (권장)**

| 타입 | 호스트 | 값 |
|------|--------|-----|
| A | @ | `151.101.1.195` |
| A | @ | `151.101.65.195` |
| A | www | `151.101.1.195` |
| A | www | `151.101.65.195` |

#### **또는 CNAME 레코드 설정**

| 타입 | 호스트 | 값 |
|------|--------|-----|
| CNAME | www | `qrchat-b7a67.web.app` |

---

### 3️⃣ **Firebase에서 제공하는 DNS 레코드 확인**

Firebase Console에서 도메인 추가 시 표시되는 **정확한 IP 주소**를 사용해야 합니다!

1. Firebase Console → Hosting → 커스텀 도메인
2. 표시되는 A 레코드 IP 주소 확인
3. 도메인 등록 업체에 해당 IP 입력

---

### 4️⃣ **TXT 레코드 추가 (소유권 확인)**

Firebase가 제공하는 TXT 레코드를 도메인 DNS에 추가:

| 타입 | 호스트 | 값 |
|------|--------|-----|
| TXT | @ | `firebase=qrchat-b7a67` (예시) |

**실제 값은 Firebase Console에서 확인하세요!**

---

## ⏰ DNS 전파 대기 시간

DNS 변경 후 전파까지 **24~48시간** 소요 가능:
- 빠르면: 10분~1시간
- 평균: 2~6시간  
- 최대: 48시간

### DNS 전파 확인 방법

```bash
# Windows CMD
nslookup www.qrchat.io

# 또는 온라인 툴
https://dnschecker.org
```

---

## 🔧 단계별 설정 가이드

### **도메인 등록 업체별 가이드**

#### 📌 **가비아**
1. 가비아 로그인 → My가비아
2. 도메인 → DNS 관리
3. 레코드 추가:
   - 타입: A, 호스트: @, 값: Firebase IP
   - 타입: A, 호스트: www, 값: Firebase IP
4. 저장 후 1~2시간 대기

#### 📌 **카페24**
1. 카페24 로그인 → 나의 서비스 관리
2. 도메인 관리 → DNS 설정
3. A 레코드 추가
4. 저장

#### 📌 **후이즈 (Whois)**
1. 후이즈 로그인
2. 도메인 → 네임서버/부가서비스
3. DNS 레코드 관리
4. A 레코드 추가

#### 📌 **GoDaddy**
1. GoDaddy 로그인
2. My Products → Domains
3. DNS 클릭
4. Add Record → Type: A, Name: @, Value: Firebase IP

---

## 🎯 Firebase Hosting 커스텀 도메인 추가 절차

### **Step 1: Firebase Console 접속**
```
https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
```

### **Step 2: 커스텀 도메인 추가**
1. 사이트 이름: `qrchat-b7a67`
2. **"커스텀 도메인 추가"** 버튼 클릭
3. 도메인 입력: `www.qrchat.io`

### **Step 3: 소유권 확인**
Firebase가 제공하는 TXT 레코드를 도메인 DNS에 추가:
```
타입: TXT
호스트: @
값: firebase=qrchat-b7a67 (또는 Firebase가 제공하는 값)
```

### **Step 4: DNS 설정**
Firebase가 제공하는 A 레코드를 추가:
```
타입: A
호스트: @
값: [Firebase가 제공하는 IP 주소]

타입: A
호스트: www
값: [Firebase가 제공하는 IP 주소]
```

### **Step 5: SSL 인증서 자동 발급 대기**
- Firebase가 자동으로 SSL 인증서 발급
- 약 10분~24시간 소요
- 완료 시 HTTPS 자동 활성화

---

## ✅ 확인 방법

### **1. DNS 전파 확인**
https://dnschecker.org 에서 `www.qrchat.io` 검색

### **2. SSL 인증서 확인**
```bash
curl -I https://www.qrchat.io
```
또는 브라우저에서 자물쇠 아이콘 확인

### **3. Firebase Console에서 상태 확인**
Firebase Hosting → 커스텀 도메인 → 상태: "연결됨" 표시

---

## 📝 체크리스트

- [ ] Firebase Console에서 커스텀 도메인 추가
- [ ] Firebase가 제공하는 TXT 레코드 추가 (소유권 확인)
- [ ] Firebase가 제공하는 A 레코드 추가 (도메인 연결)
- [ ] DNS 전파 대기 (최대 48시간)
- [ ] Firebase에서 SSL 인증서 발급 확인
- [ ] https://www.qrchat.io 접속 테스트

---

## 🚨 문제 해결

### **문제 1: "DNS 레코드를 찾을 수 없습니다"**
- DNS 설정이 아직 전파 중
- 2~6시간 더 기다려 보세요

### **문제 2: "SSL 인증서 오류"**
- Firebase가 아직 SSL 인증서 발급 중
- Firebase Console에서 상태 확인
- 보통 24시간 이내 해결

### **문제 3: "페이지를 찾을 수 없습니다"**
- Firebase Hosting에 도메인이 추가되지 않음
- Firebase Console에서 다시 확인

---

## 📞 어디서 도메인을 구매하셨나요?

도메인 등록 업체를 알려주시면 **구체적인 DNS 설정 방법**을 안내해드리겠습니다!

- 가비아 (gabia.com)
- 카페24 (cafe24.com)
- 후이즈 (whois.co.kr)
- GoDaddy
- Namecheap
- 기타

---

## 🔗 참고 링크

- Firebase 커스텀 도메인 공식 가이드: https://firebase.google.com/docs/hosting/custom-domain
- Firebase Console: https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
- DNS Checker: https://dnschecker.org
