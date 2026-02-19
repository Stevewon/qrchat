# 🔐 QRChat Desktop 코드 서명 가이드

## 📋 목차
- [왜 코드 서명이 필요한가?](#왜-코드-서명이-필요한가)
- [Windows 코드 서명](#windows-코드-서명)
- [macOS 코드 서명](#macos-코드-서명)
- [Linux 코드 서명](#linux-코드-서명)
- [비용 및 유지보수](#비용-및-유지보수)

---

## 왜 코드 서명이 필요한가?

### 사용자 신뢰 확보
- ✅ Windows Defender SmartScreen 경고 제거
- ✅ macOS Gatekeeper 경고 제거
- ✅ 다운로드 시 브라우저 경고 감소
- ✅ 기업 사용자의 보안 정책 통과

### 보안 강화
- ✅ 앱 무결성 보장
- ✅ 악의적 수정 방지
- ✅ 신원 확인 가능

### 비즈니스 가치
- ✅ 전문성 향상
- ✅ 사용자 전환율 증가
- ✅ 앱스토어 배포 가능

---

## Windows 코드 서명

### 1단계: 인증서 획득

#### 옵션 A: EV 코드 서명 인증서 (권장)
**장점:**
- 즉시 SmartScreen 신뢰
- 평판 점수 즉시 부여
- 온라인 검증 없이 설치 가능

**비용:** $300-500/년

**제공업체:**
- DigiCert
- Sectigo
- GlobalSign

**필요 서류:**
- 사업자 등록증 (법인/개인사업자)
- 대표자 신분증
- 주소 증명
- DUNS 번호 (선택)

#### 옵션 B: OV 코드 서명 인증서
**장점:**
- 저렴한 비용
- 기본 서명 가능

**단점:**
- SmartScreen 경고 (초기)
- 평판 쌓는데 시간 필요

**비용:** $100-200/년

### 2단계: 인증서 설치

#### Windows에서 설치
```powershell
# .pfx 파일을 받은 후
certmgr.msc  # 인증서 관리자 열기

# 또는 명령줄
certutil -importpfx certificate.pfx
```

#### 환경 변수 설정
```powershell
# GitHub Actions Secrets에 추가
CERTIFICATE_BASE64: (인증서를 Base64로 인코딩)
CERTIFICATE_PASSWORD: (인증서 비밀번호)
```

### 3단계: 서명 스크립트

#### signtool 사용
```powershell
# Windows SDK 설치 필요
# https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

# 서명 명령
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com /fd SHA256 /v qrchat.exe

# MSIX 패키지 서명
signtool sign /f certificate.pfx /p password /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 qrchat.msix
```

#### GitHub Actions 통합
```yaml
# .github/workflows/sign-windows.yml
name: Sign Windows Build

on:
  workflow_dispatch:
  push:
    tags:
      - 'v*'

jobs:
  sign:
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Certificate
        run: |
          echo "${{ secrets.CERTIFICATE_BASE64 }}" | base64 --decode > certificate.pfx
      
      - name: Sign Executable
        run: |
          & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
            /f certificate.pfx `
            /p "${{ secrets.CERTIFICATE_PASSWORD }}" `
            /t http://timestamp.digicert.com `
            /fd SHA256 `
            /v build/windows/x64/runner/Release/qrchat.exe
      
      - name: Sign MSIX
        run: |
          & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
            /f certificate.pfx `
            /p "${{ secrets.CERTIFICATE_PASSWORD }}" `
            /fd SHA256 `
            /tr http://timestamp.digicert.com `
            /td SHA256 `
            qrchat.msix
      
      - name: Cleanup
        run: Remove-Item certificate.pfx
```

### 4단계: SmartScreen 평판 구축

**시간이 필요한 이유:**
- Microsoft는 다운로드 횟수와 사용자 피드백을 수집
- 충분한 "평판"이 쌓이면 경고 제거

**가속 방법:**
- 많은 사용자에게 다운로드 유도
- 부정적 피드백 최소화
- 정기적으로 서명된 업데이트 배포

**예상 기간:** 1-3개월

---

## macOS 코드 서명

### 1단계: Apple Developer 프로그램 가입

**비용:** $99/년

**가입 방법:**
1. https://developer.apple.com 접속
2. Apple ID로 로그인
3. "Enroll" 클릭
4. 개인/법인 선택
5. 결제 ($99)

### 2단계: 개발자 인증서 생성

#### Xcode에서 생성
```bash
# Xcode 설치
xcode-select --install

# 인증서 요청
# Xcode > Preferences > Accounts > Manage Certificates > "+"
# "Developer ID Application" 선택
```

#### 명령줄에서 확인
```bash
# 설치된 인증서 확인
security find-identity -v -p codesigning

# 출력 예시:
# 1) XXXXXXXX "Developer ID Application: Your Name (TEAM_ID)"
```

### 3단계: 앱 서명

#### codesign 사용
```bash
# 앱 번들 서명
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements entitlements.plist \
  QRChat.app

# 확인
codesign --verify --verbose QRChat.app
spctl --assess --verbose QRChat.app
```

#### entitlements.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
</dict>
</plist>
```

### 4단계: Notarization (공증)

**필수 단계:** macOS 10.15+ 에서 실행하려면 필요

```bash
# 앱을 ZIP으로 압축
ditto -c -k --keepParent QRChat.app QRChat.zip

# Apple에 업로드
xcrun notarytool submit QRChat.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 상태 확인
xcrun notarytool info <submission-id> \
  --apple-id "your@email.com" \
  --password "app-specific-password"

# 공증 티켓 스테이플
xcrun stapler staple QRChat.app

# 확인
xcrun stapler validate QRChat.app
```

### 5단계: DMG 생성 및 서명

```bash
# DMG 생성
hdiutil create -volname "QRChat" -srcfolder QRChat.app -ov -format UDZO QRChat.dmg

# DMG 서명
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" QRChat.dmg

# 확인
codesign --verify --verbose QRChat.dmg
```

### GitHub Actions 통합
```yaml
# .github/workflows/sign-macos.yml
name: Sign macOS Build

on:
  push:
    tags:
      - 'v*'

jobs:
  sign:
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Import Certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.MACOS_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.MACOS_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          
          # Import certificate
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain
      
      - name: Sign App
        run: |
          codesign --deep --force --verify --verbose \
            --sign "Developer ID Application" \
            --options runtime \
            build/macos/Build/Products/Release/qrchat.app
      
      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: |
          ditto -c -k --keepParent build/macos/Build/Products/Release/qrchat.app qrchat.zip
          
          xcrun notarytool submit qrchat.zip \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APPLE_PASSWORD" \
            --wait
          
          xcrun stapler staple build/macos/Build/Products/Release/qrchat.app
```

---

## Linux 코드 서명

### GPG 서명 (권장)

#### 1단계: GPG 키 생성
```bash
# 키 생성
gpg --full-generate-key

# 선택:
# - RSA and RSA
# - 4096 bits
# - 유효기간: 1년
# - 이름, 이메일, 코멘트 입력

# 키 확인
gpg --list-keys
```

#### 2단계: 패키지 서명
```bash
# .deb 파일 서명
gpg --armor --detach-sign qrchat_2.0.0_amd64.deb

# 생성된 .asc 파일과 함께 배포
# qrchat_2.0.0_amd64.deb
# qrchat_2.0.0_amd64.deb.asc
```

#### 3단계: 검증 방법 제공
```bash
# 사용자가 검증하는 방법
# 1. 공개 키 가져오기
gpg --keyserver keyserver.ubuntu.com --recv-keys YOUR_KEY_ID

# 2. 서명 확인
gpg --verify qrchat_2.0.0_amd64.deb.asc qrchat_2.0.0_amd64.deb
```

#### 4단계: GitHub Actions
```yaml
# .github/workflows/sign-linux.yml
name: Sign Linux Build

on:
  push:
    tags:
      - 'v*'

jobs:
  sign:
    runs-on: ubuntu-latest
    steps:
      - name: Import GPG key
        env:
          GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
        run: |
          echo "$GPG_PRIVATE_KEY" | gpg --import
          echo "allow-preset-passphrase" >> ~/.gnupg/gpg-agent.conf
          gpg-connect-agent reloadagent /bye
      
      - name: Sign .deb
        run: |
          echo "${{ secrets.GPG_PASSPHRASE }}" | gpg --batch --yes --passphrase-fd 0 \
            --armor --detach-sign qrchat_2.0.0_amd64.deb
      
      - name: Sign AppImage
        run: |
          echo "${{ secrets.GPG_PASSPHRASE }}" | gpg --batch --yes --passphrase-fd 0 \
            --armor --detach-sign QRChat-2.0.0-linux-x86_64.AppImage
```

---

## 비용 및 유지보수

### 연간 비용 요약

| 플랫폼 | 인증서 타입 | 비용 | 갱신 주기 |
|--------|------------|------|----------|
| Windows | EV Code Signing | $300-500 | 1년 |
| Windows | OV Code Signing | $100-200 | 1년 |
| macOS | Apple Developer | $99 | 1년 |
| Linux | GPG (자체) | 무료 | - |
| **합계** | | **$399-599** | 1년 |

### 절약 팁
1. **OV 인증서로 시작** - 초기에는 저렴한 옵션
2. **번들 구매** - 여러 해 한번에 구매 시 할인
3. **GPG 먼저 사용** - Linux는 무료
4. **평판 쌓기** - SmartScreen 평판 확보 후 EV 고려

### 유지보수 작업

#### 갱신 체크리스트 (매년)
- [ ] 인증서 만료 30일 전 갱신
- [ ] 새 인증서로 CI/CD Secrets 업데이트
- [ ] 테스트 빌드로 서명 확인
- [ ] 문서 업데이트

#### 모니터링
```bash
# 인증서 만료일 확인 (Windows)
certutil -dump certificate.pfx | findstr "NotAfter"

# 인증서 만료일 확인 (macOS)
security find-certificate -c "Developer ID" -p | openssl x509 -text | grep "Not After"

# GPG 키 만료일 확인
gpg --list-keys
```

---

## 단계별 구현 플랜

### Phase 1: 무료 옵션 (즉시)
- [x] Linux GPG 서명
- [ ] 서명 검증 가이드 작성
- [ ] 사용자 교육

### Phase 2: macOS (1-2주)
- [ ] Apple Developer 가입 ($99)
- [ ] 인증서 설정
- [ ] 자동 서명 파이프라인
- [ ] Notarization 구현

### Phase 3: Windows (2-4주)
- [ ] OV 인증서 구매 ($100-200)
- [ ] 서명 파이프라인 구축
- [ ] SmartScreen 평판 모니터링

### Phase 4: Windows 업그레이드 (3-6개월)
- [ ] SmartScreen 평판 확인
- [ ] 필요시 EV 인증서로 업그레이드 ($300-500)

---

## 🎯 권장 사항

### 즉시 시작 (무료)
1. ✅ Linux GPG 서명 구현
2. ✅ 서명 검증 문서 작성
3. ✅ GitHub Actions에 통합

### 단기 (1개월, $99)
4. ⏳ Apple Developer 가입
5. ⏳ macOS 서명 및 공증
6. ⏳ DMG 서명 자동화

### 중기 (3개월, $100-200)
7. ⏳ Windows OV 인증서 구매
8. ⏳ MSIX 서명 자동화
9. ⏳ SmartScreen 평판 구축

### 장기 (6개월+, $300-500)
10. ⏳ Windows EV 인증서 고려
11. ⏳ 전문 보안 감사
12. ⏳ 인증서 관리 자동화

---

## 📚 추가 리소스

### 공식 문서
- [Microsoft Code Signing](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Apple Code Signing](https://developer.apple.com/support/code-signing/)
- [Electron Code Signing](https://www.electronjs.org/docs/latest/tutorial/code-signing)

### 인증서 발급 업체
- [DigiCert](https://www.digicert.com/signing/code-signing-certificates)
- [Sectigo](https://sectigo.com/ssl-certificates-tls/code-signing)
- [GlobalSign](https://www.globalsign.com/en/code-signing-certificate)

### 도구
- [signtool](https://docs.microsoft.com/en-us/windows/win32/seccrypto/signtool) - Windows
- [codesign](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/) - macOS
- [GPG](https://gnupg.org/) - Linux

---

**코드 서명은 신뢰의 시작입니다!** 🔐✨

사용자들이 안심하고 QRChat을 다운로드할 수 있도록 하세요!
