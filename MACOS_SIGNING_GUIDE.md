# 🍎 macOS 코드 서명 - 실행 가이드

## 📋 개요
**비용**: $99/년  
**예상 시간**: 1-2일  
**난이도**: 중급  

---

## ✅ 사전 준비사항

### 필요한 것들
- [ ] Apple ID (개인/회사)
- [ ] 신용카드 ($99 결제용)
- [ ] macOS 개발 환경 (또는 GitHub Actions)
- [ ] 빌드된 QRChat.app

### 선택사항
- [ ] 사업자 등록증 (법인 계정 시)
- [ ] DUNS 번호 (법인 계정 시)

---

## 📝 단계별 가이드

### Step 1: Apple Developer Program 가입 ($99)

#### 1-1. Apple Developer 사이트 접속
```
https://developer.apple.com/programs/enroll/
```

#### 1-2. 계정 유형 선택
**개인 개발자 (Individual)**
- ✅ 빠른 승인 (1-2일)
- ✅ 간단한 절차
- ✅ 신분증만 필요
- ❌ 법인 이름 불가

**조직 개발자 (Organization)**
- ✅ 회사 이름으로 등록
- ✅ 팀 관리 가능
- ❌ 승인 오래 걸림 (1-2주)
- ❌ 사업자 등록증 필요

**권장**: 개인으로 시작 → 나중에 조직으로 전환 가능

#### 1-3. 등록 절차
```
1. Apple ID로 로그인
2. "Enroll" 버튼 클릭
3. 개인정보 입력:
   - 법적 이름 (Legal Name)
   - 주소
   - 전화번호
4. 약관 동의
5. 결제 ($99)
```

#### 1-4. 승인 대기
- **이메일 확인** (수분 내)
- **신원 확인** (1-2일)
- **승인 완료 알림**

**Tip**: 승인 빠르게 받으려면
- 정확한 정보 입력
- Apple ID와 동일한 이름 사용
- 이메일 즉시 확인

---

### Step 2: 개발자 인증서 생성

#### 2-1. Xcode 설치 (macOS에서)
```bash
# App Store에서 Xcode 설치
# 또는 명령줄
xcode-select --install
```

#### 2-2. Apple ID 추가
```
Xcode > Preferences (Settings) > Accounts
```

1. "+" 버튼 클릭
2. Apple ID 추가
3. "Download Manual Profiles" 클릭

#### 2-3. 인증서 생성
```
Xcode > Preferences > Accounts > [Your Apple ID]
> Manage Certificates > "+"
> "Developer ID Application"
```

**생성되는 인증서:**
- Developer ID Application (배포용)
- Apple Development (개발용)

#### 2-4. 인증서 확인
```bash
# 터미널에서 확인
security find-identity -v -p codesigning

# 출력 예시:
# 1) 1234567890ABCDEF "Developer ID Application: Your Name (TEAM_ID)"
```

**Team ID 저장**: 나중에 필요!

---

### Step 3: App-Specific Password 생성

#### 3-1. Apple ID 사이트 접속
```
https://appleid.apple.com/
```

#### 3-2. App-Specific Password 생성
```
1. 로그인
2. "Sign-In and Security" 섹션
3. "App-Specific Passwords" 클릭
4. "Generate an app-specific password"
5. 이름 입력: "QRChat Notarization"
6. 생성된 비밀번호 복사 (xxxx-xxxx-xxxx-xxxx)
```

**⚠️ 중요**: 이 비밀번호를 안전하게 저장! (다시 볼 수 없음)

---

### Step 4: 앱 서명

#### 4-1. entitlements.plist 생성
```bash
cd /home/user/qrchat_desktop/macos/Runner
cat > Release.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
EOF
```

