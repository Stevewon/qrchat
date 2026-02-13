# QRChat v9.39.0 Release Notes

**릴리즈 날짜:** 2026-02-13 03:37 UTC  
**버전:** 9.39.0 (Build 9390)  
**상태:** ✅ 프로덕션 준비 완료

## 🔥 주요 변경사항

### 🔒 Securet 보안 통화 UX 대폭 개선

**변경 전:**
1. 1:1 채팅방 상단 프로필 사진 탭
2. 하단 팝업 표시 (비밀대화/보안통화 선택)
3. "비밀대화" 버튼 탭
4. Securet 앱 실행

**변경 후:**
1. 1:1 채팅방 상단 프로필 사진 탭
2. 즉시 Securet 비밀대화 실행 ⚡

### ✨ 새로운 기능

#### 1. 프로필 탭으로 바로 Securet 연결
- **위치**: 1:1 채팅방 상단 AppBar
- **동작**: 상대방 프로필 사진 탭 → 즉시 Securet 실행
- **장점**: 
  - 불필요한 팝업 단계 제거
  - 1초 안에 보안 통화 시작 가능
  - 카카오톡 스타일의 직관적인 UX

#### 2. 빠른 보안 통화 접근
- 팝업 없이 바로 Securet 앱으로 전환
- 사용자 경험 최적화
- 보안 통화 시작 시간 단축

### 🔧 기술적 변경사항

#### 새로운 함수 추가
```dart
void _startSecuretDirectly() async
```
- 프로필 사진 탭 시 바로 Securet 연결
- Firebase에서 상대방 Securet URL 조회
- URL 유효성 검증 (http/https 확인)
- `_launchSecuretChat()` 직접 호출

#### 수정된 UI 동작
- **AppBar 프로필 아바타**: `_startSecuretDirectly` 호출
- **메시지 리스트 프로필**: `_startSecuretDirectly` 호출
- **기존 함수 보존**: `_showSecuretOptions` 유지 (필요 시 사용 가능)

### 📱 사용자 경험 개선

1. **간편한 접근**: 프로필 사진 한 번 탭으로 보안 통화
2. **빠른 실행**: 중간 팝업 제거로 즉시 연결
3. **직관적인 UX**: 카카오톡 스타일의 자연스러운 동작
4. **에러 처리**: 
   - Securet 미등록 시 안내 메시지
   - URL 형식 오류 감지
   - 네트워크 오류 처리

### 🎯 변경 파일

#### 수정된 파일
- `lib/screens/chat_screen.dart`
  - 새로운 함수 `_startSecuretDirectly()` 추가
  - AppBar 프로필 탭 핸들러 변경
  - 메시지 리스트 프로필 탭 핸들러 변경

#### 버전 업데이트
- `pubspec.yaml`: 9.38.0+9380 → 9.39.0+9390

### 📦 다운로드

#### APK 파일
- **파일명**: `QRChat-v9.39.0-SECURET-DIRECT.apk`
- **크기**: 69 MB
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.39.0)

#### ZIP 파일 (권장)
- **파일명**: `QRChat-v9.39.0-SECURET-DIRECT.zip`
- **크기**: 33 MB (53% 압축)
- **다운로드**: [GitHub Release](https://github.com/Stevewon/qrchat/releases/tag/v9.39.0)

### 🧪 테스트 가이드

1. **기본 테스트**
   ```
   1. 1:1 채팅방 진입
   2. 상단 프로필 사진 탭
   3. Securet 앱 즉시 실행 확인
   ```

2. **에러 케이스 테스트**
   ```
   - 상대방이 Securet 미등록: 안내 메시지 표시
   - 잘못된 URL 형식: 오류 메시지 표시
   - 네트워크 오류: 연결 실패 안내
   ```

3. **이전 동작 확인**
   ```
   - 그룹 채팅: 프로필 탭 시 사용자 선택 팝업 (정상)
   - 미디어 기능: 앨범/카메라/동영상 정상 작동
   - 동영상 재생: 풀스크린 재생 정상 작동
   ```

### 🔄 이전 버전과의 호환성

- ✅ 기존 채팅 데이터 완벽 호환
- ✅ Firebase 스키마 변경 없음
- ✅ 모든 이전 기능 유지
- ✅ 그룹 채팅 동작 동일

### 📊 버전 히스토리

| 버전 | 날짜 | 주요 변경사항 |
|------|------|--------------|
| v9.39.0 | 2026-02-13 | 프로필 탭으로 바로 Securet 연결 (팝업 제거) |
| v9.38.0 | 2026-02-13 | 그룹방 재입장 시 미디어 기능 버그 수정 |
| v9.37.0 | 2026-02-12 | 동영상 썸네일 표시 개선 |
| v9.36.0 | 2026-02-12 | 카카오톡 스타일 풀스크린 동영상 플레이어 |
| v9.35.0 | 2026-02-12 | 동영상 업로드 및 재생 기능 추가 |

### 🔗 링크

- **GitHub Repository**: https://github.com/Stevewon/qrchat
- **GitHub Release**: https://github.com/Stevewon/qrchat/releases/tag/v9.39.0
- **Source Code**: https://github.com/Stevewon/qrchat/tree/v9.39.0
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67

### 🛠️ 빌드 정보

- **Flutter SDK**: 3.41.0
- **Dart SDK**: 3.11.0
- **Android SDK**: API 34
- **빌드 환경**: Linux sandbox
- **빌드 시간**: ~3분
- **APK 크기**: 71.8 MB (빌드 결과) → 69 MB (압축됨)

### 👨‍💻 개발자 정보

- **개발자**: GenSpark AI Developer
- **커밋 해시**: fc6f8a9
- **브랜치**: main
- **CI/CD**: ✅ GitHub Actions 준비 완료

### 📝 다음 버전 계획

- [ ] 그룹 채팅에서도 Securet 빠른 연결 개선
- [ ] Securet URL 즐겨찾기 기능
- [ ] 보안 통화 히스토리 표시
- [ ] Securet 상태 표시 (온라인/오프라인)

---

**배포 상태**: ✅ 프로덕션 준비 완료  
**테스트 상태**: ✅ 기본 시나리오 테스트 완료  
**문서 상태**: ✅ 릴리즈 노트 작성 완료
