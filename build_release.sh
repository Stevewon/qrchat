#!/bin/bash

# 🚀 QRChat Desktop v2.0.0 Release Build Script
# This script builds installers for all platforms

set -e  # Exit on error

echo "🚀 QRChat Desktop v2.0.0 Release Build"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version
VERSION="2.0.0"
BUILD_NUMBER="200"

echo -e "${BLUE}📦 Version: $VERSION+$BUILD_NUMBER${NC}"
echo ""

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Create releases directory
mkdir -p releases

# Platform detection
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="windows"
else
    echo -e "${RED}❌ Unknown platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Detected platform: $PLATFORM${NC}"
echo ""

# Build for current platform
case $PLATFORM in
    linux)
        echo -e "${BLUE}🐧 Building Linux version...${NC}"
        flutter build linux --release
        
        # Create AppImage (if available)
        if command -v appimagetool &> /dev/null; then
            echo -e "${BLUE}📦 Creating AppImage...${NC}"
            appimagetool build/linux/x64/release/bundle releases/QRChat-$VERSION-linux-x86_64.AppImage
        fi
        
        # Create .deb package
        echo -e "${BLUE}📦 Creating .deb package...${NC}"
        mkdir -p releases/qrchat-$VERSION/DEBIAN
        mkdir -p releases/qrchat-$VERSION/usr/bin
        mkdir -p releases/qrchat-$VERSION/usr/share/applications
        mkdir -p releases/qrchat-$VERSION/usr/share/icons/hicolor/256x256/apps
        
        # Copy files
        cp -r build/linux/x64/release/bundle/* releases/qrchat-$VERSION/usr/bin/
        
        # Create .desktop file
        cat > releases/qrchat-$VERSION/usr/share/applications/qrchat.desktop << EOF
[Desktop Entry]
Name=QRChat
Comment=QRChat Desktop - 카카오톡 스타일 PC 메신저
Exec=/usr/bin/qrchat
Icon=qrchat
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
EOF
        
        # Create control file
        cat > releases/qrchat-$VERSION/DEBIAN/control << EOF
Package: qrchat
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Maintainer: QRChat Team <support@qrchat.io>
Description: QRChat Desktop - KakaoTalk-style PC Messenger
 QRChat is a modern, secure messaging application
 with QR code-based friend adding feature.
EOF
        
        # Build .deb
        dpkg-deb --build releases/qrchat-$VERSION releases/qrchat_${VERSION}_amd64.deb
        
        echo -e "${GREEN}✅ Linux build complete!${NC}"
        echo -e "${GREEN}   - AppImage: releases/QRChat-$VERSION-linux-x86_64.AppImage${NC}"
        echo -e "${GREEN}   - .deb: releases/qrchat_${VERSION}_amd64.deb${NC}"
        ;;
        
    macos)
        echo -e "${BLUE}🍎 Building macOS version...${NC}"
        flutter build macos --release
        
        # Create .dmg
        echo -e "${BLUE}📦 Creating .dmg...${NC}"
        create-dmg \
          --volname "QRChat $VERSION" \
          --window-pos 200 120 \
          --window-size 800 400 \
          --icon-size 100 \
          --icon "QRChat.app" 200 190 \
          --hide-extension "QRChat.app" \
          --app-drop-link 600 185 \
          "releases/QRChat-$VERSION-macos.dmg" \
          "build/macos/Build/Products/Release/qrchat.app"
        
        echo -e "${GREEN}✅ macOS build complete!${NC}"
        echo -e "${GREEN}   - .dmg: releases/QRChat-$VERSION-macos.dmg${NC}"
        ;;
        
    windows)
        echo -e "${BLUE}🪟 Building Windows version...${NC}"
        flutter build windows --release
        
        # Create MSIX package
        echo -e "${BLUE}📦 Creating MSIX package...${NC}"
        flutter pub run msix:create
        
        # Create portable ZIP
        echo -e "${BLUE}📦 Creating portable ZIP...${NC}"
        cd build/windows/x64/runner/Release
        zip -r ../../../../../releases/QRChat-$VERSION-windows-portable.zip ./*
        cd -
        
        echo -e "${GREEN}✅ Windows build complete!${NC}"
        echo -e "${GREEN}   - MSIX: releases/qrchat.msix${NC}"
        echo -e "${GREEN}   - Portable: releases/QRChat-$VERSION-windows-portable.zip${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Release files are in: releases/${NC}"
ls -lh releases/

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "  1. Test the installer on a clean machine"
echo -e "  2. Upload to GitHub Releases"
echo -e "  3. Update appcast.xml for auto-updates"
echo -e "  4. Announce the release! 🎉"
