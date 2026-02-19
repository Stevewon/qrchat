# 📥 QRChat Desktop 설치 가이드

## 목차
- [Windows 설치](#windows-설치)
- [macOS 설치](#macos-설치)
- [Linux 설치](#linux-설치)
- [문제 해결](#문제-해결)

---

## Windows 설치

### 방법 1: MSIX 인스톨러 (권장) 🌟

#### 단계별 설치
1. **다운로드**
   ```
   https://github.com/Stevewon/qrchat/releases/latest/download/qrchat.msix
   ```

2. **설치 실행**
   - 다운로드한 `qrchat.msix` 파일을 더블클릭
   - Windows가 앱 설치 권한을 요청하면 "설치" 클릭

3. **인증서 신뢰 (필요 시)**
   - "이 앱을 설치하시겠습니까?" 메시지가 나타나면
   - "자세히" 클릭 → "확인" 클릭

4. **완료!**
   - 시작 메뉴에서 "QRChat" 검색
   - 또는 바탕화면 아이콘 클릭

### 방법 2: 포터블 버전

#### 설치 없이 사용
1. **다운로드**
   ```
   https://github.com/Stevewon/qrchat/releases/latest/download/QRChat-2.0.0-windows-portable.zip
   ```

2. **압축 해제**
   - ZIP 파일을 원하는 위치에 압축 해제

3. **실행**
   - `qrchat.exe` 파일을 더블클릭

### Windows Defender 경고 해결
Windows Defender SmartScreen 경고가 나타날 경우:
1. "추가 정보" 클릭
2. "실행" 버튼 클릭
3. (인증서 서명 작업 중이므로 추후 해결 예정)

---

## macOS 설치

### DMG 인스톨러 방식 🍎

#### 단계별 설치
1. **다운로드**
   ```
   https://github.com/Stevewon/qrchat/releases/latest/download/QRChat-2.0.0-macos.dmg
   ```

2. **DMG 마운트**
   - 다운로드한 DMG 파일을 더블클릭
   - Finder 창이 열림

3. **앱 설치**
   - QRChat 앱 아이콘을 Applications 폴더로 드래그

4. **완료!**
   - Launchpad에서 QRChat 실행

### Gatekeeper 경고 해결
"개발자를 확인할 수 없습니다" 경고가 나타날 경우:

**방법 1: 우클릭 메뉴**
1. QRChat 앱을 우클릭 (또는 Control+클릭)
2. "열기" 선택
3. "열기" 버튼 클릭

**방법 2: 시스템 설정**
1. 시스템 설정 → 개인정보 보호 및 보안
2. "확인 없이 열기" 버튼 클릭
3. QRChat 다시 실행

### Apple Silicon (M1/M2/M3) 사용자
- 현재 버전은 Intel x64 바이너리입니다
- Rosetta 2가 자동으로 실행됩니다
- 네이티브 ARM64 버전은 차후 제공 예정

---

## Linux 설치

### Ubuntu/Debian (.deb 패키지) 🐧

#### 방법 1: 명령줄 설치 (권장)
```bash
# 다운로드
wget https://github.com/Stevewon/qrchat/releases/latest/download/qrchat_2.0.0_amd64.deb

# 설치
sudo dpkg -i qrchat_2.0.0_amd64.deb

# 의존성 해결 (필요 시)
sudo apt-get install -f

# 실행
qrchat
```

#### 방법 2: GUI 설치
1. `.deb` 파일 다운로드
2. 파일 더블클릭
3. "소프트웨어 설치" 클릭
4. 비밀번호 입력

### AppImage (모든 배포판)

#### 사용 방법
```bash
# 다운로드
wget https://github.com/Stevewon/qrchat/releases/latest/download/QRChat-2.0.0-linux-x86_64.AppImage

# 실행 권한 부여
chmod +x QRChat-2.0.0-linux-x86_64.AppImage

# 실행
./QRChat-2.0.0-linux-x86_64.AppImage
```

### Fedora/RHEL (.rpm - 계획)
```bash
# 다운로드
wget https://github.com/Stevewon/qrchat/releases/latest/download/qrchat-2.0.0-1.x86_64.rpm

# 설치
sudo dnf install ./qrchat-2.0.0-1.x86_64.rpm

# 또는 (구버전)
sudo yum install ./qrchat-2.0.0-1.x86_64.rpm
```

### Arch Linux (AUR - 계획)
```bash
# yay 사용
yay -S qrchat

# 또는 paru
paru -S qrchat
```

### 의존성 수동 설치
필요한 라이브러리가 없을 경우:

**Ubuntu/Debian:**
```bash
sudo apt-get install libgtk-3-0 libgstreamer1.0-0 libnotify4
```

**Fedora:**
```bash
sudo dnf install gtk3 gstreamer1 libnotify
```

---

## 문제 해결

### Windows

#### 문제: "앱을 실행할 수 없습니다"
**해결:**
- Windows 10 버전 1903 이상인지 확인
- Windows Update 실행

#### 문제: 안티바이러스 차단
**해결:**
- 안티바이러스 예외 목록에 QRChat 추가
- 일시적으로 비활성화 후 설치

### macOS

#### 문제: "손상되었기 때문에 열 수 없습니다"
**해결:**
```bash
xattr -cr /Applications/QRChat.app
```

#### 문제: Rosetta 2 미설치 (Apple Silicon)
**해결:**
```bash
softwareupdate --install-rosetta
```

### Linux

#### 문제: 라이브러리 누락
**해결:**
```bash
# 모든 의존성 확인
ldd /usr/bin/qrchat

# 누락된 패키지 설치
sudo apt-get install <패키지명>
```

#### 문제: 시스템 트레이 아이콘 미표시
**해결:**
- Wayland 대신 X11 세션 사용
- 또는 시스템 트레이 확장 설치 (GNOME)

#### 문제: 권한 오류
**해결:**
```bash
sudo chmod +x /usr/bin/qrchat
```

---

## 제거 방법

### Windows
1. 설정 → 앱 → 설치된 앱
2. "QRChat" 검색
3. "제거" 클릭

또는 명령줄:
```powershell
winget uninstall qrchat
```

### macOS
1. Finder → Applications
2. QRChat 앱을 휴지통으로 드래그
3. 휴지통 비우기

또는 명령줄:
```bash
rm -rf /Applications/QRChat.app
```

### Linux
```bash
# Debian/Ubuntu
sudo apt-get remove qrchat

# Fedora
sudo dnf remove qrchat

# AppImage (단순 삭제)
rm QRChat-2.0.0-linux-x86_64.AppImage
```

---

## 자동 업데이트

QRChat Desktop은 자동 업데이트를 지원합니다!

### 업데이트 확인 주기
- **자동**: 1시간마다
- **수동**: 설정 → 업데이트 확인

### 업데이트 프로세스
1. 백그라운드에서 자동 확인
2. 새 버전 발견 시 알림
3. "지금 업데이트" 클릭
4. 다운로드 및 설치
5. 재시작 프롬프트

### 업데이트 비활성화
설정 → 일반 → "자동 업데이트" 체크 해제

---

## 추가 도움말

### 공식 웹사이트
https://qrchat.io

### GitHub Issues
https://github.com/Stevewon/qrchat/issues

### 이메일 지원
support@qrchat.io

### 커뮤니티
- Discord: (추후 공개)
- Reddit: r/qrchat (추후 공개)

---

## 시스템 요구사항 요약

| OS | 최소 버전 | RAM | 저장공간 |
|----|----------|-----|---------|
| Windows | 10 (1903) | 4GB | 500MB |
| macOS | 11 Big Sur | 4GB | 500MB |
| Linux | Ubuntu 20.04+ | 4GB | 500MB |

---

**설치가 완료되면 QRChat을 즐겨보세요!** 🎉

문제가 있다면 언제든지 문의해 주세요! 💙
