# 🪟 Windows 코드 서명 - 실행 가이드

## 📋 개요
**비용**: $200-500/년  
**예상 시간**: 3-7일  
**난이도**: 고급  

---

## 💡 인증서 종류

### OV (Organization Validation) - $200/년
- ✅ 기업 정보 확인
- ✅ SmartScreen 필터 해제 (몇 주 후)
- ✅ 비교적 저렴
- ❌ SmartScreen 초기 경고
- ❌ 사업자 등록증 필요

**추천**: 중소 기업, 스타트업

### EV (Extended Validation) - $400-500/년
- ✅ 엄격한 검증
- ✅ SmartScreen 경고 **즉시** 해제
- ✅ 최고 신뢰도
- ✅ 하드웨어 토큰 제공
- ❌ 비싼 가격
- ❌ 복잡한 검증 절차

**추천**: 대기업, 고보안 앱

---

## ✅ 사전 준비사항

### 필수 문서 (OV 기준)
- [ ] 사업자 등록증 (법인/개인사업자)
- [ ] 대표자 신분증
- [ ] 사업장 전화번호 (검증용)
- [ ] 회사 이메일 주소
- [ ] DUNS 번호 (선택, 있으면 빠름)

### 필수 문서 (EV 기준)
- [ ] 법인 등기부등본
- [ ] 사업자 등록증
- [ ] 대표자 신분증 + 재직증명서
- [ ] 사업장 주소 증명 (공과금 청구서)
- [ ] 은행 계좌 증명
- [ ] DUNS 번호 (거의 필수)

### 기술 요구사항
- [ ] Windows 10/11 (서명용)
- [ ] USB 포트 (EV용 하드웨어 토큰)
- [ ] 인터넷 연결

---

## 🏪 인증서 구매

### 추천 CA (Certificate Authority)

#### 1. **Sectigo (구 Comodo)** - 가장 인기
**OV**: $200/년  
**EV**: $400/년  
**특징**:
- 빠른 발급 (OV 1-3일, EV 3-7일)
- 좋은 평판
- Microsoft SmartScreen 신뢰
- 재판매업체 많음

**구매처**: https://comodosslstore.com

#### 2. **DigiCert**
**OV**: $300/년  
**EV**: $500/년  
**특징**:
- 최고 품질
- 빠른 발급
- 우수한 지원
- 비싼 가격

**구매처**: https://www.digicert.com

#### 3. **GlobalSign**
**OV**: $250/년  
**EV**: $450/년  
**특징**:
- 중간 가격
- 좋은 품질
- 국제적으로 인정

**구매처**: https://www.globalsign.com

### 💰 비용 비교표

| CA | OV | EV | 발급 시간 | 추천도 |
|---|---|---|---|---|
| Sectigo | $200 | $400 | 1-7일 | ⭐⭐⭐⭐⭐ |
| DigiCert | $300 | $500 | 1-5일 | ⭐⭐⭐⭐ |
| GlobalSign | $250 | $450 | 2-7일 | ⭐⭐⭐⭐ |

**권장**: 처음이면 **Sectigo OV ($200)**

---

## 📝 단계별 가이드 (Sectigo OV 기준)

### Step 1: 인증서 신청

#### 1-1. 구매 사이트 접속
```
https://comodosslstore.com/code-signing
또는
https://store.sectigo.com/
```

#### 1-2. 인증서 선택
- "Sectigo Code Signing Certificate (OV)" 선택
- 1년 선택 (최소 $199)
- 장바구니 추가

#### 1-3. 결제
- 신용카드 또는 PayPal
- 주문 번호 저장

#### 1-4. 이메일 확인
- 주문 확인 이메일
- 인증서 신청 링크

---

### Step 2: CSR (Certificate Signing Request) 생성

#### 2-1. Windows에서 CSR 생성

**방법 1: 인증서 관리자 (권장)**

```powershell
# PowerShell을 관리자 권한으로 실행

# 1. certmgr.msc 실행
certmgr.msc

# 2. Personal > Certificates 우클릭 > All Tasks > Advanced Operations > Create Custom Request

# 3. 설정:
# - Template: (No template) Legacy key
# - Request Format: PKCS #10
# - Key: RSA, 2048 bits
# - Hash Algorithm: SHA256
```

**방법 2: OpenSSL (크로스 플랫폼)**

```bash
# OpenSSL 설치 (Windows)
# https://slproweb.com/products/Win32OpenSSL.html

# CSR 생성
openssl req -new -newkey rsa:2048 -nodes -out qrchat.csr -keyout qrchat.key -subj "/C=KR/ST=Seoul/L=Seoul/O=QRChat/OU=Development/CN=QRChat/emailAddress=your@email.com"

# 파일 생성:
# - qrchat.csr (인증서 요청서, CA에 제출)
# - qrchat.key (개인 키, 안전하게 보관!)
```

