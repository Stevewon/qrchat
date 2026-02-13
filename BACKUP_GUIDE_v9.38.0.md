# QRChat v9.38.0 백업 파일 가이드

## 📦 백업 파일 목록

### 1. 소스 코드 백업 (권장 - 빠른 다운로드)
```
파일명: QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz
크기: 5.1 MB
포함 내용: 소스 코드만 (APK 제외)
```

**다운로드 링크**:
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz
```

**포함 항목**:
- ✅ 전체 Flutter 소스 코드
- ✅ pubspec.yaml (의존성 목록)
- ✅ 모든 Dart 파일 (lib/, test/)
- ✅ 리소스 파일 (assets/, fonts/)
- ✅ 설정 파일 (android/, ios/, web/)
- ✅ 문서 파일 (README, 릴리즈 노트)
- ✅ 웹 관리자 페이지 (web_admin/)
- ✅ 다운로드 페이지 (download.html)

**제외 항목**:
- ❌ build/ (빌드 결과물)
- ❌ .dart_tool/ (Dart 도구 캐시)
- ❌ *.apk (APK 파일들)
- ❌ *.zip (ZIP 파일들)
- ❌ .git/ (Git 히스토리)

---

### 2. 완전 백업 (APK 포함)
```
파일명: QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz
크기: 75 MB
포함 내용: 소스 코드 + 최신 APK
```

**다운로드 링크**:
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz
```

**포함 항목**:
- ✅ 위의 소스 코드 백업 내용 전부
- ✅ QRChat-v9.38.0-GROUP-MEDIA-FIX.apk (69 MB)
- ✅ QRChat-v9.38.0-GROUP-MEDIA-FIX.zip (33 MB)

**제외 항목**:
- ❌ 이전 버전 APK (v9.30~v9.37)
- ❌ 이전 버전 ZIP 파일
- ❌ build/, .dart_tool/, .git/

---

## 📥 백업 파일 다운로드

### 옵션 1: 소스 코드만 (5.1 MB - 권장)
```bash
# 다운로드
curl -O https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz

# 압축 해제
tar -xzf QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz

# 의존성 설치
cd webapp
flutter pub get

# 앱 빌드
flutter build apk --release
```

### 옵션 2: APK 포함 전체 백업 (75 MB)
```bash
# 다운로드
curl -O https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz

# 압축 해제
tar -xzf QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz

# APK 바로 사용 가능
cd webapp
ls -lh QRChat-v9.38.0-GROUP-MEDIA-FIX.apk
```

---

## 🔧 복원 방법

### 1단계: 백업 파일 다운로드
```bash
# 브라우저에서 다운로드 또는 curl 사용
curl -O https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz
```

### 2단계: 압축 해제
```bash
# 새 디렉토리 생성
mkdir qrchat-restore
cd qrchat-restore

# 압축 해제
tar -xzf ../QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz
```

### 3단계: Flutter 환경 설정
```bash
# Flutter 의존성 설치
flutter pub get

# Flutter doctor 실행 (환경 확인)
flutter doctor
```

