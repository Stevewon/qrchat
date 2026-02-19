# ✅ 인증서 구매 빠른 체크리스트

## 🚀 지금 바로 시작하세요!

### 📋 구매 전 준비 (5분)

```
✅ 준비 완료 여부 체크:

[ ] 신용카드 (Visa/Mastercard/Amex)
[ ] 이메일 주소 (stevewon@qrchat.io)
[ ] 전화번호 (+82-10-1234-5678)
[ ] 사업자 등록증 스캔본 (Windows용)
[ ] 신분증 스캔본 (Windows용)
```

---

## 🍎 Apple Developer 구매 (15분)

### Step 1: 신청 시작
```
🔗 https://developer.apple.com/programs/enroll/

1. [ ] "Start Your Enrollment" 클릭
2. [ ] Apple ID 로그인 (없으면 생성)
3. [ ] Entity Type: Individual 선택 ✅
4. [ ] 개인정보 입력
5. [ ] 약관 동의
```

### Step 2: 결제
```
💳 결제 정보:

카드 종류:    [ ] Visa  [ ] Mastercard  [ ] Amex
카드 번호:    ____-____-____-____
만료일:      __/__
CVV:        ___

금액: $99.00 USD (약 ₩130,000)

6. [ ] "Purchase" 버튼 클릭
7. [ ] 주문 번호 저장: _________________
```

### Step 3: 확인 대기
```
📧 이메일 확인:

8. [ ] "Verify your email" 이메일 받음
9. [ ] 인증 링크 클릭
10. [ ] 승인 대기 (1-2일)
11. [ ] "Welcome to Apple Developer" 이메일 받음
12. [ ] Team ID 확인: _________________
```

---

## 🪟 Windows 인증서 구매 (30분)

### Step 1: 사이트 선택
```
✅ 추천: Comodo SSL Store

🔗 https://comodosslstore.com/code-signing

1. [ ] "Sectigo Code Signing (OV)" 선택
2. [ ] Validity: 1 Year ($199)
3. [ ] "Add to Cart"
```

### Step 2: 계정 생성
```
📝 회원 정보:

Email:         _________________
Password:      _________________
Company Name:  _________________

4. [ ] 회원 가입 완료
```

### Step 3: 결제
```
💳 결제 정보:

카드 번호:    ____-____-____-____
만료일:      __/__
CVV:        ___

금액: $199-200 USD (약 ₩260,000)

5. [ ] "Complete Order" 클릭
6. [ ] 주문 번호 저장: _________________
```

### Step 4: CSR 생성
```bash
# 터미널에서 실행:
openssl req -new -newkey rsa:2048 -nodes \
  -keyout qrchat_private.key \
  -out qrchat.csr \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=QRChat Inc./OU=Development/CN=QRChat/emailAddress=stevewon@qrchat.io"

7. [ ] qrchat.csr 생성 완료
8. [ ] qrchat_private.key 안전 보관 ⚠️
```

### Step 5: CSR 제출
```
📤 CA 포털:

9. [ ] 이메일의 "Complete Your Order" 링크 클릭
10. [ ] CSR 내용 붙여넣기
11. [ ] 회사 정보 입력:
    Company Name:    _________________
    Address:         _________________
    Phone:          _________________
    Email:          _________________
```

### Step 6: 서류 업로드
```
📄 필수 서류:

12. [ ] 사업자 등록증 업로드 (PDF/JPG)
13. [ ] 신분증 앞뒷면 업로드 (PDF/JPG)
14. [ ] Authorization Letter 다운로드 → 서명 → 업로드
15. [ ] "Submit Documents" 클릭
```

### Step 7: 전화 확인
```
📞 전화 받기 (1-2일 내):

16. [ ] Sectigo에서 전화 받음
17. [ ] 신원 확인 질문 답변
18. [ ] 전화 확인 완료
```

### Step 8: 인증서 다운로드
```
✅ 발급 완료 (1-3일 후):

19. [ ] "Certificate Ready" 이메일 받음
20. [ ] qrchat.cer 다운로드
21. [ ] sectigo_intermediate.cer 다운로드
```

