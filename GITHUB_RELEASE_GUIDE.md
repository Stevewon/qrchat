# QRChat v9.33.0 GitHub Release 생성 가이드

## 📋 릴리즈 정보

- **버전**: v9.33.0
- **태그**: v9.33.0 (이미 생성됨 ✅)
- **릴리즈 날짜**: 2026-02-12

---

## 🚀 릴리즈 생성 단계

### 1. APK 빌드 (로컬 환경)

```bash
# 저장소 클론 또는 업데이트
git clone https://github.com/Stevewon/qrchat.git
cd qrchat
git checkout v9.33.0

# 의존성 설치
flutter pub get

# APK 빌드
flutter build apk --release

# 빌드된 APK 위치 확인
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

### 2. APK 파일 이름 변경

```bash
# 릴리즈용 이름으로 변경
cp build/app/outputs/flutter-apk/app-release.apk ./QRChat-v9.33.0.apk
```

---

## 📤 GitHub Releases 업로드 방법

### 방법 1: GitHub 웹 인터페이스 (권장)

1. **릴리즈 페이지 이동**
   - https://github.com/Stevewon/qrchat/releases

2. **"Draft a new release" 클릭**

3. **태그 선택**
   - "Choose a tag" → `v9.33.0` 선택 (이미 생성됨)

4. **릴리즈 제목 작성**
   ```
   🎉 QRChat v9.33.0 - 스티커 삭제 수정 및 UI 개선
   ```

5. **릴리즈 노트 작성**
   ```markdown
   ## 🆕 새로운 기능 및 개선 사항

   ### ✅ 스티커 삭제 기능 완전 수정
   - ✨ 스티커 관리자에서 삭제가 제대로 작동하지 않던 문제 해결
   - 🔧 Storage 경로 자동 추출 기능 추가
   - 🛡️ undefined 경로 처리 및 에러 핸들링 개선
   - 📝 Firestore 우선 업데이트 로직으로 데이터 일관성 보장

   ### 🎨 UI 개선
   - 💚 채팅 목록 스와이프 배경색 변경
     - 이전: 진한 빨간색 (너무 자극적)
     - 변경: 연한 연두색 (부드럽고 편안함)
   - 👆 채팅방 나가기 제스처 시각적 피드백 개선

   ---

   ## 🐛 버그 수정

   ### 스티커 관리자
   1. **삭제 기능 수정**
      - ❌ 문제: Storage 경로가 undefined로 전달됨
      - ✅ 해결: URL에서 Storage 경로 자동 추출
      - ✅ 해결: 경로 없을 때 안전 처리

   2. **데이터 일관성 개선**
      - Storage 삭제 전에 Firestore 먼저 업데이트
      - 업데이트 후 즉시 검증 로직 추가

   ### 채팅 목록
   - 스와이프 배경색: `Colors.red` → `Colors.lightGreen[200]`

   ---

   ## 📥 다운로드

   ### APK 설치 파일
   - **QRChat-v9.33.0.apk** (아래 Assets에서 다운로드)
   - Android 5.0 이상 지원

   ### 설치 방법
   1. APK 파일 다운로드
   2. "알 수 없는 출처" 앱 설치 허용
   3. APK 파일 실행하여 설치

   ---

   ## 📊 기술 정보

   - **Flutter**: 3.9.2+
   - **Firebase**: ✅ 완전 통합
   - **빌드 번호**: 9330
   - **패키지명**: com.example.qrchatapp

   ---

   ## 🔗 관련 링크

   - **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67
   - **스티커 관리자**: [웹 관리 도구](https://8080-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai)
   - **소스 코드**: [GitHub Repository](https://github.com/Stevewon/qrchat)

   ---

   ## 📝 커밋 히스토리

   ```
   106ec3b - UI: 채팅 목록 스와이프 배경색 변경
   172a2bf - Fix: 스티커 삭제 기능 완전 수정
   8176111 - Add: Firebase 연결 테스트 페이지
   1b52f20 - Fix: 스티커 삭제 로직 개선
   ```

   ---

   **Happy Chatting! 💬✨**
   ```

6. **APK 파일 업로드**
   - "Attach binaries" 섹션에서 `QRChat-v9.33.0.apk` 파일 드래그 앤 드롭
   - 또는 "Choose files" 클릭하여 선택

7. **"Publish release" 클릭**

---

### 방법 2: GitHub CLI 사용

```bash
# GitHub CLI 설치 필요 (https://cli.github.com/)

# 릴리즈 생성 및 파일 업로드
gh release create v9.33.0 \
  --title "🎉 QRChat v9.33.0 - 스티커 삭제 수정 및 UI 개선" \
  --notes-file RELEASE_NOTES_v9.33.0.md \
  QRChat-v9.33.0.apk
```

---

## ✅ 릴리즈 생성 완료 후

릴리즈가 생성되면 다음 URL로 접근 가능:
- **릴리즈 페이지**: https://github.com/Stevewon/qrchat/releases/tag/v9.33.0
- **최신 릴리즈**: https://github.com/Stevewon/qrchat/releases/latest
- **직접 APK 다운로드**: https://github.com/Stevewon/qrchat/releases/download/v9.33.0/QRChat-v9.33.0.apk

---

## 📱 사용자 다운로드 방법

릴리즈 생성 후 사용자에게 다음 링크 제공:

```
📥 QRChat v9.33.0 다운로드

🔗 다운로드 페이지:
https://github.com/Stevewon/qrchat/releases/tag/v9.33.0

📱 직접 다운로드:
https://github.com/Stevewon/qrchat/releases/download/v9.33.0/QRChat-v9.33.0.apk
```

---

## 🎯 체크리스트

- [x] Git 태그 생성 (v9.33.0) ✅
- [x] 코드 푸시 완료 ✅
- [ ] APK 빌드 (로컬에서 수행 필요)
- [ ] GitHub Releases 페이지 생성
- [ ] APK 파일 업로드
- [ ] 릴리즈 노트 작성
- [ ] Publish release

---

**현재 상태**: Git 태그는 생성되었으며, 로컬에서 APK 빌드 후 GitHub Releases에 업로드만 하면 됩니다!
