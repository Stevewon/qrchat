# QRChat v2.0.1 빌드 방법

## ⚠️ 중요: 새 APK 빌드 필요

현재 샌드박스에서는 Android SDK가 없어서 APK를 빌드할 수 없습니다.
아래 방법 중 하나를 선택해서 빌드해주세요:

---

## 방법 1: 로컬 Android Studio (권장)

### 1️⃣ 저장소 클론
```bash
git clone https://github.com/Stevewon/qrchat.git
cd qrchat
git checkout v2.0.1
```

### 2️⃣ Flutter 설정
```bash
flutter doctor
flutter pub get
```

### 3️⃣ APK 빌드
```bash
flutter build apk --release
```

### 4️⃣ APK 위치
```
build/app/outputs/flutter-apk/app-release.apk
```

### 5️⃣ 버전 확인
빌드 후 앱을 설치하고 **설정 → 앱 정보**에서 버전이 **2.0.1+201**인지 확인하세요!

---

## 방법 2: GitHub Codespaces

### 1️⃣ Codespaces 열기
```
https://github.com/Stevewon/qrchat
→ Code 버튼
→ Codespaces 탭
→ "Create codespace on master"
```

### 2️⃣ Flutter 설치
```bash
# Flutter 설치
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Android SDK 설치
flutter doctor --android-licenses
```

### 3️⃣ 빌드
```bash
git checkout v2.0.1
flutter pub get
flutter build apk --release
```

---

## 방법 3: Codemagic (무료 CI/CD)

### 1️⃣ Codemagic 가입
https://codemagic.io/signup

### 2️⃣ 프로젝트 추가
- "Add application"
- GitHub 연결
- "Stevewon/qrchat" 선택

### 3️⃣ 빌드 설정
```yaml
workflows:
  android-workflow:
    name: Android Build
    max_build_duration: 60
    environment:
      flutter: stable
    scripts:
      - flutter pub get
      - flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/*.apk
```

### 4️⃣ 빌드 실행
- "Start new build"
- Branch: v2.0.1
- "Start build"

---

## 🔍 빌드 완료 후 확인사항

### ✅ 체크리스트
- [ ] APK 파일명: `app-release.apk`
- [ ] 파일 크기: ~70 MB
- [ ] 앱 설치 가능
- [ ] 설정에서 버전 확인: **v2.0.1+201**
- [ ] 알림음 테스트:
  - [ ] 1번째 메시지: 무음 📱
  - [ ] 2번째 메시지: 알림음 🔔
  - [ ] 3번째 메시지: 무음 📱
  - [ ] 4번째 메시지: 알림음 🔔

---

## 📦 릴리즈 업로드

APK 빌드 후:

### 1️⃣ GitHub Release 생성
```
https://github.com/Stevewon/qrchat/releases/new?tag=v2.0.1
```

### 2️⃣ 정보 입력
- **제목**: `QRChat v2.0.1 - 알림음 2회당 1회 로직 완벽 구현`
- **설명**: `/home/user/RELEASE_v2.0.1.md` 내용 복사
- **파일**: 빌드한 APK 업로드 (이름을 `qrchat_v2.0.1.apk`로 변경)

### 3️⃣ Publish
"Publish release" 클릭

---

## 🆘 문제 해결

### Q: Flutter 버전이 안 맞아요
```bash
flutter channel stable
flutter upgrade
```

### Q: Android SDK 라이센스 오류
```bash
flutter doctor --android-licenses
# "y" 입력해서 모두 동의
```

### Q: 빌드 중 Gradle 오류
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Q: Firebase 설정 오류
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 설정
firebase login
flutterfire configure
```

---

## 📞 도움이 필요하면

- **GitHub Issues**: https://github.com/Stevewon/qrchat/issues
- **이메일**: hocu00987@gmail.com

---

## 🎊 빌드 성공하면

1. **GitHub Release 생성**
2. **APK 업로드**
3. **테스트!**

빌드 성공을 기원합니다! 🚀
