# 🎉 QRChat v9.33.0 Release Notes

**Release Date**: 2026-02-12  
**Build Number**: 9330

---

## 🆕 **새로운 기능 및 개선 사항**

### ✅ **스티커 삭제 기능 완전 수정**
- ✨ 스티커 관리자에서 삭제가 제대로 작동하지 않던 문제 해결
- 🔧 Storage 경로 자동 추출 기능 추가
- 🛡️ undefined 경로 처리 및 에러 핸들링 개선
- 📝 Firestore 우선 업데이트 로직으로 데이터 일관성 보장

### 🎨 **UI 개선**
- 💚 채팅 목록 스와이프 배경색 변경
  - 이전: 진한 빨간색 (너무 자극적)
  - 변경: 연한 연두색 (부드럽고 편안함)
- 👆 채팅방 나가기 제스처 시각적 피드백 개선

---

## 🐛 **버그 수정**

### 스티커 관리자 (web_admin/index.html)
1. **삭제 기능 수정**
   - ❌ 문제: 스티커 삭제 시 Storage 경로가 undefined로 전달됨
   - ✅ 해결: URL에서 Storage 경로 자동 추출
   - ✅ 해결: 경로 없을 때 안전 처리 (Firestore만 업데이트)

2. **데이터 일관성 개선**
   - Storage 삭제 전에 Firestore 먼저 업데이트
   - 업데이트 후 즉시 검증 로직 추가
   - Storage 실패해도 앱에서는 정상 동작

### 채팅 목록 (chat_list_screen.dart)
1. **스와이프 배경색 개선**
   - 사용자 경험 향상을 위한 색상 변경
   - 더 부드럽고 덜 자극적인 디자인

---

## 🔧 **기술적 개선**

### Firebase Storage 경로 처리
```javascript
// URL에서 경로 자동 추출
const url = new URL(sticker.sticker_url);
const pathMatch = url.pathname.match(/\/o\/(.+?)(\?|$)/);
storagePath = decodeURIComponent(pathMatch[1]);
```

### 에러 핸들링 강화
- undefined/null/empty 경로 안전 처리
- Storage 삭제 실패 시 경고만 표시 (앱 계속 작동)
- 상세한 디버깅 로그 추가

---

## 📊 **커밋 히스토리**

```
106ec3b - UI: 채팅 목록 스와이프 배경색 변경 (진한 빨강 → 연한 연두색)
172a2bf - Fix: 스티커 삭제 기능 완전 수정 - Storage 경로 URL 자동 추출 및 undefined 처리
8176111 - Add: Firebase 연결 및 권한 테스트 페이지
1b52f20 - Fix: 스티커 삭제 로직 개선 - Firestore 우선 업데이트 및 검증 추가
```

---

## 📱 **다운로드**

### APK 파일
현재 sandbox 환경에서는 Flutter 빌드가 불가능하므로, 로컬 환경에서 빌드해주세요:

```bash
# 1. 저장소 클론
git clone https://github.com/Stevewon/qrchat.git
cd qrchat

# 2. 최신 코드 가져오기
git pull origin main

# 3. 의존성 설치
flutter pub get

# 4. APK 빌드
flutter build apk --release

# 5. APK 위치
build/app/outputs/flutter-apk/app-release.apk
```

### 또는 GitHub Releases에서 다운로드
- **GitHub Releases**: https://github.com/Stevewon/qrchat/releases
- **최신 버전**: v9.33.0 (빌드 후 업로드 필요)

---

## 🧪 **테스트 가이드**

### 1. 스티커 삭제 기능 테스트
1. 스티커 관리자 페이지 접속
2. F12 개발자 도구 열기
3. 스티커 삭제 버튼 클릭
4. 콘솔에서 삭제 프로세스 확인:
   ```
   🔴 DELETE STARTED
   📄 Fetching Firestore document...
   ✅ Document fetched
   📝 Updating Firestore document...
   ✅ Document updated successfully
   ✅ DELETE COMPLETED
   ```
5. 페이지 새로고침 → 삭제된 스티커 확인

### 2. 채팅 목록 UI 테스트
1. QRChat 앱 실행
2. 채팅 목록 화면으로 이동
3. 채팅방을 왼쪽에서 오른쪽으로 스와이프
4. 연한 연두색 배경 확인 ✅

---

## 🔗 **링크**

- **GitHub Repository**: https://github.com/Stevewon/qrchat
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67
- **스티커 관리자**: https://8080-{sandbox-id}.sandbox.novita.ai

---

## 👨‍💻 **개발자 노트**

이번 릴리즈는 주로 버그 수정과 사용자 경험 개선에 중점을 두었습니다. 
스티커 삭제 기능의 완전한 수정으로 관리자 페이지가 더욱 안정적으로 작동합니다.

---

**Happy Chatting! 💬✨**
