# 🌐 가비아 DNS 설정 가이드 (qrchat.io → Firebase Hosting)

## 📋 단계별 설정 방법

### 1️⃣ **Firebase Console에서 커스텀 도메인 추가**

먼저 Firebase에서 도메인을 추가하고 DNS 레코드 정보를 받아야 합니다!

#### **Step 1: Firebase Console 접속**
```
https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
```

#### **Step 2: 커스텀 도메인 추가**
1. 페이지 중간의 **"커스텀 도메인 추가"** 버튼 클릭
2. 도메인 입력: `www.qrchat.io`
3. **"계속"** 클릭

#### **Step 3: DNS 레코드 정보 확인**
Firebase가 아래와 같은 정보를 제공합니다:

**TXT 레코드** (소유권 확인용):
```
타입: TXT
호스트/이름: @ (또는 공백)
값/데이터: (Firebase가 제공하는 긴 문자열)
예: firebase=qrchat-b7a67...
```

**A 레코드** (실제 연결용):
```
타입: A
호스트/이름: www
값/데이터: (Firebase가 제공하는 IP 주소)
예: 151.101.1.195, 151.101.65.195
```

> ⚠️ **중요**: Firebase Console에 표시되는 **정확한 값**을 복사하세요!

---

### 2️⃣ **가비아 DNS 관리 페이지 접속**

#### **Step 1: 가비아 로그인**
```
https://www.gabia.com
```
→ 우측 상단 **"로그인"** 클릭

#### **Step 2: My가비아 접속**
로그인 후 우측 상단 **"My가비아"** 클릭

#### **Step 3: 도메인 관리**
1. 왼쪽 메뉴에서 **"서비스 관리"** → **"도메인"** 클릭
2. `qrchat.io` 도메인 찾기
3. **"관리"** 또는 **"설정"** 버튼 클릭

#### **Step 4: DNS 정보 관리**
1. **"DNS 관리"** 또는 **"DNS 정보"** 탭 클릭
2. **"DNS 설정"** 버튼 클릭

---

### 3️⃣ **가비아 DNS 레코드 추가**

#### **① TXT 레코드 추가 (소유권 확인)**

1. **"레코드 추가"** 또는 **"+ 추가"** 버튼 클릭

2. **레코드 정보 입력**:
   ```
   타입(Type): TXT
   호스트(Host): @ (또는 공백으로 둠)
   값(Value): Firebase가 제공한 TXT 값 복사
   예: firebase=qrchat-b7a67
   TTL: 3600 (기본값 유지)
   ```

3. **"저장"** 또는 **"확인"** 클릭

#### **② A 레코드 추가 (www 서브도메인)**

1. **"레코드 추가"** 버튼 다시 클릭

2. **첫 번째 A 레코드**:
   ```
   타입(Type): A
   호스트(Host): www
   값(Value): [Firebase가 제공한 첫 번째 IP]
   예: 151.101.1.195
   TTL: 3600
   ```

3. **"저장"** 클릭

4. **"레코드 추가"** 버튼 다시 클릭

5. **두 번째 A 레코드**:
   ```
   타입(Type): A
   호스트(Host): www
   값(Value): [Firebase가 제공한 두 번째 IP]
   예: 151.101.65.195
   TTL: 3600
   ```

6. **"저장"** 클릭

#### **③ A 레코드 추가 (루트 도메인 - 선택사항)**

`qrchat.io` (www 없이) 접속도 원하시면:

1. **"레코드 추가"** 클릭

2. **A 레코드**:
   ```
   타입(Type): A
   호스트(Host): @ (또는 공백)
   값(Value): [Firebase IP 첫 번째]
   TTL: 3600
   ```

3. 위 과정 반복하여 두 번째 IP도 추가

---

### 4️⃣ **가비아 DNS 설정 최종 확인**

설정 후 DNS 레코드 목록이 아래와 같아야 합니다:

| 타입 | 호스트 | 값/데이터 | TTL |
|------|--------|-----------|-----|
| TXT | @ | firebase=qrchat-b7a67... | 3600 |
| A | www | 151.101.1.195 | 3600 |
| A | www | 151.101.65.195 | 3600 |
| A | @ | 151.101.1.195 | 3600 |
| A | @ | 151.101.65.195 | 3600 |

> ⚠️ IP 주소는 Firebase Console에서 제공한 **정확한 값** 사용!

---

### 5️⃣ **Firebase Console에서 DNS 확인**

1. Firebase Console로 돌아가기
2. **"확인"** 또는 **"DNS 확인"** 버튼 클릭
3. Firebase가 DNS 레코드 확인 시작

---

## ⏰ **대기 시간**

### **TXT 레코드 전파**
- 소요 시간: 10분~2시간
- Firebase가 소유권 확인 완료

### **A 레코드 전파**
- 소요 시간: 1~6시간
- 도메인 연결 완료