**⚠️ 중요**: `qrchat.key` 파일을 절대 공유하지 마세요!

#### 2-2. CSR 내용 복사
```bash
cat qrchat.csr

# 출력:
# -----BEGIN CERTIFICATE REQUEST-----
# MIICvDCCAaQCAQAwdzELMAkGA1UEBhMCS1IxDjAMBgNVBAgMBVNlb3VsMQ4wDAYD
# ...
# -----END CERTIFICATE REQUEST-----
```

전체 내용 복사 (BEGIN부터 END까지)

---

### Step 3: 인증 서류 제출

#### 3-1. CA 포털 로그인
- 이메일로 받은 링크 클릭
- 계정 생성

#### 3-2. CSR 업로드
- "Certificate Signing Request" 필드에 CSR 붙여넣기

#### 3-3. 회사 정보 입력
```
회사명: QRChat Inc. (또는 개인사업자명)
주소: 서울시 강남구 ...
전화번호: +82-2-1234-5678 (사업장 전화)
이메일: admin@qrchat.io (회사 도메인)
DUNS 번호: (있으면 입력)
```

#### 3-4. 서류 업로드
**필수 서류:**
1. **사업자 등록증**
   - PDF 또는 JPG
   - 선명하게 스캔
   - 최근 3개월 이내

2. **대표자 신분증**
   - 주민등록증 또는 여권
   - 양면 스캔

3. **전화 확인 동의서** (CA가 제공)
   - 다운로드 > 서명 > 스캔 > 업로드

#### 3-5. 검증 대기
- **전화 확인**: CA가 사업장으로 전화 (영어 가능 직원 필요)
- **이메일 확인**: 회사 도메인 이메일로 인증 링크
- **서류 검토**: 1-3일 소요

**Tip**: 전화 확인 빠르게 받으려면
- 영어 가능한 직원 대기
- "Yes, I confirm this certificate request" 답변
- 신청자 이름 및 회사명 확인

---

### Step 4: 인증서 발급 및 설치

#### 4-1. 인증서 다운로드
- 승인 이메일 받음 (보통 1-3일 후)
- 인증서 파일 다운로드 (`.cer` 또는 `.crt`)

#### 4-2. 인증서를 PFX로 변환

**Windows (certmgr):**
```
1. certmgr.msc 실행
2. Personal > Certificates 우클릭
3. All Tasks > Import
4. 다운로드한 .cer 파일 선택
5. 자동으로 개인 키와 매칭
6. 인증서 우클릭 > All Tasks > Export
7. "Yes, export the private key" 선택
8. PKCS #12 (.PFX) 형식
9. 강력한 비밀번호 설정
10. qrchat.pfx 저장
```

**OpenSSL:**
```bash
# .cer와 .key를 .pfx로 합치기
openssl pkcs12 -export -out qrchat.pfx \
  -inkey qrchat.key \
  -in qrchat.cer \
  -certfile sectigo_intermediate.crt

# 비밀번호 입력 (기억하세요!)
```

**⚠️ 중요**: `qrchat.pfx`와 비밀번호를 안전하게 보관!

#### 4-3. 인증서 설치 확인
```powershell
# PowerShell
Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

# 출력:
# Thumbprint                                Subject
# ----------                                -------
# 1234567890ABCDEF...                       CN=QRChat, O=QRChat Inc., ...
```

---

### Step 5: 앱 서명

#### 5-1. SignTool 설치
```powershell
# Visual Studio Build Tools 설치 (무료)
# https://visualstudio.microsoft.com/downloads/

# 또는 Windows SDK만 설치
# https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

# signtool.exe 경로 (보통):
# C:\Program Files (x86)\Windows Kits\10\bin\<version>\x64\signtool.exe
```

#### 5-2. 서명 스크립트 생성
```bash
cd /home/user/qrchat_desktop

cat > sign_windows.sh << 'EOF'
#!/bin/bash

# 설정
PFX_FILE="qrchat.pfx"
PFX_PASSWORD="your_password_here"
APP_PATH="build/windows/x64/runner/Release/qrchat.exe"
TIMESTAMP_URL="http://timestamp.sectigo.com"

echo "🔐 Signing Windows executable..."

# Windows에서 실행 (WSL에서 Windows 명령 호출)
# 또는 Windows PowerShell에서 직접 실행

# signtool sign 명령
signtool.exe sign \
  /f "$PFX_FILE" \
  /p "$PFX_PASSWORD" \
  /tr "$TIMESTAMP_URL" \
  /td SHA256 \
  /fd SHA256 \
  /v \
  "$APP_PATH"

# 서명 확인
echo "✅ Verifying signature..."
signtool.exe verify /pa /v "$APP_PATH"

echo "✅ Windows app signed successfully!"
EOF

chmod +x sign_windows.sh
```

