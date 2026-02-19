# 🖥️ QRChat Desktop Development

## 📋 Project Overview

QRChat PC 버전 개발 프로젝트입니다. 카카오톡처럼 완전한 데스크톱 경험을 제공합니다!

### ✨ 목표 기능
- ✅ Windows, macOS, Linux 지원
- ✅ 시스템 트레이 통합 (카카오톡처럼)
- ✅ 윈도우 크기/위치 기억
- ✅ 자동 시작 옵션
- ✅ 데스크톱 알림
- ✅ 키보드 단축키

## 🚀 완료된 작업

### 1단계: Flutter Desktop 활성화 ✅
```bash
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
```

### 2단계: Desktop 플랫폼 생성 ✅
```bash
flutter create --platforms=linux,windows,macos .
```

### 3단계: Desktop 패키지 추가 ✅
`pubspec.yaml`에 추가된 패키지:
- `window_manager`: 윈도우 크기/위치 제어
- `tray_manager`: 시스템 트레이 아이콘
- `launch_at_startup`: 자동 시작
- `screen_retriever`: 화면 정보
- `local_notifier`: 데스크톱 알림

### 4단계: main.dart 수정 ✅
Desktop 지원 코드 추가:
```dart
// 🖥️ Desktop 초기화 (Windows, macOS, Linux)
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  await _initializeDesktop();
}
```

주요 기능:
- ✅ 윈도우 크기 설정 (1200x800, 카카오톡 스타일)
- ✅ 최소 크기 제한 (800x600)
- ✅ 화면 중앙 배치
- ✅ 시스템 트레이 메뉴
- ✅ 자동 시작 설정

## 🔧 Linux 빌드 의존성

### 설치된 패키지
```bash
# Build tools
sudo apt-get install -y cmake ninja-build pkg-config

# GTK development
sudo apt-get install -y libgtk-3-dev

# C++ compiler
sudo apt-get install -y clang build-essential

# Audio support (GStreamer)
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# Desktop notifications
sudo apt-get install -y libnotify-dev

# System tray support
sudo apt-get install -y libayatana-appindicator3-dev
```

## 📱 플랫폼별 빌드 명령어

### Linux
```bash
flutter build linux --release
```

### Windows (Windows 환경에서)
```bash
flutter build windows --release
```

### macOS (macOS 환경에서)
```bash
flutter build macos --release
```

## 🎯 다음 단계

### PC UI 최적화
- [ ] 큰 화면용 레이아웃 개선
- [ ] 멀티윈도우 지원
- [ ] 키보드 단축키 추가
  - `Ctrl+Enter`: 메시지 전송
  - `Ctrl+N`: 새 채팅
  - `Ctrl+K`: 검색
  - `Ctrl+,`: 설정

### 파일 처리 개선
- [ ] 드래그앤드롭 지원
- [ ] 클립보드 이미지 붙여넣기
- [ ] 파일 미리보기

### 시스템 통합
- [ ] 시작 시 자동 실행 설정 UI
- [ ] 시스템 트레이 메뉴 확장
- [ ] 알림 배지 숫자 표시
- [ ] 윈도우 최소화 동작 설정

### 설치 프로그램
- [ ] Windows: `.exe` 인스톨러 (NSIS/Inno Setup)
- [ ] macOS: `.dmg` 패키지
- [ ] Linux: `.deb`, `.rpm`, AppImage

### 자동 업데이트
- [ ] 업데이트 확인
- [ ] 백그라운드 다운로드
- [ ] 재시작 없이 업데이트

## 📦 배포 계획

### Phase 1: 베타 테스트 (1-2주)
- Linux 버전 완성
- 기본 기능 테스트
- 버그 수정

### Phase 2: Windows/macOS (2-3주)
- Windows 버전 빌드
- macOS 버전 빌드
- 크로스 플랫폼 테스트

### Phase 3: 설치 프로그램 (1주)
- 각 플랫폼별 인스톨러 생성
- 코드 사이닝
- 배포 자동화

### Phase 4: 자동 업데이트 (1주)
- 업데이트 서버 구축
- 자동 업데이트 구현
- 롤백 기능

## 🎨 UI/UX 개선 사항

### 큰 화면 최적화
- 채팅 리스트: 왼쪽 (300px)
- 채팅 내용: 중앙 (나머지 공간)
- 사용자 정보: 오른쪽 (300px, 선택적)

### 반응형 레이아웃
```dart
if (MediaQuery.of(context).size.width > 1024) {
  // 3단 레이아웃
} else if (MediaQuery.of(context).size.width > 768) {
  // 2단 레이아웃
} else {
  // 모바일 레이아웃
}
```

## 🔐 보안 고려사항

- ✅ Firebase 설정 보호
- ✅ 로컬 데이터 암호화
- ✅ 안전한 업데이트 메커니즘
- ✅ 코드 사이닝 (배포 시)

## 📚 참고 자료

- [Flutter Desktop 공식 문서](https://docs.flutter.dev/desktop)
- [window_manager 패키지](https://pub.dev/packages/window_manager)
- [tray_manager 패키지](https://pub.dev/packages/tray_manager)
- [카카오톡 PC 버전 참고](https://www.kakaocorp.com/page/service/service/KakaoTalk)

## 🎯 성공 지표

- ✅ 3개 플랫폼 지원 (Windows, macOS, Linux)
- ✅ 모바일 앱과 동일한 기능
- ✅ 부드러운 60fps 성능
- ✅ 100MB 이하 설치 크기
- ✅ 1초 이내 시작 시간

---

**개발 시작일**: 2026-02-19
**현재 버전**: 1.0.85 (Desktop Branch)
**목표 릴리스**: v2.0.0 Desktop Edition

🚀 함께 최고의 PC 메신저를 만들어가요!
