# 🪟 Windows 코드 서명 인증서 구매 가이드

## 🎯 추천: SSL.com OV Code Signing ($199/년)

---

## 📋 Step-by-Step 구매 가이드

### **Step 1: SSL.com 사이트 접속**

🔗 **구매 링크:** https://www.ssl.com/certificates/code-signing/

1. 위 링크 클릭
2. "Order Now" 버튼 클릭
3. **"eSigner Code Signing"** 선택 (클라우드 기반, 추천!)
   - 또는 **"Standard Code Signing"** (USB 토큰)

---

### **Step 2: 제품 선택**

| 제품 | 가격 | 추천도 | 특징 |
|------|------|--------|------|
| **eSigner EV Code Signing** | $299/년 | ⭐⭐⭐⭐⭐ | EV 인증서, 즉시 SmartScreen 우회 |
| **eSigner Code Signing** | $199/년 | ⭐⭐⭐⭐ | OV 인증서, 클라우드 기반 |
| Standard Code Signing | $199/년 | ⭐⭐⭐ | OV 인증서, USB 토큰 |

**추천:** **eSigner EV Code Signing** ($299)
- 이유: EV 인증서는 즉시 Windows SmartScreen 경고 제거!

---

### **Step 3: 계정 생성 및 정보 입력**

#### **개인 정보**
```
이름: [실명]
이메일: hocu00987@gmail.com
전화번호: [본인 휴대폰]
국가: South Korea (대한민국)
```

#### **조직 정보 (개인 개발자인 경우)**
```
조직명: QRChat (또는 개인 이름)
조직 유형: Individual / Sole Proprietor
주소: [실제 주소]
도시: [도시명]
우편번호: [우편번호]
```

---

### **Step 4: 검증 서류 준비**

#### **OV 인증서 필요 서류:**
1. **신분증** (필수)
   - 주민등록증 앞면 스캔
   - 또는 운전면허증
   - 또는 여권

2. **사업자 등록증** (사업자인 경우)
   - 개인 개발자는 필요 없음

3. **전화 인증** (필수)
   - SSL.com에서 전화 걸어옴
   - 본인 확인용

#### **EV 인증서 추가 필요 서류:**
1. 위의 OV 서류 전부
2. **주소 증명**
   - 공과금 고지서 (전기/수도/가스)
   - 또는 은행 명세서
3. **Dun & Bradstreet (D-U-N-S) 번호** (법인인 경우)

---

### **Step 5: CSR 생성 (이미 완료!)**

✅ **이미 생성됨!**
- 파일 위치: `/home/user/qrchat_desktop/qrchat.csr`
- 개인키: `/home/user/qrchat_desktop/qrchat_private.key`

**CSR 내용 확인:**
```bash
cat /home/user/qrchat_desktop/qrchat.csr
```

---

### **Step 6: 주문 완료 후 검증**

#### **1~3일 내 진행 사항:**

**Day 1:**
- ✅ 주문 확인 이메일 수신
- ✅ 검증 이메일 수신 (서류 업로드 링크)
- 📄 신분증 스캔 업로드
- 📞 전화번호 확인 대기

**Day 2:**
- 📞 SSL.com에서 전화 (본인 확인)
- ⏳ 서류 검토 중

**Day 3:**
- ✅ 인증서 발급 완료 이메일
- 📥 인증서 다운로드 (.pfx 파일)

---

### **Step 7: 인증서 다운로드 & 설치**

#### **발급 완료 후:**

1. **인증서 다운로드**
   - SSL.com 계정 로그인
   - "Download Certificate" 클릭
   - `qrchat_code_signing.pfx` 다운로드

2. **PFX 비밀번호 설정**
   - 예: `QRChat2026!Secure`
   - 안전한 곳에 메모!

3. **Windows에 설치**
   ```powershell
   # Windows에서 실행
   certutil -importPFX qrchat_code_signing.pfx
   ```

---

## 💰 **가격 비교**

| 제공업체 | OV 가격 | EV 가격 | 승인 시간 | 추천도 |
|----------|---------|---------|-----------|--------|
| **SSL.com** | $199 | $299 | 1~3일 | ⭐⭐⭐⭐⭐ |
| Sectigo | $224 | $474 | 2~5일 | ⭐⭐⭐⭐ |
| DigiCert | $474 | $649 | 1~3일 | ⭐⭐⭐ |
| GlobalSign | $249 | $599 | 3~7일 | ⭐⭐⭐ |

**최종 추천:** SSL.com eSigner EV ($299) - 가성비 최고!

---

## 🔐 **eSigner vs Standard 비교**

| 특징 | eSigner (클라우드) | Standard (USB 토큰) |
|------|-------------------|-------------------|
| 가격 | $199~$299 | $199 |
| 저장 위치 | 클라우드 (SSL.com 서버) | USB 토큰 (물리적) |
| 사용 편의성 | ⭐⭐⭐⭐⭐ (어디서든 사용) | ⭐⭐⭐ (USB 필요) |
| 보안 | ⭐⭐⭐⭐ (클라우드 암호화) | ⭐⭐⭐⭐⭐ (물리 분리) |
| CI/CD 통합 | ✅ 쉬움 | ❌ 어려움 |
| GitHub Actions | ✅ 가능 | ❌ 불가능 |
| 추천 | ✅ 개발자/팀 | ⭐ 개인 사용 |

**추천:** eSigner (클라우드 기반) - GitHub Actions 자동화 가능!

---

## 📞 **고객 지원**

### **SSL.com 지원:**
- 이메일: support@ssl.com
- 전화: +1-877-SSL-SECURE (+1-877-775-7328)
- 라이브챗: https://www.ssl.com (우측 하단)
- 응답 시간: 24시간 이내

### **한국 시간대 팁:**
- 미국 업무시간: 한국 시간 밤 11시~아침 8시
- 이메일 문의 추천 (빠른 응답)

---

## 🎯 **지금 바로 시작하기**

### **1단계: 사이트 접속**
🔗 https://www.ssl.com/certificates/code-signing/

### **2단계: 제품 선택**
- **추천:** eSigner EV Code Signing ($299)

### **3단계: 계정 생성**
- 이메일: hocu00987@gmail.com
- 비밀번호: (안전한 비밀번호 설정)

### **4단계: 서류 준비**
- 신분증 스캔 준비
- 전화 받을 준비

### **5단계: 구매 완료**
- 신용카드 결제
- 검증 이메일 대기

---

## ⏱️ **예상 타임라인**

```
Day 0 (오늘):
  09:00 - SSL.com 접속 및 주문
  09:30 - 주문 확인 이메일 수신
  10:00 - 검증 이메일 수신 (서류 업로드)
  10:30 - 신분증 스캔 업로드

Day 1:
  전화 인증 대기

Day 2:
  서류 검토 중

Day 3:
  ✅ 인증서 발급!
  📥 다운로드 및 테스트 서명

Day 4:
  🎉 QRChat Desktop v2.0.0 배포!
```

---

## ✅ **체크리스트**

- [ ] SSL.com 사이트 접속
- [ ] 계정 생성
- [ ] eSigner EV Code Signing 선택 ($299)
- [ ] 개인/조직 정보 입력
- [ ] 신용카드 결제
- [ ] 검증 이메일 확인
- [ ] 신분증 스캔 업로드
- [ ] 전화 인증 완료
- [ ] 인증서 다운로드
- [ ] 테스트 서명 실행

---

**생성일:** 2026-02-19  
**예상 완료일:** 2026-02-22 (3일 후)  
**총 비용:** $299 (EV) 또는 $199 (OV)  
**상태:** 📝 구매 준비 완료  