### Step 9: PFX 생성
```bash
# 터미널에서 실행:
openssl pkcs12 -export \
  -out qrchat.pfx \
  -inkey qrchat_private.key \
  -in qrchat.cer \
  -certfile sectigo_intermediate.cer

22. [ ] PFX 비밀번호 설정: _________________
23. [ ] qrchat.pfx 생성 완료
24. [ ] 비밀번호 안전 보관 ⚠️
```

---

## 🐧 Linux GPG 서명 (5분, 즉시!)

### 바로 실행!
```bash
cd /home/user/qrchat_desktop
./sign_linux.sh

25. [ ] 스크립트 실행 완료
26. [ ] GPG 키 자동 생성
27. [ ] .deb 패키지 생성
28. [ ] AppImage 생성
29. [ ] 서명 완료!
```

---

## 🎯 완료 후 테스트

### macOS 테스트 (Apple 승인 후)
```bash
export APPLE_ID="stevewon@qrchat.io"
export APPLE_TEAM_ID="ABC123DEF4"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./sign_macos.sh

30. [ ] macOS 서명 테스트 성공
```

### Windows 테스트 (인증서 발급 후)
```batch
set PFX_FILE=qrchat.pfx
set PFX_PASSWORD=your_password
sign_windows.bat

31. [ ] Windows 서명 테스트 성공
```

### Linux 테스트 (즉시 가능)
```bash
./sign_linux.sh

32. [ ] Linux 서명 테스트 성공
```

---

## 📊 진행 상황 추적

```
날짜별 체크:

Day 0 (오늘):
[ ] Apple Developer 신청 완료
[ ] Windows 인증서 신청 완료
[ ] Linux 서명 완료 ✅

Day 1-2:
[ ] Apple 이메일 인증 완료
[ ] Windows 서류 검토 중

Day 2-3:
[ ] Windows 전화 확인 완료

Day 3:
[ ] Apple Developer 승인 완료
[ ] Windows 인증서 발급 완료

Day 4:
[ ] macOS 서명 테스트 완료
[ ] Windows 서명 테스트 완료
[ ] ✅ 모든 플랫폼 준비 완료!

Day 5:
[ ] v2.0.0 정식 출시! 🚀
```

---

## 💰 총 비용 확인

```
✅ 결제 완료 여부:

[ ] Apple Developer     $99    날짜: __________
[ ] Windows 인증서      $200   날짜: __________
[ ] Linux GPG          무료   완료: ✅

총 비용: $299 / 1년
```

---

## 📞 연락처 정보

### Apple Developer 문제
```
🌐 https://developer.apple.com/contact/
📧 developer@apple.com
⏰ 응답 시간: 1-2 영업일
```

### Sectigo 문제
```
📧 support@comodoca.com
📧 enterprise-support@sectigo.com
📞 +1-888-266-6361 (영어)
⏰ 응답 시간: 24시간
```

---

## 🎉 완료!

모든 체크박스에 ✅ 표시가 되면:

```
🎊 축하합니다! 🎊

✅ Apple Developer 활성화
✅ Windows 인증서 발급
✅ Linux GPG 서명 준비
✅ 모든 플랫폼 코드 서명 가능!

→ 이제 v2.0.0 정식 출시하세요! 🚀
```

---

## 📝 메모

```
개인 메모 공간:

Apple Team ID:
_____________________________________

Windows PFX Password:
_____________________________________

중요한 날짜:
- Apple 승인일: ___________
- Windows 발급일: ___________
- 인증서 만료일: ___________

기타:
_____________________________________
_____________________________________
_____________________________________
```

---

**지금 바로 시작하세요!** ⏰

1. ✅ 이 체크리스트 프린트 또는 저장
2. 🔗 Apple Developer 사이트 열기
3. 🔗 Comodo SSL Store 사이트 열기
4. ▶️ 단계별로 진행!

**화이팅!** 💪🚀
