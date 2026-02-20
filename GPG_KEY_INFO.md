# 🔑 QRChat Desktop GPG 서명 키 정보

## ✅ 생성 완료 (2026-02-19)

### 📋 키 정보

```
키 ID (긴 형식): 3E5C759D70848749
지문: D534FD45AD8BD6E7C7E19F973E5C759D70848749
이름: QRChat Desktop
이메일: hocu00987@gmail.com
설명: QRChat Linux signing key
알고리즘: RSA 4096-bit
유효기간: 2028-02-19 (2년)
생성일: 2026-02-19
```

---

## 📁 생성된 파일

| 파일 | 설명 | 위치 |
|------|------|------|
| `qrchat_gpg_public.key` | 공개키 (배포용) | `/home/user/qrchat_desktop/` |
| 비밀키 | GPG 키링에 저장 | `~/.gnupg/` |
| 폐기 인증서 | 긴급 폐기용 | `~/.gnupg/openpgp-revocs.d/` |

---

## 🚀 사용 방법

### 1️⃣ 파일 서명하기

```bash
# .deb 패키지 서명
gpg --detach-sign --armor package.deb

# AppImage 서명
gpg --detach-sign --armor QRChat.AppImage

# .tar.gz 서명
gpg --detach-sign --armor qrchat-1.0.0.tar.gz
```

서명 파일: `파일명.asc` 또는 `파일명.sig`

---

### 2️⃣ 서명 검증하기

```bash
gpg --verify 파일명.asc 파일명
```

---

### 3️⃣ 공개키 배포

**방법 1: 웹사이트에 업로드**
```bash
# qrchat.io/gpg-key.asc 에 업로드
cp qrchat_gpg_public.key /path/to/website/gpg-key.asc
```

**방법 2: 키서버에 업로드**
```bash
gpg --keyserver keyserver.ubuntu.com --send-keys 3E5C759D70848749
gpg --keyserver keys.openpgp.org --send-keys 3E5C759D70848749
```

**방법 3: README에 추가**
```markdown
## Verify Downloads

Download our GPG public key:
```bash
wget https://qrchat.io/gpg-key.asc
gpg --import gpg-key.asc
```

Verify signature:
```bash
gpg --verify QRChat-1.0.0.deb.asc QRChat-1.0.0.deb
```
```

---

### 4️⃣ 사용자에게 검증 안내

**README.md에 추가할 내용:**

```markdown
## 🔐 Download Verification

All QRChat Desktop releases are GPG-signed for security.

### Import Public Key
```bash
curl https://qrchat.io/gpg-key.asc | gpg --import
```

### Verify Package
```bash
# Debian/Ubuntu
gpg --verify qrchat-desktop_1.0.0_amd64.deb.asc

# AppImage
gpg --verify QRChat-Desktop-1.0.0-x86_64.AppImage.asc
```

**Expected output:**
```
gpg: Good signature from "QRChat Desktop <hocu00987@gmail.com>"
```

### Key Details
- Key ID: `3E5C759D70848749`
- Fingerprint: `D534 FD45 AD8B D6E7 C7E1  9F97 3E5C 759D 7084 8749`
```

---

## 💾 백업하기

### 공개키 백업 (배포용)
```bash
gpg --armor --export hocu00987@gmail.com > qrchat_public.key
```

### 비밀키 백업 (안전한 곳에 보관!)
```bash
gpg --armor --export-secret-keys hocu00987@gmail.com > qrchat_private.key.asc
```

⚠️ **중요:** 비밀키는 절대 공개하지 말 것! 안전한 곳에만 보관!

---

## 🔄 다른 컴퓨터에서 사용하기

### 비밀키 가져오기
```bash
gpg --import qrchat_private.key.asc
gpg --edit-key hocu00987@gmail.com
> trust
> 5 (최종 신뢰)
> quit
```

---

## 🗑️ 키 폐기 (긴급시)

```bash
# 폐기 인증서 가져오기
gpg --import ~/.gnupg/openpgp-revocs.d/D534FD45AD8BD6E7C7E19F973E5C759D70848749.rev

# 키서버에 폐기 알림
gpg --keyserver keyserver.ubuntu.com --send-keys 3E5C759D70848749
```

---

## 📊 테스트 결과

✅ 키 생성: 성공  
✅ 파일 서명: 성공 (test_file.txt)  
✅ 서명 검증: 성공 ("Good signature")  

---

## 🎯 다음 단계

1. ✅ GPG 키 생성 완료
2. ⏭️ 실제 .deb, AppImage 빌드 파일 서명
3. ⏭️ 공개키를 qrchat.io에 업로드
4. ⏭️ README에 검증 방법 추가
5. ⏭️ GitHub Release에 서명 파일 첨부

---

**생성일:** 2026-02-19  
**만료일:** 2028-02-19  
**상태:** ✅ 활성  
**비용:** 무료!  
