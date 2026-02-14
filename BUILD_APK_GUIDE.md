# 📱 QRChat 모바일 APK 빌드 가이드

## 🎯 개요

QRChat 모바일 앱을 Android APK 파일로 빌드하는 전체 가이드입니다.

## 📋 사전 준비사항

### 1️⃣ **필수 설치 프로그램**
- ✅ Flutter SDK (최신 stable 버전)
- ✅ Android Studio
- ✅ Java Development Kit (JDK 11 이상)
- ✅ Git

### 2️⃣ **환경 변수 설정**
Windows에서 다음 경로를 Path에 추가:
- `C:\flutter\bin`
- `C:\Program Files\Android\Android Studio\bin`
- `%JAVA_HOME%\bin`

## 🚀 빌드 방법

### **방법 1: Release APK 빌드 (권장)**

```bash
# 1. 프로젝트 최신 코드 다운로드
cd C:\Users\sayto\qrchat
git pull origin main

# 2. 의존성 패키지 설치
flutter pub get

# 3. Release APK 빌드
flutter build apk --release

# 4. 빌드 완료 후 APK 위치
# 📂 build/app/outputs/flutter-apk/app-release.apk
```

### **방법 2: Debug APK 빌드 (테스트용)**

```bash
flutter build apk --debug
```

### **방법 3: Split APK 빌드 (용량 최적화)**

```bash
flutter build apk --split-per-abi --release
```

이 방법은 CPU 아키텍처별로 별도의 APK를 생성:
- `app-armeabi-v7a-release.apk` (32비트 ARM)
- `app-arm64-v8a-release.apk` (64비트 ARM - 가장 일반적)
- `app-x86_64-release.apk` (Intel 에뮬레이터)

## 📦 APK 파일 위치

빌드가 완료되면 다음 경로에 APK 파일이 생성됩니다:

```
C:\Users\sayto\qrchat\build\app\outputs\flutter-apk\
├── app-release.apk          (일반 빌드)
├── app-armeabi-v7a-release.apk  (32비트 ARM)
├── app-arm64-v8a-release.apk    (64비트 ARM - 권장)
└── app-x86_64-release.apk       (Intel)
```

**대부분의 Android 기기는 `app-arm64-v8a-release.apk` 사용**

## 🔧 빌드 트러블슈팅

### **오류 1: Flutter SDK를 찾을 수 없음**
```bash
flutter doctor -v
```
Flutter SDK 설치 상태 확인 및 누락된 항목 설치

### **오류 2: Android licenses 미동의**
```bash
flutter doctor --android-licenses
```
모든 라이선스에 `y` 입력

### **오류 3: Gradle 빌드 실패**
```bash
cd android
./gradlew clean
cd ..
flutter build apk --release
```

### **오류 4: 의존성 충돌**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 📲 APK 설치 방법

### **Android 기기에 직접 설치**

1. APK 파일을 휴대폰으로 전송 (USB, 이메일, 클라우드 등)
2. 휴대폰에서 APK 파일 실행
3. "알 수 없는 출처" 설치 허용 (설정 → 보안)
4. 설치 진행

### **ADB를 통한 설치**

```bash
# USB 디버깅 활성화 후
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🎨 최근 변경사항

### ✅ **v1.0.3 (2026-02-14)**

#### **기능 추가**
- ✅ QR 주소 기반 닉네임 찾기
- ✅ QR 주소 기반 비밀번호 찾기
- ✅ 로그인 화면에 "닉네임 찾기 | 비밀번호 찾기" 버튼 추가

#### **기능 제거**
- ❌ 모바일 앱에서 스티커 관리 기능 제거 (웹 대시보드에서 관리)
- ❌ admin_sticker_screen.dart 삭제
- ❌ 프로필 화면의 "스티커 관리자" 버튼 제거

#### **관리자 기능**
- ✅ 사용자 강제 차단 기능
- ✅ QR 코드 재가입 방지
- ✅ 중복 닉네임 제거
- ✅ 회원가입 시 닉네임 중복 체크

## 🔐 코드 서명 (선택사항)

Play Store 배포를 위해서는 코드 서명이 필요합니다:

### **1. Keystore 생성**
```bash
keytool -genkey -v -keystore qrchat-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias qrchat
```

### **2. android/key.properties 파일 생성**
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=qrchat
storeFile=C:/path/to/qrchat-release-key.jks
```

### **3. android/app/build.gradle 수정**
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 📊 빌드 크기 최적화

### **방법 1: 난독화 활성화**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### **방법 2: 사용하지 않는 리소스 제거**
```bash
flutter build apk --release --tree-shake-icons
```

### **방법 3: App Bundle 빌드 (Play Store용)**
```bash
flutter build appbundle --release
```

## 🧪 테스트 시나리오

APK 설치 후 반드시 테스트할 항목:

### ✅ **기본 기능**
- [ ] 회원가입 (QR 코드 입력)
- [ ] 닉네임 중복 체크
- [ ] 로그인 (닉네임 + 비밀번호)
- [ ] 닉네임 찾기 (QR 주소로)
- [ ] 비밀번호 찾기 (QR 주소로)

### ✅ **채팅 기능**
- [ ] 1:1 채팅
- [ ] 단체 채팅방
- [ ] 메시지 전송/수신
- [ ] 스티커 전송
- [ ] 이미지 전송

### ✅ **프로필 기능**
- [ ] 프로필 사진 변경
- [ ] 상태 메시지 변경
- [ ] 알림 설정
- [ ] 로그아웃

### ✅ **친구 기능**
- [ ] QR 코드로 친구 추가
- [ ] 친구 목록 확인
- [ ] 친구 삭제

### ✅ **QKEY 기능**
- [ ] QKEY 잔액 확인
- [ ] QKEY 거래 내역
- [ ] QKEY 출금 신청

## 🌐 관련 링크

- **GitHub 저장소**: https://github.com/Stevewon/qrchat
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67
- **웹 관리자 대시보드**: https://qrchat-b7a67.web.app/admin_dashboard.html
- **최신 커밋**: https://github.com/Stevewon/qrchat/commit/cb473de

## 💡 팁

1. **Release 빌드 권장**: Release APK는 Debug보다 훨씬 작고 빠릅니다
2. **Split APK 사용**: 기기별로 최적화된 APK로 용량 50% 절감
3. **버전 관리**: `pubspec.yaml`에서 `version: 1.0.3+3` 형식으로 버전 관리
4. **테스트 필수**: 실제 기기에서 반드시 테스트 후 배포

## 🎉 빌드 완료!

빌드가 완료되면 APK 파일을 배포하거나 테스트하세요!

**문의사항이 있으면 GitHub Issues에 등록해주세요.**