#### 5-3. Windows에서 서명 (PowerShell)
```powershell
# PowerShell 스크립트
$pfxPath = "qrchat.pfx"
$password = "your_password_here"
$appPath = "build\windows\x64\runner\Release\qrchat.exe"
$timestampUrl = "http://timestamp.sectigo.com"

# signtool 경로 설정
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"

# 서명
& $signtool sign `
  /f $pfxPath `
  /p $password `
  /tr $timestampUrl `
  /td SHA256 `
  /fd SHA256 `
  /v `
  $appPath

# 확인
& $signtool verify /pa /v $appPath
```

#### 5-4. 실행
```bash
# Flutter 빌드
flutter build windows --release

# 서명 실행
./sign_windows.sh  # Linux/macOS에서 준비
# 또는
.\sign_windows.ps1  # Windows에서 직접 실행
```

---

### Step 6: 설치 프로그램 서명

#### 6-1. NSIS 설치
```
https://nsis.sourceforge.io/Download
```

#### 6-2. 설치 스크립트 생성
```nsis
; qrchat_installer.nsi

!define APP_NAME "QRChat"
!define APP_VERSION "2.0.0"
!define APP_PUBLISHER "QRChat Inc."
!define APP_URL "https://qrchat.io"
!define APP_EXE "qrchat.exe"

Name "${APP_NAME}"
OutFile "QRChat-${APP_VERSION}-Setup.exe"
InstallDir "$PROGRAMFILES64\${APP_NAME}"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "build\windows\x64\runner\Release\*.*"
  
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
    "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
    "UninstallString" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\*.*"
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\${APP_NAME}\*.*"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd
```

#### 6-3. 설치 프로그램 빌드 및 서명
```powershell
# NSIS 컴파일
makensis qrchat_installer.nsi

# 서명
signtool.exe sign `
  /f qrchat.pfx `
  /p "your_password" `
  /tr "http://timestamp.sectigo.com" `
  /td SHA256 `
  /fd SHA256 `
  /d "QRChat Installer" `
  /v `
  QRChat-2.0.0-Setup.exe

# 확인
signtool.exe verify /pa /v QRChat-2.0.0-Setup.exe
```

---

### Step 7: GitHub Actions 통합

#### 7-1. GitHub Secrets 설정
```
GitHub Repository > Settings > Secrets and Variables > Actions
```

**추가할 Secrets:**
1. `WINDOWS_PFX_BASE64`
   ```powershell
   # PowerShell에서 Base64 인코딩
   $bytes = [System.IO.File]::ReadAllBytes("qrchat.pfx")
   $base64 = [Convert]::ToBase64String($bytes)
   $base64 | Set-Clipboard
   ```

2. `WINDOWS_PFX_PASSWORD`
   - PFX 파일 비밀번호

#### 7-2. Workflow 파일
```yaml
# .github/workflows/sign-windows.yml
name: Sign Windows Build

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  sign-windows:
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.1'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build Windows
        run: flutter build windows --release
      
      - name: Import Certificate
        env:
          PFX_BASE64: ${{ secrets.WINDOWS_PFX_BASE64 }}
          PFX_PASSWORD: ${{ secrets.WINDOWS_PFX_PASSWORD }}
        shell: powershell
        run: |
          # Decode certificate
          $pfxBytes = [Convert]::FromBase64String($env:PFX_BASE64)
          [IO.File]::WriteAllBytes("qrchat.pfx", $pfxBytes)
          
          # Import to certificate store (optional)
          $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
          $cert.Import("qrchat.pfx", $env:PFX_PASSWORD, "Exportable,PersistKeySet")
          
          Write-Host "✅ Certificate imported"
      
      - name: Sign Executable
        env:
          PFX_PASSWORD: ${{ secrets.WINDOWS_PFX_PASSWORD }}
        shell: powershell
        run: |
          $signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
          
          & $signtool sign `
            /f "qrchat.pfx" `
            /p $env:PFX_PASSWORD `
            /tr "http://timestamp.sectigo.com" `
            /td SHA256 `
            /fd SHA256 `
            /v `
            "build\windows\x64\runner\Release\qrchat.exe"
          
          & $signtool verify /pa /v "build\windows\x64\runner\Release\qrchat.exe"
      
      - name: Create Installer
        run: |
          choco install nsis -y
          makensis qrchat_installer.nsi
      
      - name: Sign Installer
        env:
          PFX_PASSWORD: ${{ secrets.WINDOWS_PFX_PASSWORD }}
        shell: powershell
        run: |
          $signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
          
          & $signtool sign `
            /f "qrchat.pfx" `
            /p $env:PFX_PASSWORD `
            /tr "http://timestamp.sectigo.com" `
            /td SHA256 `
            /fd SHA256 `
            /d "QRChat Installer" `
            /v `
            "QRChat-2.0.0-Setup.exe"
      
      - name: Upload Installer
        uses: actions/upload-artifact@v4
        with:
          name: windows-signed-installer
          path: "*.exe"
      
      - name: Cleanup
        if: always()
        shell: powershell
        run: |
          Remove-Item "qrchat.pfx" -ErrorAction SilentlyContinue
```