### **SSL 인증서 발급**
- 소요 시간: 자동 발급 (최대 24시간)
- Firebase가 Let's Encrypt SSL 자동 발급

---

## ✅ **확인 방법**

### **1. DNS 전파 확인**

**방법 1: 온라인 툴**
```
https://dnschecker.org
```
→ `www.qrchat.io` 입력 → "Search" 클릭

**방법 2: Windows CMD**
```cmd
nslookup www.qrchat.io
```

**방법 3: 가비아에서 확인**
- My가비아 → 도메인 → DNS 관리
- 추가한 레코드가 보이는지 확인

### **2. Firebase Console 상태 확인**
```
https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
```
→ 커스텀 도메인 상태:
- ⏳ **"확인 중"**: DNS 전파 대기 중
- ✅ **"연결됨"**: 설정 완료!

### **3. 브라우저 접속 테스트**
```
https://www.qrchat.io
```
→ QRChat 관리자 대시보드가 보이면 성공! 🎉

---

## 🚨 **문제 해결**

### **문제 1: "DNS 레코드를 찾을 수 없습니다"**

**원인**: DNS 설정이 아직 전파되지 않음

**해결**:
- 2~6시간 더 기다리기
- 가비아 DNS 설정 다시 확인
- TTL 값이 3600 이하인지 확인

### **문제 2: "소유권을 확인할 수 없습니다"**

**원인**: TXT 레코드가 잘못되었거나 전파 안 됨

**해결**:
1. 가비아 DNS 관리에서 TXT 레코드 확인
2. Firebase Console에 표시된 값과 정확히 일치하는지 확인
3. 호스트가 `@` 또는 공백인지 확인
4. 20~30분 후 다시 시도

### **문제 3: "SSL 인증서 오류"**

**원인**: Firebase가 아직 SSL 발급 중

**해결**:
- Firebase Console에서 "연결됨" 상태 확인
- 최대 24시간 대기
- HTTPS 자동 활성화됨

### **문제 4: "qrchat.io는 되는데 www.qrchat.io는 안 됨"**

**원인**: A 레코드를 루트(@)에만 추가하고 www에 추가 안 함

**해결**:
- 가비아에서 `www` 호스트로 A 레코드 추가
- Firebase Console에서 `www.qrchat.io`도 별도로 추가

---

## 📸 **가비아 DNS 설정 화면 예시**

### **DNS 관리 메뉴 경로**
```
My가비아 → 서비스 관리 → 도메인 → qrchat.io → DNS 관리 → DNS 설정
```

### **레코드 추가 화면**
```
┌─────────────────────────────────────┐
│  타입: [TXT ▼]                      │
│  호스트: [@        ]                │
│  값: [firebase=qrchat-b7a67...    ] │
│  TTL: [3600      ]                  │
│                                     │
│  [취소]  [저장]                     │
└─────────────────────────────────────┘
```

---

## 📝 **체크리스트**

### **Firebase Console**
- [ ] https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites 접속
- [ ] "커스텀 도메인 추가" 클릭
- [ ] `www.qrchat.io` 입력
- [ ] TXT 레코드 값 복사
- [ ] A 레코드 IP 주소 복사

### **가비아 DNS 설정**
- [ ] 가비아 로그인 → My가비아
- [ ] 도메인 관리 → qrchat.io → DNS 관리
- [ ] TXT 레코드 추가 (호스트: @, 값: Firebase 제공)
- [ ] A 레코드 추가 #1 (호스트: www, 값: Firebase IP 1)
- [ ] A 레코드 추가 #2 (호스트: www, 값: Firebase IP 2)
- [ ] 설정 저장

### **확인**
- [ ] DNS 전파 확인 (https://dnschecker.org)
- [ ] Firebase Console 상태: "연결됨"
- [ ] https://www.qrchat.io 접속 테스트

---

## 🔗 **참고 링크**

- **가비아**: https://www.gabia.com
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67/hosting/sites
- **DNS Checker**: https://dnschecker.org
- **가비아 고객센터**: 1544-4755

---

## 💡 **중요 팁**

1. **Firebase Console을 먼저 열어두세요!**
   - DNS 레코드 값을 복사하기 위해

2. **TXT 레코드부터 추가하세요!**
   - 소유권 확인이 먼저 필요

3. **DNS 전파는 시간이 걸립니다!**
   - 빠르면 10분, 보통 2~6시간

4. **가비아는 비교적 빠른 편입니다!**
   - 평균 1~2시간이면 전파 완료

---

## 🎉 **설정 완료 후**

모든 설정이 완료되면:

1. ✅ `https://www.qrchat.io` → QRChat 관리자 대시보드
2. ✅ `https://qrchat.io` → 자동으로 www로 리다이렉트 (선택사항)
3. ✅ SSL 인증서 자동 발급 (🔒 자물쇠 아이콘)

---

**설정 중 문제가 있으면 알려주세요!** 😊