### 4단계: APK 빌드 (소스 코드 백업인 경우)
```bash
# Android SDK 경로 설정
export ANDROID_HOME=/path/to/android-sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Release APK 빌드
flutter build apk --release

# APK 위치 확인
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

## 📂 백업 파일 구조

```
QRChat-v9.38.0-FULL-BACKUP/
├── lib/                          # Dart 소스 코드
│   ├── main.dart
│   ├── models/                   # 데이터 모델
│   ├── screens/                  # 화면 위젯
│   ├── services/                 # 비즈니스 로직
│   └── widgets/                  # 재사용 위젯
├── assets/                       # 리소스 파일
│   ├── images/
│   └── fonts/
├── android/                      # Android 설정
│   ├── app/
│   └── gradle/
├── ios/                          # iOS 설정
├── web/                          # Web 설정
├── web_admin/                    # 스티커 관리자 페이지
│   └── index.html
├── pubspec.yaml                  # 의존성 목록
├── download.html                 # 다운로드 페이지
├── RELEASE_NOTES_v9.38.0.md     # 릴리즈 노트
└── README.md                     # 프로젝트 문서
```

---

## ⚙️ 시스템 요구사항

### 개발 환경
- **Flutter SDK**: 3.41.0 이상
- **Dart SDK**: 3.11.0 이상
- **Android SDK**: API 21 (Android 5.0) 이상
- **Java**: JDK 11 이상

### 빌드 환경
- **메모리**: 최소 4GB RAM (권장 8GB)
- **디스크**: 최소 10GB 여유 공간
- **운영체제**: Windows, macOS, Linux

---

## 🔑 Firebase 설정 (중요!)

백업 파일에는 Firebase 설정이 포함되어 있지만, 새로운 환경에서 작동하려면:

1. **Firebase 프로젝트 확인**
   - Firebase Console: https://console.firebase.google.com/project/qrchat-b7a67

2. **google-services.json 확인**
   - 위치: `android/app/google-services.json`
   - 이미 백업에 포함되어 있음

3. **Firebase 규칙 확인**
   - Firestore Rules: 읽기/쓰기 권한 설정
   - Storage Rules: 파일 업로드 권한 설정

---

## 📊 백업 파일 비교

| 항목 | 소스 코드 백업 | 완전 백업 (APK 포함) |
|------|---------------|---------------------|
| **크기** | 5.1 MB | 75 MB |
| **다운로드 시간** | 빠름 ⚡ | 보통 |
| **소스 코드** | ✅ | ✅ |
| **APK 파일** | ❌ | ✅ |
| **ZIP 파일** | ❌ | ✅ |
| **빌드 필요** | 필요 🔨 | 불필요 |
| **권장 용도** | 개발자 | 일반 사용자 |

---

## 🚀 빠른 시작 가이드

### 개발자용 (소스 코드 백업)
```bash
# 1. 백업 다운로드
wget https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz

# 2. 압축 해제
tar -xzf QRChat-v9.38.0-FULL-BACKUP-20260213-032357.tar.gz
cd webapp

# 3. 의존성 설치
flutter pub get

# 4. 앱 실행 (개발 모드)
flutter run

# 5. APK 빌드 (릴리즈 모드)
flutter build apk --release
```

### 일반 사용자용 (완전 백업)
```bash
# 1. 백업 다운로드
wget https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz

# 2. 압축 해제
tar -xzf QRChat-v9.38.0-COMPLETE-WITH-APK-20260213-032410.tar.gz
cd webapp

# 3. APK 설치 (Android 기기로 전송)
adb install QRChat-v9.38.0-GROUP-MEDIA-FIX.apk
```

---

## 📝 백업 날짜 및 버전 정보

- **백업 생성 날짜**: 2026-02-13 03:23 UTC
- **앱 버전**: 9.38.0 (Build 9380)
- **Flutter SDK**: 3.41.0
- **Dart SDK**: 3.11.0
- **Git 커밋**: cdf6da3

---

## 🔗 관련 링크

- **다운로드 페이지**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html
- **GitHub Repository**: https://github.com/Stevewon/qrchat
- **GitHub Release**: https://github.com/Stevewon/qrchat/releases/tag/v9.38.0
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67

---

## ⚠️ 주의사항

1. **백업 파일 보관**
   - 안전한 장소에 백업 파일 보관
   - 정기적으로 새 백업 생성 권장

2. **Firebase 보안**
   - `google-services.json` 파일을 공개 저장소에 올리지 마세요
   - Firebase 규칙을 항상 확인하세요

3. **버전 관리**
   - Git을 사용하여 버전 관리 권장
   - 주요 변경사항마다 태그 생성

---

**백업 완료! 🎉**

두 가지 백업 옵션 중 필요에 맞는 파일을 다운로드하세요:
- **개발자**: 소스 코드 백업 (5.1 MB)
- **일반 사용자**: 완전 백업 (75 MB)
