# 🚀 qrchat.io 웹사이트 GitHub Pages 배포 - 2단계

## ✅ **1단계 완료!**
- ✅ `gh-pages` 브랜치 생성 완료
- ✅ 웹사이트 파일 업로드 완료
- ✅ GitHub에 푸시 완료

---

## 📋 **2단계: GitHub Pages 활성화**

### 1️⃣ **GitHub 저장소 Settings로 이동**
1. 브라우저에서 접속: https://github.com/Stevewon/qrchat/settings/pages
2. 또는:
   - GitHub 저장소: https://github.com/Stevewon/qrchat
   - 클릭: **Settings** 탭
   - 왼쪽 메뉴에서: **Pages** 클릭

### 2️⃣ **GitHub Pages 설정**
**Source (소스) 설정:**
- **Branch**: `gh-pages` 선택
- **Folder**: `/ (root)` 선택
- **Save** 버튼 클릭

### 3️⃣ **Custom Domain (커스텀 도메인) 설정**
**Custom domain 섹션:**
- 입력란에: `qrchat.io` 입력
- **Save** 버튼 클릭
- ⏳ DNS 확인 완료까지 대기 (몇 분 소요)

### 4️⃣ **HTTPS 설정**
- ✅ **Enforce HTTPS** 체크박스 활성화
  - (DNS 전파 후 자동으로 활성화됩니다)

---

## 🌐 **3단계: DNS 설정 (도메인 등록기관에서)**

### A 레코드 추가 (GitHub Pages IP)
qrchat.io 도메인에 다음 4개의 A 레코드 추가:

```
Type: A
Name: @
Value: 185.199.108.153
TTL: 3600 (or Auto)

Type: A
Name: @
Value: 185.199.109.153
TTL: 3600

Type: A
Name: @
Value: 185.199.110.153
TTL: 3600

Type: A
Name: @
Value: 185.199.111.153
TTL: 3600
```

### CNAME 레코드 추가 (www 리디렉션)
```
Type: CNAME
Name: www
Value: stevewon.github.io.
TTL: 3600
```

### ⚠️ **중요 참고사항**
1. **도메인 등록기관**: 가비아, Cloudflare, 또는 현재 qrchat.io를 관리하는 곳
2. **DNS 전파 시간**: 보통 **5분~48시간** 소요 (평균 1~2시간)
3. **기존 레코드 삭제**: 
   - qrchat.io의 기존 A 레코드가 있다면 모두 삭제
   - 위의 GitHub Pages IP로 교체

---

## 📊 **4단계: 배포 확인**

### DNS 전파 확인 (5분~2시간 후)
```bash
# Windows (CMD/PowerShell)
nslookup qrchat.io

# Linux/Mac
dig qrchat.io +short
```

**올바른 결과 예시:**
```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

### 웹사이트 접속 확인
1. https://qrchat.io - 메인 도메인
2. https://www.qrchat.io - www 서브도메인
3. https://stevewon.github.io/qrchat/ - GitHub Pages 기본 URL

---

## ✅ **전체 체크리스트**

### GitHub Pages 설정
- [ ] GitHub Settings → Pages 이동
- [ ] Source: `gh-pages` 브랜치 선택
- [ ] Custom domain: `qrchat.io` 입력 및 저장
- [ ] Enforce HTTPS 활성화 (DNS 전파 후)

### DNS 설정
- [ ] A 레코드 4개 추가 (GitHub Pages IP)
- [ ] CNAME 레코드 추가 (www → stevewon.github.io)
- [ ] 기존 qrchat.io A 레코드 삭제 (있는 경우)

### 배포 확인
- [ ] DNS 전파 확인 (`nslookup` 또는 `dig`)
- [ ] https://qrchat.io 접속 확인
- [ ] https://www.qrchat.io 접속 확인
- [ ] HTTPS 작동 확인 (자물쇠 아이콘)

---

## 🎯 **다음 단계**

### 웹사이트 업데이트 시
```bash
# gh-pages 브랜치로 이동
cd /home/user/webapp
git checkout gh-pages

# 파일 수정 후
git add .
git commit -m "Update website content"
git push origin gh-pages

# 자동으로 GitHub Pages에 배포됩니다 (1~2분 소요)
```

### 앱 스토어 링크 업데이트 (나중에)
`index.html` 파일에서:
- Google Play 링크 교체
- App Store 링크 교체
- "Coming Soon" 배지 제거

---

## 📞 **문제 해결**

### DNS 전파가 안 될 때
1. **DNS 캐시 초기화**:
   - Windows: `ipconfig /flushdns`
   - Mac: `sudo dscacheutil -flushcache`
   - Linux: `sudo systemd-resolve --flush-caches`

2. **온라인 DNS 전파 확인**:
   - https://dnschecker.org/#A/qrchat.io
   - 전 세계 DNS 서버에서 전파 상태 확인

### GitHub Pages가 404 에러
1. 브랜치 설정 재확인: `gh-pages` 브랜치, `/ (root)` 폴더
2. 파일 존재 확인: `index.html`이 root에 있는지
3. 강제 리빌드: Settings → Pages → "Re-run workflow" 또는 아무 파일 수정 후 재푸시

### HTTPS 설정이 안 될 때
1. DNS 전파가 완료될 때까지 대기 (최대 48시간)
2. GitHub Pages 설정에서 "Enforce HTTPS" 체크 해제 후 다시 체크

---

## 🎉 **완료!**

모든 단계를 완료하면:
- ✅ https://qrchat.io 에서 웹사이트 접속 가능
- ✅ HTTPS 보안 연결
- ✅ Google Play / App Store 다운로드 링크 제공
- ✅ 개인정보 처리방침 및 이용약관 페이지

**예상 완료 시간**: DNS 설정 후 1~2시간 (DNS 전파 시간 포함)