---

## 🎯 테스트

### SmartScreen 상태 확인
```powershell
# 서명 정보 확인
Get-AuthenticodeSignature "QRChat-2.0.0-Setup.exe" | Format-List

# 출력:
# SignerCertificate : [Subject] CN=QRChat Inc., O=QRChat Inc., ...
# Status            : Valid
```

### 다른 Windows PC에서 테스트
1. 서명된 설치 프로그램을 다른 PC로 복사
2. 실행
3. **SmartScreen 경고 확인**:
   - OV: 처음에는 경고 표시 (몇 주 후 사라짐)
   - EV: 경고 없음 (즉시)

---

## 🐛 문제 해결

### "SignTool Error: No certificates were found"
```powershell
# 인증서 확인
Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

# 없으면 PFX 다시 import
certutil -importpfx qrchat.pfx
```

### "Timestamp server error"
```powershell
# 다른 타임스탬프 서버 시도
/tr "http://timestamp.digicert.com"
/tr "http://timestamp.globalsign.com"
/tr "http://timestamp.comodoca.com"
```

### SmartScreen이 계속 경고 표시
**OV 인증서의 경우 정상입니다:**
- Microsoft는 다운로드 **평판**을 추적
- 몇 주간 많은 사용자가 다운로드해야 경고 사라짐
- **해결책**:
  - EV 인증서로 업그레이드 ($500/년)
  - 사용자들에게 "계속" 클릭 안내
  - 웹사이트에 설명 추가

---

## 💰 비용 요약

### OV 인증서
- **Sectigo OV**: $200/년
- **도구**: 무료 (Windows SDK, NSIS)
- **총**: **$200/년**

### EV 인증서
- **Sectigo EV**: $400/년
- **하드웨어 토큰**: 무료 (포함)
- **도구**: 무료
- **총**: **$400/년**

### 예상 시간
- 서류 준비: 1-2시간
- 신청 및 검증 대기: 1-7일
- 설정 및 테스트: 2-4시간
- **총**: 3-7일

---

## 🔒 보안 모범 사례

### PFX 파일 보호
```bash
# 1. 강력한 비밀번호 사용
# 2. 안전한 곳에 백업 (암호화된 USB, 클라우드 저장소)
# 3. GitHub Secrets에 저장 (Base64)
# 4. 만료 전 갱신 알림 설정
```

### 타임스탬프 필수
```
타임스탬프를 사용하면:
- 인증서 만료 후에도 서명 유효
- 사용자가 오래된 버전 설치 가능
- 항상 /tr 옵션 사용!
```

---

## ✅ 완료 체크리스트

- [ ] 인증서 구매 (OV 또는 EV)
- [ ] CSR 생성
- [ ] 서류 제출 및 검증
- [ ] 인증서 발급 받음
- [ ] PFX 파일 생성
- [ ] SignTool 설치
- [ ] EXE 서명 테스트
- [ ] NSIS 설치 프로그램 생성
- [ ] 설치 프로그램 서명
- [ ] GitHub Secrets 설정
- [ ] GitHub Actions 테스트
- [ ] 다른 Windows PC에서 검증

---

## 🎉 성공하면

**사용자 경험 개선:**
- ✅ Windows Defender 경고 감소
- ✅ SmartScreen 필터 통과 (EV는 즉시)
- ✅ 신뢰도 향상
- ✅ 전문적인 이미지

**다음 단계:**
- v2.1.0 개발
- App Store / Microsoft Store 배포 (선택)
- 마케팅 시작

---

## 📚 참고 자료

- [Microsoft SignTool 문서](https://docs.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [Sectigo Code Signing](https://sectigo.com/ssl-certificates-tls/code-signing)
- [Windows SmartScreen](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-smartscreen/)
- [NSIS Documentation](https://nsis.sourceforge.io/Docs/)

---

**Windows 코드 서명 완료!** 🪟✨

**이제 v2.1.0 계획으로 넘어가세요!** 🚀