#### 4-2. 앱 서명 스크립트
```bash
cd /home/user/qrchat_desktop

# 서명 스크립트 생성
cat > sign_macos.sh << 'EOF'
#!/bin/bash

# 설정
TEAM_ID="YOUR_TEAM_ID"  # 여기에 Team ID 입력
APP_PATH="build/macos/Build/Products/Release/qrchat.app"
IDENTITY="Developer ID Application: Your Name ($TEAM_ID)"

echo "🔐 Signing QRChat.app..."

# 앱 서명
codesign --deep --force --verify --verbose \
  --sign "$IDENTITY" \
  --options runtime \
  --entitlements macos/Runner/Release.entitlements \
  "$APP_PATH"

# 서명 확인
echo "✅ Verifying signature..."
codesign --verify --verbose "$APP_PATH"
spctl --assess --verbose "$APP_PATH"

echo "✅ macOS app signed successfully!"
EOF

chmod +x sign_macos.sh
```

#### 4-3. 실행
```bash
# Flutter 빌드
flutter build macos --release

# 서명 실행
./sign_macos.sh
```

---

### Step 5: Notarization (공증)

#### 5-1. 앱을 ZIP으로 압축
```bash
cd build/macos/Build/Products/Release
ditto -c -k --keepParent qrchat.app qrchat.zip
```

#### 5-2. Apple에 업로드
```bash
# 환경 변수 설정
export APPLE_ID="your@email.com"
export TEAM_ID="YOUR_TEAM_ID"
export APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-Specific Password

# 업로드
xcrun notarytool submit qrchat.zip \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

# 상태 확인 (Submission ID 받음)
# 출력: Submission ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 5-3. 공증 결과 확인
```bash
# Submission ID로 상태 확인
xcrun notarytool info <submission-id> \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD"

# 로그 확인 (문제 발생 시)
xcrun notarytool log <submission-id> \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD"
```

**공증 시간**: 보통 5-10분

#### 5-4. 공증 티켓 스테이플
```bash
# 앱에 공증 티켓 첨부
xcrun stapler staple qrchat.app

# 확인
xcrun stapler validate qrchat.app
spctl --assess --verbose qrchat.app
```

---

### Step 6: DMG 생성 및 서명

#### 6-1. create-dmg 설치
```bash
brew install create-dmg
```

#### 6-2. DMG 생성
```bash
cd /home/user/qrchat_desktop

cat > create_dmg.sh << 'EOF'
#!/bin/bash

APP_PATH="build/macos/Build/Products/Release/qrchat.app"
DMG_NAME="QRChat-2.0.0-macos.dmg"
IDENTITY="Developer ID Application: Your Name (YOUR_TEAM_ID)"

echo "📦 Creating DMG..."

create-dmg \
  --volname "QRChat" \
  --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "qrchat.app" 200 190 \
  --hide-extension "qrchat.app" \
  --app-drop-link 600 185 \
  "$DMG_NAME" \
  "$APP_PATH"

echo "🔐 Signing DMG..."
codesign --sign "$IDENTITY" "$DMG_NAME"

echo "✅ Verifying DMG..."
codesign --verify --verbose "$DMG_NAME"

echo "✅ DMG created and signed: $DMG_NAME"
EOF

