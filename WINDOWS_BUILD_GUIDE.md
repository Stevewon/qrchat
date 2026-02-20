# 🪟 QRChat Windows 설치 프로그램 만들기

## 📋 목표
카카오톡처럼 **Windows PC에 설치되는 .exe 프로그램** 만들기

---

## 🛠️ **필요한 것**

### 1. Windows PC (필수!)
- Windows 10/11
- 관리자 권한

### 2. 소프트웨어 설치
- Flutter SDK
- Visual Studio 2022 (Community 무료판)
- NSIS (설치 프로그램 제작 도구)

---

## 📝 **Step 1: 개발 환경 설정**

### **1-1. Flutter 설치**

1. **Flutter 다운로드**
   - https://docs.flutter.dev/get-started/install/windows
   - `flutter_windows_3.41.1-stable.zip` 다운로드

2. **압축 해제**
   ```
   C:\src\flutter\
   ```

3. **환경 변수 설정**
   - 시스템 환경 변수 → Path 편집
   - `C:\src\flutter\bin` 추가

4. **확인**
   ```cmd
   flutter --version
   ```

---

### **1-2. Visual Studio 2022 설치**

1. **다운로드**
   - https://visualstudio.microsoft.com/ko/downloads/
   - "Community" 버전 (무료)

2. **워크로드 선택**
   - ✅ "C++를 사용한 데스크톱 개발"
   - ✅ "Windows 10/11 SDK"

3. **설치 확인**
   ```cmd
   flutter doctor
   ```

---

### **1-3. NSIS 설치 (설치 프로그램 제작)**

1. **다운로드**
   - https://nsis.sourceforge.io/Download
   - `nsis-3.09-setup.exe` 설치

2. **설치 경로**
   ```
   C:\Program Files (x86)\NSIS\
   ```

---

## 🚀 **Step 2: 프로젝트 준비**

### **2-1. 프로젝트 다운로드**

```cmd
git clone https://github.com/Stevewon/qrchat.git
cd qrchat
```

### **2-2. 의존성 설치**

```cmd
flutter pub get
```

### **2-3. Windows 데스크톱 활성화**

```cmd
flutter config --enable-windows-desktop
```

---

## 🔨 **Step 3: Windows 앱 빌드**

### **3-1. Release 빌드**

```cmd
flutter build windows --release
```

**빌드 결과:**
```
build/windows/x64/runner/Release/
├── qrchat.exe          (실행 파일)
├── flutter_windows.dll
├── data/               (리소스)
└── ... (기타 DLL)
```

### **3-2. 테스트 실행**

```cmd
build\windows\x64\runner\Release\qrchat.exe
```

---

## 📦 **Step 4: 설치 프로그램 만들기**

### **4-1. NSIS 스크립트 작성**

`installer.nsi` 파일 생성:

```nsis
!define APP_NAME "QRChat"
!define APP_VERSION "2.0.0"
!define COMPANY_NAME "QRChat Team"
!define APP_EXECUTABLE "qrchat.exe"

; 설치 프로그램 이름
OutFile "QRChat_Setup_v${APP_VERSION}.exe"

; 설치 디렉토리
InstallDir "$PROGRAMFILES64\${APP_NAME}"

; 현대적인 UI
!include "MUI2.nsh"

; UI 설정
!define MUI_ICON "windows\runner\resources\app_icon.ico"
!define MUI_UNICON "windows\runner\resources\app_icon.ico"
!define MUI_WELCOMEPAGE_TITLE "${APP_NAME} 설치"
!define MUI_WELCOMEPAGE_TEXT "카카오톡 스타일 메신저 ${APP_NAME}을 설치합니다."

; 페이지
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; 언어
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "English"

; 설치 섹션
Section "Install"
    SetOutPath "$INSTDIR"
    
    ; 모든 파일 복사
    File /r "build\windows\x64\runner\Release\*.*"
    
    ; 시작 메뉴 바로가기
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    
    ; 바탕화면 바로가기
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
    
    ; 레지스트리 등록 (프로그램 추가/제거)
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXECUTABLE}"
    
    ; 언인스톨러 생성
    WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

; 삭제 섹션
Section "Uninstall"
    ; 파일 삭제
    RMDir /r "$INSTDIR"
    
    ; 바로가기 삭제
    Delete "$DESKTOP\${APP_NAME}.lnk"
    RMDir /r "$SMPROGRAMS\${APP_NAME}"
    
    ; 레지스트리 삭제
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd
```

---

### **4-2. 설치 프로그램 빌드**

```cmd
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
```

**결과:**
```
QRChat_Setup_v2.0.0.exe (약 30MB)
```

