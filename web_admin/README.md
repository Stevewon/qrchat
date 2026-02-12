# 🎨 QRChat 스티커 관리자 웹 페이지

Firebase Storage와 Firestore에 직접 연결하여 스티커를 업로드하고 관리할 수 있는 웹 기반 관리자 페이지입니다.

## 🌐 접속 방법

### 옵션 1: 로컬에서 실행
```bash
# 웹 서버 실행 (Python)
cd web_admin
python3 -m http.server 8000

# 브라우저에서 접속
# http://localhost:8000
```

### 옵션 2: GitHub Pages로 배포
1. GitHub 저장소의 Settings → Pages
2. Source를 `main` 브랜치의 `/web_admin` 폴더로 설정
3. 배포된 URL로 접속

### 옵션 3: 직접 파일 열기
```bash
# 브라우저에서 index.html 파일을 직접 엽니다
open web_admin/index.html  # macOS
start web_admin/index.html # Windows
xdg-open web_admin/index.html # Linux
```

## ✨ 주요 기능

### 📤 스티커 업로드
- **드래그 앤 드롭**: 파일을 드래그하여 업로드
- **클릭 업로드**: 업로드 영역을 클릭하여 파일 선택
- **다중 파일 지원**: 여러 파일을 한 번에 업로드
- **미리보기**: 업로드 전 이미지 미리보기
- **자동 저장**: Firebase Storage + Firestore에 자동 저장

### 🗑️ 스티커 삭제
- **개별 삭제**: 각 스티커를 개별적으로 삭제
- **Storage + Firestore 동시 삭제**: 이미지 파일과 메타데이터 모두 삭제
- **확인 메시지**: 삭제 전 확인 대화상자 표시

### 🖼️ 스티커 목록 보기
- **그리드 뷰**: 모든 스티커를 카드 형식으로 표시
- **스티커팩 정보**: 각 스티커의 팩 이름 표시
- **실시간 새로고침**: 새로고침 버튼으로 최신 데이터 로드
- **반응형 디자인**: PC/모바일 모두 지원

## 📋 사용 방법

### 1. 스티커 업로드

1. **파일 선택**
   - 업로드 영역을 클릭하거나 파일을 드래그
   - GIF, PNG, WebP 파일 선택 (여러 개 가능)

2. **정보 입력**
   - **스티커팩 이름**: 사용자에게 표시될 이름 (예: "고양이 감정팩")
   - **스티커팩 ID**: 고유 식별자 (예: "cat_emotions_pack")

3. **업로드**
   - "업로드" 버튼 클릭
   - 업로드 완료 시 성공 메시지 표시
   - 자동으로 스티커 목록 새로고침

### 2. 스티커 삭제

1. 삭제하려는 스티커 카드에서 "삭제" 버튼 클릭
2. 확인 대화상자에서 "확인" 클릭
3. Firebase Storage와 Firestore에서 모두 삭제됨

### 3. 스티커 목록 새로고침

- "새로고침" 버튼을 클릭하여 최신 스티커 목록 로드

## 🔧 기술 스택

- **Frontend**: HTML, CSS, JavaScript (Vanilla)
- **Backend**: Firebase
  - Firebase Storage (이미지 저장)
  - Cloud Firestore (메타데이터 저장)
- **Firebase SDK**: v10.7.1 (ES Modules)

## 🔐 보안 설정

현재는 Firebase의 기본 보안 규칙을 사용합니다.
프로덕션 환경에서는 다음과 같은 보안 규칙을 설정하세요:

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /sticker_packs/{packId} {
      allow read: if true;  // 모든 사용자 읽기 가능
      allow write: if request.auth != null;  // 인증된 사용자만 쓰기
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /stickers/{allPaths=**} {
      allow read: if true;  // 모든 사용자 읽기 가능
      allow write: if request.auth != null;  // 인증된 사용자만 쓰기
    }
  }
}
```

## 📱 모바일 앱과의 연동

이 웹 관리자에서 업로드한 스티커는 QRChat 모바일 앱에서 자동으로 사용됩니다.

**Firestore 구조**:
```json
{
  "sticker_packs": {
    "document_id": {
      "pack_name": "고양이 감정팩",
      "pack_id": "cat_emotions_pack",
      "created_at": "2026-02-12T11:30:00Z",
      "stickers": [
        {
          "sticker_name": "happy_cat",
          "sticker_url": "https://...",
          "sticker_path": "stickers/cat_emotions_pack/..."
        }
      ]
    }
  }
}
```

## 🐛 문제 해결

### CORS 오류
- 로컬에서 파일을 직접 열면 CORS 오류가 발생할 수 있습니다
- 해결: 로컬 웹 서버를 사용하거나 GitHub Pages로 배포

### Firebase 연결 실패
- Firebase 프로젝트 설정 확인
- API Key와 Project ID가 올바른지 확인
- 브라우저 콘솔(F12)에서 오류 메시지 확인

### 업로드 실패
- 파일 크기 확인 (500KB 이하 권장)
- 파일 형식 확인 (GIF, PNG, WebP만 지원)
- Firebase Storage 권한 확인

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. 브라우저 콘솔(F12)의 오류 메시지
2. Firebase Console의 로그
3. 네트워크 탭에서 요청/응답 확인

---

**QRChat 스티커 관리자** - 간편한 웹 기반 스티커 관리 도구 🎨
