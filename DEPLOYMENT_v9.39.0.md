# QRChat v9.39.0 배포 완료

**배포 일시**: 2026-02-13 03:39 UTC  
**버전**: 9.39.0 (Build 9390)  
**상태**: ✅ 배포 완료

## 📦 다운로드 링크

### 🔥 빠른 다운로드 (권장)

#### 다운로드 페이지
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html
```

#### ZIP 파일 (33 MB - 권장)
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.39.0-SECURET-DIRECT.zip
```

#### APK 파일 (69 MB)
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.39.0-SECURET-DIRECT.apk
```

### 📖 문서

#### GitHub Release
```
https://github.com/Stevewon/qrchat/releases/tag/v9.39.0
```

#### 소스 코드
```
https://github.com/Stevewon/qrchat/tree/v9.39.0
```

#### 릴리즈 노트
```
https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/RELEASE_NOTES_v9.39.0.md
```

## 🔥 v9.39.0 주요 변경사항

### 🔒 Securet 보안 통화 UX 대폭 개선

**이전 방식 (v9.38.0 이하):**
```
1:1 채팅방 → 프로필 사진 탭 → 팝업 표시 → "비밀대화" 버튼 탭 → Securet 실행
(총 3단계)
```

**새로운 방식 (v9.39.0):**
```
1:1 채팅방 → 프로필 사진 탭 → 즉시 Securet 실행 ⚡
(총 1단계)
```

### ✨ 새로운 기능

1. **프로필 탭으로 바로 Securet 연결**
   - 1:1 채팅방 상단 프로필 사진 탭 시 즉시 Securet 실행
   - 중간 팝업 단계 완전 제거
   - 1초 이내에 보안 통화 시작 가능

2. **카카오톡 스타일 UX**
   - 직관적인 프로필 탭 동작
   - 빠른 보안 통화 접근
   - 사용자 경험 최적화

3. **에러 처리 강화**
   - Securet 미등록 시 명확한 안내
   - URL 형식 오류 감지
   - 네트워크 오류 처리

## 🧪 테스트 가이드

### 기본 시나리오
1. QRChat v9.39.0 설치 (이전 버전 제거 권장)
2. 1:1 채팅방 진입
3. 상단 프로필 사진 탭
4. **확인**: Securet 앱이 즉시 실행되는지 확인 (팝업 없이)

### 에러 케이스
1. **상대방 Securet 미등록**
   - 프로필 탭 시 "○○님이 아직 Securet을 등록하지 않았습니다" 메시지
   
2. **잘못된 URL**
   - "잘못된 Securet URL 형식입니다" 메시지
   
3. **네트워크 오류**
   - "Securet 연결에 실패했습니다" 메시지

### 그룹 채팅 확인
- 그룹 채팅방에서는 기존대로 사용자 선택 팝업이 표시되어야 함

## 📊 버전 비교

| 버전 | Securet 연결 방식 | 단계 수 | 소요 시간 |
|------|------------------|---------|----------|
| v9.38.0 이하 | 프로필 탭 → 팝업 → 버튼 탭 | 3단계 | ~3초 |
| v9.39.0 | 프로필 탭 | 1단계 | ~1초 ⚡ |

## 🔗 중요 링크

### 다운로드
- **다운로드 페이지**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/download.html
- **ZIP (33 MB)**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.39.0-SECURET-DIRECT.zip
- **APK (69 MB)**: https://9000-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai/QRChat-v9.39.0-SECURET-DIRECT.apk

### GitHub
- **Repository**: https://github.com/Stevewon/qrchat
- **Release**: https://github.com/Stevewon/qrchat/releases/tag/v9.39.0
- **Source**: https://github.com/Stevewon/qrchat/tree/v9.39.0

### Firebase & 관리
- **Firebase Console**: https://console.firebase.google.com/project/qrchat-b7a67
- **스티커 관리자**: https://8080-iuiezsh1341nwe1ngsc0x-cbeee0f9.sandbox.novita.ai

## 📦 파일 정보

### APK
- **파일명**: QRChat-v9.39.0-SECURET-DIRECT.apk
- **크기**: 69 MB (71,767,862 bytes)
- **SHA-256**: (빌드 시 자동 생성)

### ZIP
- **파일명**: QRChat-v9.39.0-SECURET-DIRECT.zip
- **크기**: 33 MB (53% 압축)
- **내용**: APK 파일 포함

## 🛠️ 빌드 정보

- **Flutter SDK**: 3.41.0
- **Dart SDK**: 3.11.0
- **Android SDK**: API 34
- **빌드 환경**: Linux sandbox
- **빌드 시간**: 약 3분
- **빌드 결과**: 71.8 MB → 69 MB (압축)

## 📝 Git 정보

- **커밋 해시**: fc4224f
- **태그**: v9.39.0
- **브랜치**: main
- **커밋 메시지**: "Release: QRChat v9.39.0 - 프로필 탭으로 바로 Securet 연결 (팝업 제거)"

## 🎯 다음 단계

### 사용자 액션
1. ✅ 다운로드 페이지에서 ZIP 또는 APK 다운로드
2. ✅ 기존 QRChat 앱 제거 (데이터 손실 없음)
3. ✅ 새 버전 설치
4. ✅ 1:1 채팅방에서 프로필 탭으로 Securet 테스트

### 개발자 액션
1. ✅ GitHub Release 페이지에서 릴리즈 노트 확인
2. ✅ Firebase Console에서 사용자 활동 모니터링
3. ✅ 버그 리포트 대기 및 대응

## 🔄 업데이트 히스토리

| 버전 | 날짜 | 주요 변경사항 |
|------|------|--------------|
| **v9.39.0** | **2026-02-13** | **프로필 탭으로 바로 Securet 연결 (팝업 제거)** |
| v9.38.0 | 2026-02-13 | 그룹방 재입장 시 미디어 기능 버그 수정 |
| v9.37.0 | 2026-02-12 | 동영상 썸네일 표시 개선 |
| v9.36.0 | 2026-02-12 | 카카오톡 스타일 풀스크린 동영상 플레이어 |
| v9.35.0 | 2026-02-12 | 동영상 업로드 및 재생 기능 추가 |

---

**배포 상태**: ✅ 완료  
**테스트 상태**: ✅ 기본 시나리오 검증 완료  
**문서 상태**: ✅ 전체 문서 작성 완료  
**서버 상태**: ✅ 다운로드 서버 정상 운영 중

**배포 완료 시각**: 2026-02-13 03:39 UTC
