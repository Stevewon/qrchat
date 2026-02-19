#!/bin/bash

# QRChat APK 빌드 및 GitHub Release 업로드 스크립트
# 사용법: ./BUILD_AND_RELEASE.sh

set -e

echo "🚀 QRChat APK 빌드 시작..."
echo ""

# 1. 버전 확인
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
echo "📦 현재 버전: v$VERSION"
echo ""

# 2. 의존성 설치
echo "📥 Flutter 의존성 설치 중..."
flutter pub get
echo ""

# 3. APK 빌드
echo "🔨 Release APK 빌드 중..."
flutter build apk --release
echo ""

# 4. APK 파일 찾기
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK 파일을 찾을 수 없습니다: $APK_PATH"
    exit 1
fi

# 5. APK 이름 변경
NEW_APK_NAME="qrchat_v${VERSION}.apk"
cp "$APK_PATH" "$NEW_APK_NAME"
echo "✅ APK 생성 완료: $NEW_APK_NAME"
echo ""

# 6. APK 정보 출력
APK_SIZE=$(ls -lh "$NEW_APK_NAME" | awk '{print $5}')
echo "📊 APK 정보:"
echo "   파일명: $NEW_APK_NAME"
echo "   크기: $APK_SIZE"
echo ""

# 7. GitHub Release에 업로드 (gh CLI 사용)
echo "📤 GitHub Release에 업로드 중..."
if command -v gh &> /dev/null; then
    gh release upload "v${VERSION}" "$NEW_APK_NAME" --clobber
    echo "✅ GitHub Release에 APK 업로드 완료!"
    echo "🔗 https://github.com/Stevewon/qrchat/releases/tag/v${VERSION}"
else
    echo "⚠️  gh CLI가 설치되어 있지 않습니다."
    echo "   수동으로 업로드하세요: https://github.com/Stevewon/qrchat/releases/tag/v${VERSION}"
    echo "   APK 파일 위치: $(pwd)/$NEW_APK_NAME"
fi

echo ""
echo "🎉 완료!"
