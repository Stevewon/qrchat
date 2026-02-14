# 🔧 QRChat 스티커팩 통합 가이드

## 📋 사전 준비

### 1️⃣ Firebase 서비스 계정 키 다운로드

**Firebase Console 접속:**
🔗 https://console.firebase.google.com/project/qrchat-b7a67/settings/serviceaccounts/adminsdk

**다운로드 절차:**
1. 위 링크 클릭
2. "Firebase Admin SDK" 탭 선택
3. "새 비공개 키 생성" 버튼 클릭
4. JSON 파일 다운로드
5. 파일명을 `firebase-service-account.json`으로 변경
6. `/home/user/webapp/` 폴더에 업로드

---

## 🚀 스크립트 실행 방법

### 방법 1: 서비스 계정 키 사용 (권장)

```bash
# 1. 서비스 계정 키 파일 확인
cd /home/user/webapp
ls -la firebase-service-account.json

# 2. Firebase Admin SDK 설치
npm install firebase-admin

# 3. 스크립트 실행
node merge_sticker_packs.js
```

### 방법 2: Firebase CLI 사용 (대안)

```bash
# 1. Firebase CLI로 로그인
cd /home/user/webapp
firebase login

# 2. Firebase Admin SDK 설치
npm install firebase-admin

# 3. 스크립트 실행
GOOGLE_APPLICATION_CREDENTIALS=firebase-service-account.json node merge_sticker_packs.js
```

---

## 📊 스크립트 실행 결과 예시

```
🔧 QRChat 스티커팩 통합 스크립트 시작...

✅ Firebase Admin SDK 초기화 완료 (서비스 계정 키)

📦 스티커팩 컬렉션 조회 중...

✅ 총 2개의 스티커팩 발견

📌 "명청이" 팩 발견:
   - ID: meongceongi_26414
   - 스티커 개수: 6개

📌 "명청이" 팩 발견:
   - ID: meongceongi_35385
   - 스티커 개수: 5개

🔀 2개의 "명청이" 팩 통합 시작...

   팩 1 (meongceongi_26414): 6개 스티커 추가
   팩 2 (meongceongi_35385): 5개 스티커 추가

✅ 총 11개의 스티커 수집 완료

📝 메인 팩 업데이트 중... (ID: meongceongi_26414)
✅ 메인 팩 업데이트 완료

🗑️  중복 팩 삭제 중...

   - 삭제 중: meongceongi_35385 (5개 스티커)
   ✅ 삭제 완료: meongceongi_35385

============================================================
🎉 스티커팩 통합 완료!

📊 최종 결과:
   - 팩 이름: 명청이
   - 팩 ID: meongceongi_26414
   - 총 스티커: 11개
   - 삭제된 팩: 1개
============================================================

💡 앱에서 확인:
   1. QRChat 앱 실행
   2. 채팅방에서 스티커 아이콘 클릭
   3. "명청이" 탭 하나만 있는지 확인
   4. 11개의 스티커가 모두 표시되는지 확인

✅ 스크립트 실행 완료
```

---

## ⚠️ 문제 해결

### 오류: "Firebase 초기화 실패"
→ 서비스 계정 키 파일이 없거나 경로가 잘못됨
→ `firebase-service-account.json` 파일을 확인하세요

### 오류: "스티커팩이 없습니다"
→ Firestore에 `sticker_packs` 컬렉션이 없거나 비어 있음
→ Firebase Console에서 데이터를 확인하세요

### 오류: "권한이 거부되었습니다"
→ 서비스 계정에 Firestore 쓰기 권한이 없음
→ Firebase Console에서 권한을 확인하세요

---

## 🔗 관련 링크

- **Firebase Console (서비스 계정):** https://console.firebase.google.com/project/qrchat-b7a67/settings/serviceaccounts/adminsdk
- **Firestore Database:** https://console.firebase.google.com/project/qrchat-b7a67/firestore
- **스티커팩 컬렉션:** https://console.firebase.google.com/project/qrchat-b7a67/firestore/data/~2Fsticker_packs

---

## 📱 실행 후 확인

1. ✅ Firebase Console에서 `sticker_packs` 컬렉션 확인
2. ✅ "명청이" 팩이 1개만 있는지 확인
3. ✅ 스티커가 11개 있는지 확인
4. ✅ QRChat 앱에서 스티커 탭 확인