chmod +x create_dmg.sh
./create_dmg.sh
```

---

### Step 7: GitHub Actions 통합

#### 7-1. GitHub Secrets 설정
```
GitHub Repository > Settings > Secrets and Variables > Actions
```

**추가할 Secrets:**
1. `MACOS_CERTIFICATE_BASE64`
   ```bash
   # 인증서를 Base64로 인코딩
   base64 -i DeveloperIDApplication.p12 | pbcopy
   ```

2. `MACOS_CERTIFICATE_PASSWORD`
   - 인증서 비밀번호

3. `APPLE_ID`
   - your@email.com

4. `APPLE_TEAM_ID`
   - YOUR_TEAM_ID

5. `APPLE_APP_PASSWORD`
   - xxxx-xxxx-xxxx-xxxx (App-Specific Password)

6. `KEYCHAIN_PASSWORD`
   - 임의의 강력한 비밀번호

#### 7-2. Workflow 파일 업데이트
```yaml
# .github/workflows/sign-macos.yml
name: Sign macOS Build

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  sign-macos:
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.1'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Import Certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.MACOS_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.MACOS_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security set-keychain-settings -lut 21600 build.keychain
          
          # Import certificate
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 \
            -k build.keychain \
            -P "$CERTIFICATE_PASSWORD" \
            -T /usr/bin/codesign \
            -T /usr/bin/security
          
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain
          
          # Verify
          security find-identity -v -p codesigning
      
      - name: Build macOS
        run: flutter build macos --release
      
      - name: Sign App
        env:
          TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          codesign --deep --force --verify --verbose \
            --sign "Developer ID Application" \
            --options runtime \
            --entitlements macos/Runner/Release.entitlements \
            build/macos/Build/Products/Release/qrchat.app
      
      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
          TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          cd build/macos/Build/Products/Release
          
          # Create zip
          ditto -c -k --keepParent qrchat.app qrchat.zip
          
          # Submit for notarization
          xcrun notarytool submit qrchat.zip \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APPLE_PASSWORD" \
            --wait
          
          # Staple ticket
          xcrun stapler staple qrchat.app
          xcrun stapler validate qrchat.app
      
      - name: Create DMG
        run: |
          brew install create-dmg
          
          create-dmg \
            --volname "QRChat" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --app-drop-link 600 185 \
            "QRChat-${{ github.ref_name }}-macos.dmg" \
            "build/macos/Build/Products/Release/qrchat.app"
          
          codesign --sign "Developer ID Application" \
            "QRChat-${{ github.ref_name }}-macos.dmg"
      
      - name: Upload DMG
        uses: actions/upload-artifact@v4
        with:
          name: macos-signed-dmg
          path: "*.dmg"
      
      - name: Cleanup
        if: always()
        run: |
          security delete-keychain build.keychain || true
          rm -f certificate.p12
```

---

## 🎯 테스트

### 로컬 테스트
```bash
# 1. 서명된 앱 실행
open build/macos/Build/Products/Release/qrchat.app

# 2. Gatekeeper 확인
spctl --assess --verbose build/macos/Build/Products/Release/qrchat.app

# 성공 메시지:
# source=Notarized Developer ID
# accepted
```

### 다른 Mac에서 테스트
1. DMG를 다른 Mac으로 복사
2. DMG 마운트 및 앱 설치
3. 실행 시 경고 없이 실행되는지 확인

---

## 🐛 문제 해결

### "Developer ID Application" 인증서가 없음
```bash
# Xcode에서 다시 생성
# Preferences > Accounts > Manage Certificates > "+"
```

### Notarization 실패
```bash
# 로그 확인
xcrun notarytool log <submission-id> \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD"

# 일반적인 원인:
# 1. 서명되지 않은 라이브러리
# 2. 잘못된 entitlements
# 3. Hardened Runtime 문제
```

### "Unable to find signing identity"
```bash
# 키체인 확인
security find-identity -v -p codesigning

# 인증서가 없으면 다시 생성
```

---

## 💰 비용 요약

### 초기 비용
- Apple Developer Program: **$99**
- 도구/소프트웨어: **무료**

### 연간 비용
- 갱신: **$99/년**

### 예상 시간
- 계정 생성: 30분
- 승인 대기: 1-2일
- 설정 및 테스트: 2-4시간
- **총**: 1-2일

---

## ✅ 완료 체크리스트

- [ ] Apple Developer 가입 ($99)
- [ ] 개발자 인증서 생성
- [ ] App-Specific Password 생성
- [ ] entitlements.plist 생성
- [ ] 앱 서명 테스트
- [ ] Notarization 성공
- [ ] DMG 생성 및 서명
- [ ] GitHub Secrets 설정
- [ ] GitHub Actions 테스트
- [ ] 다른 Mac에서 검증

---

## 🎉 성공하면

**사용자 경험 개선:**
- ✅ Gatekeeper 경고 없음
- ✅ "확인 없이 열기" 불필요
- ✅ 앱 다운로드 전환율 증가
- ✅ 전문적인 이미지

**다음 단계:**
- Windows 코드 서명
- v2.1.0 개발
- App Store 배포 (선택)

---

**macOS 코드 서명 완료!** 🍎✨

이제 Windows 코드 서명으로 넘어가세요!
