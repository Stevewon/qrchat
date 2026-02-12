# QRChat 버그 수정 버전 빌드 가이드

## 🐛 수정된 버그
- 그룹 채팅 중복 초대 방지
- 초대 버튼 연속 클릭 방지

## 📱 APK 빌드 방법

### 방법 1: 로컬에서 빌드 (권장)

1. **소스 코드 다운로드**
   ```bash
   git clone https://github.com/Stevewon/qrchat.git
   cd qrchat
   ```

2. **Flutter 의존성 설치**
   ```bash
   flutter pub get
   ```

3. **APK 빌드**
   ```bash
   flutter build apk --release
   ```

4. **APK 위치**
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

### 방법 2: GitHub Actions로 자동 빌드

1. `.github/workflows/build.yml` 생성
2. Push하면 자동으로 APK 빌드
3. GitHub Releases에서 다운로드

### 방법 3: Android Studio 사용

1. Android Studio에서 프로젝트 열기
2. Build → Flutter → Build APK
3. 빌드된 APK 확인

## 🔧 빌드 요구사항

- Flutter SDK 3.9.2+
- Android SDK
- Java 17+

## 📝 수정된 파일

- `lib/screens/chat_screen.dart`
  - `_isInviting` 플래그 추가
  - 중복 초대 방지 로직 구현

## ✅ 확인 사항

빌드 전에 다음을 확인하세요:
- Firebase 설정 파일 (`google-services.json`)
- 서명 키 설정 (릴리스 빌드 시)

## 📱 테스트 방법

1. APK를 안드로이드 기기에 설치
2. 그룹 채팅방 열기
3. 친구 초대 버튼 여러 번 클릭
4. 1번만 초대되는지 확인

---

**GitHub**: https://github.com/Stevewon/qrchat
**커밋**: 9d988e0