---

## 🔐 **Step 5: 코드 서명 (인증서 발급 후)**

### **5-1. 인증서 준비**

SSL.com에서 받은 `.pfx` 파일:
```
qrchat_code_signing.pfx
비밀번호: [저장한 비밀번호]
```

### **5-2. SignTool로 서명**

```cmd
"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign ^
  /f qrchat_code_signing.pfx ^
  /p [비밀번호] ^
  /t http://timestamp.sectigo.com ^
  /fd SHA256 ^
  QRChat_Setup_v2.0.0.exe
```

### **5-3. 서명 확인**

```cmd
signtool verify /pa QRChat_Setup_v2.0.0.exe
```

**성공 메시지:**
```
Successfully verified: QRChat_Setup_v2.0.0.exe
```

---

## 🎯 **Step 6: 배포**

### **6-1. 테스트**

1. **설치 테스트**
   - `QRChat_Setup_v2.0.0.exe` 실행
   - 설치 진행
   - 바탕화면 아이콘 확인

2. **실행 테스트**
   - 바탕화면 아이콘 더블클릭
   - 앱 정상 실행 확인

3. **삭제 테스트**
   - 제어판 → 프로그램 제거
   - QRChat 선택 → 제거

### **6-2. GitHub Release 업로드**

```cmd
gh release create v2.0.0 ^
  QRChat_Setup_v2.0.0.exe ^
  --title "QRChat v2.0.0 - Windows Edition" ^
  --notes "카카오톡 스타일 Windows 메신저"
```

### **6-3. 웹사이트에 다운로드 링크 추가**

```html
<a href="https://github.com/Stevewon/qrchat/releases/download/v2.0.0/QRChat_Setup_v2.0.0.exe">
  Windows용 다운로드
</a>
```

---

## 📊 **파일 크기 최적화**

### **압축 설정**

NSIS 스크립트에 추가:
```nsis
SetCompressor /SOLID lzma
SetCompressorDictSize 32
```

**결과:**
- 압축 전: ~50MB
- 압축 후: ~25MB

---

## 🎨 **설치 프로그램 커스터마이징**

### **1. 아이콘 변경**

```nsis
!define MUI_ICON "resources\installer_icon.ico"
```

### **2. 배너 이미지 추가**

```nsis
!define MUI_WELCOMEFINISHPAGE_BITMAP "resources\welcome.bmp"
```

### **3. 라이선스 파일**

```nsis
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
```

---

## 🔧 **자동 시작 옵션**

### **시작 프로그램 등록**

NSIS 스크립트:
```nsis
Section "Auto Start"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}" "$INSTDIR\${APP_EXECUTABLE}"
SectionEnd
```

사용자가 체크박스로 선택 가능하게:
```nsis
Section /o "Auto Start" SEC_AUTOSTART
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}" "$INSTDIR\${APP_EXECUTABLE}"
SectionEnd
```

---

## 📦 **Portable 버전 (설치 없이 실행)**

### **ZIP 파일 생성**

```cmd
cd build\windows\x64\runner\Release
powershell Compress-Archive -Path * -DestinationPath QRChat_Portable_v2.0.0.zip
```

---

## 🎯 **완성!**

### **최종 결과:**

```
QRChat_Setup_v2.0.0.exe (서명됨, 25MB)
│
├─ 설치 시
│  ├─ C:\Program Files\QRChat\
│  ├─ 시작 메뉴 바로가기
│  ├─ 바탕화면 아이콘
│  └─ 프로그램 추가/제거 등록
│
└─ 실행 시
   ├─ 시스템 트레이 아이콘
   ├─ 창 크기/위치 기억
   └─ 자동 업데이트 확인
```

---

## 🚀 **빠른 시작 체크리스트**

- [ ] Flutter 설치
- [ ] Visual Studio 2022 설치
- [ ] NSIS 설치
- [ ] 프로젝트 clone
- [ ] `flutter build windows --release`
- [ ] `installer.nsi` 작성
- [ ] NSIS로 설치 프로그램 빌드
- [ ] 인증서로 코드 서명
- [ ] 테스트
- [ ] 배포!

---

## 📚 **참고 자료**

- [Flutter Windows 빌드](https://docs.flutter.dev/deployment/windows)
- [NSIS 문서](https://nsis.sourceforge.io/Docs/)
- [SignTool 가이드](https://docs.microsoft.com/en-us/windows/win32/seccrypto/signtool)

---

**작성일:** 2026-02-19  
**버전:** 2.0.0  
**대상:** Windows 10/11 (64-bit)  

🎉 카카오톡처럼 멋진 Windows 메신저 완성!
