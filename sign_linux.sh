#!/bin/bash

###############################################################################
# QRChat Desktop - Automated Linux Code Signing Script
# 
# This script automates the Linux code signing process:
# 1. Build Flutter app
# 2. Create .deb package
# 3. Sign with GPG
# 4. Create AppImage
# 5. Sign AppImage
#
# Requirements:
# - Linux (Ubuntu/Debian recommended)
# - Flutter SDK
# - dpkg-deb
# - appimagetool
# - GPG key for signing
#
# Usage:
#   ./sign_linux.sh
#
# Environment variables (optional):
#   GPG_KEY_ID        Your GPG key ID (default: auto-detect)
#   BUILD_DEB         Build .deb package (default: yes)
#   BUILD_APPIMAGE    Build AppImage (default: yes)
#
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="qrchat"
APP_VERSION="2.0.0"
BUILD_MODE="release"

# Paths
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${PROJECT_ROOT}/build/linux/x64/release/bundle"
DEB_NAME="${APP_NAME}_${APP_VERSION}_amd64.deb"
APPIMAGE_NAME="QRChat-${APP_VERSION}-x86_64.AppImage"

# Options
BUILD_DEB=${BUILD_DEB:-yes}
BUILD_APPIMAGE=${BUILD_APPIMAGE:-yes}

###############################################################################
# Functions
###############################################################################

log_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

check_tools() {
    log_info "Checking required tools..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Install from: https://flutter.dev"
        exit 1
    fi
    
    if ! command -v gpg &> /dev/null; then
        log_error "GPG not found. Install with: sudo apt install gnupg"
        exit 1
    fi
    
    if [ "$BUILD_DEB" = "yes" ] && ! command -v dpkg-deb &> /dev/null; then
        log_error "dpkg-deb not found. Install with: sudo apt install dpkg-dev"
        exit 1
    fi
    
    if [ "$BUILD_APPIMAGE" = "yes" ] && ! command -v appimagetool &> /dev/null; then
        log_warning "appimagetool not found. Downloading..."
        wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
            -O /tmp/appimagetool
        chmod +x /tmp/appimagetool
        APPIMAGETOOL=/tmp/appimagetool
    else
        APPIMAGETOOL=appimagetool
    fi
    
    log_success "All tools available"
}

check_gpg_key() {
    log_info "Checking GPG key..."
    
    if [ -z "$GPG_KEY_ID" ]; then
        # Auto-detect first GPG key
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    fi
    
    if [ -z "$GPG_KEY_ID" ]; then
        log_warning "No GPG key found. Creating a new one..."
        create_gpg_key
    else
        log_success "Using GPG key: $GPG_KEY_ID"
    fi
}

create_gpg_key() {
    log_info "Creating GPG key..."
    
    cat > /tmp/gpg_key_config << EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: QRChat Developer
Name-Email: developer@qrchat.io
Expire-Date: 0
EOF
    
    gpg --batch --generate-key /tmp/gpg_key_config
    rm -f /tmp/gpg_key_config
    
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    
    log_success "GPG key created: $GPG_KEY_ID"
    log_info "Export your public key with: gpg --armor --export $GPG_KEY_ID > qrchat-pubkey.asc"
}

build_flutter_app() {
    log_info "Building Flutter Linux app..."
    
    cd "$PROJECT_ROOT"
    
    flutter clean
    flutter pub get
    flutter build linux --release
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Build failed: $APP_PATH not found"
        exit 1
    fi
    
    log_success "Flutter build completed: $APP_PATH"
}

create_deb_package() {
    log_info "Creating .deb package..."
    
    DEB_BUILD_DIR="${PROJECT_ROOT}/build/deb"
    rm -rf "$DEB_BUILD_DIR"
    mkdir -p "$DEB_BUILD_DIR"
    
    # Create directory structure
    mkdir -p "${DEB_BUILD_DIR}/DEBIAN"
    mkdir -p "${DEB_BUILD_DIR}/usr/bin"
    mkdir -p "${DEB_BUILD_DIR}/usr/share/applications"
    mkdir -p "${DEB_BUILD_DIR}/usr/share/pixmaps"
    mkdir -p "${DEB_BUILD_DIR}/usr/lib/${APP_NAME}"
    
    # Copy binary and files
    cp -r "${APP_PATH}"/* "${DEB_BUILD_DIR}/usr/lib/${APP_NAME}/"
    ln -s "/usr/lib/${APP_NAME}/${APP_NAME}" "${DEB_BUILD_DIR}/usr/bin/${APP_NAME}"
    
    # Create desktop file
    cat > "${DEB_BUILD_DIR}/usr/share/applications/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Name=QRChat
Comment=Secure QR-based messaging app
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Network;InstantMessaging;
Terminal=false
StartupWMClass=qrchat
EOF
    
    # Copy icon (assuming you have one)
    if [ -f "${PROJECT_ROOT}/assets/icon/app_icon.png" ]; then
        cp "${PROJECT_ROOT}/assets/icon/app_icon.png" "${DEB_BUILD_DIR}/usr/share/pixmaps/${APP_NAME}.png"
    fi
    
    # Get installed size
    INSTALLED_SIZE=$(du -sk "${DEB_BUILD_DIR}/usr" | cut -f1)
    
    # Create control file
    cat > "${DEB_BUILD_DIR}/DEBIAN/control" << EOF
Package: ${APP_NAME}
Version: ${APP_VERSION}
Architecture: amd64
Maintainer: QRChat Developer <developer@qrchat.io>
Depends: libgtk-3-0, libglib2.0-0, libgstreamer1.0-0, libayatana-appindicator3-1
Installed-Size: ${INSTALLED_SIZE}
Section: net
Priority: optional
Homepage: https://qrchat.io
Description: QRChat - Secure QR-based messaging
 QRChat is a secure messaging application that uses QR codes
 for easy contact exchange and features end-to-end encryption.
EOF
    
    # Build .deb
    dpkg-deb --build "$DEB_BUILD_DIR" "$DEB_NAME"
    
    log_success ".deb package created: $DEB_NAME"
}

sign_deb() {
    log_info "Signing .deb package..."
    
    # Create GPG signature
    gpg --default-key "$GPG_KEY_ID" --armor --detach-sign "$DEB_NAME"
    
    log_success ".deb signature created: ${DEB_NAME}.asc"
}

create_appimage() {
    log_info "Creating AppImage..."
    
    APPDIR="${PROJECT_ROOT}/build/AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR"
    
    # Create directory structure
    mkdir -p "${APPDIR}/usr/bin"
    mkdir -p "${APPDIR}/usr/share/applications"
    mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "${APPDIR}/usr/lib"
    
    # Copy files
    cp -r "${APP_PATH}"/* "${APPDIR}/usr/bin/"
    
    # Create desktop file
    cat > "${APPDIR}/usr/share/applications/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Name=QRChat
Comment=Secure QR-based messaging app
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Network;InstantMessaging;
Terminal=false
EOF
    
    # Copy icon
    if [ -f "${PROJECT_ROOT}/assets/icon/app_icon.png" ]; then
        cp "${PROJECT_ROOT}/assets/icon/app_icon.png" \
           "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
        cp "${PROJECT_ROOT}/assets/icon/app_icon.png" "${APPDIR}/${APP_NAME}.png"
        cp "${PROJECT_ROOT}/assets/icon/app_icon.png" "${APPDIR}/.DirIcon"
    fi
    
    # Create AppRun script
    cat > "${APPDIR}/AppRun" << 'EOF'
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
exec "${APPDIR}/usr/bin/qrchat" "$@"
EOF
    chmod +x "${APPDIR}/AppRun"
    
    # Build AppImage
    ARCH=x86_64 $APPIMAGETOOL "$APPDIR" "$APPIMAGE_NAME"
    
    log_success "AppImage created: $APPIMAGE_NAME"
}

sign_appimage() {
    log_info "Signing AppImage..."
    
    # Create GPG signature
    gpg --default-key "$GPG_KEY_ID" --armor --detach-sign "$APPIMAGE_NAME"
    
    log_success "AppImage signature created: ${APPIMAGE_NAME}.asc"
}

verify_signatures() {
    log_info "Verifying signatures..."
    
    if [ "$BUILD_DEB" = "yes" ]; then
        gpg --verify "${DEB_NAME}.asc" "$DEB_NAME"
        log_success ".deb signature valid"
    fi
    
    if [ "$BUILD_APPIMAGE" = "yes" ]; then
        gpg --verify "${APPIMAGE_NAME}.asc" "$APPIMAGE_NAME"
        log_success "AppImage signature valid"
    fi
}

export_public_key() {
    log_info "Exporting public key..."
    
    PUBLIC_KEY_FILE="qrchat-pubkey.asc"
    gpg --armor --export "$GPG_KEY_ID" > "$PUBLIC_KEY_FILE"
    
    log_success "Public key exported: $PUBLIC_KEY_FILE"
    log_info "Users can import it with: gpg --import $PUBLIC_KEY_FILE"
}

final_summary() {
    log_success "Final summary"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🐧 Linux Build Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$BUILD_DEB" = "yes" ]; then
        DEB_SIZE=$(du -sh "$DEB_NAME" | awk '{print $1}')
        echo -e "${BLUE}📦 .deb package:${NC} $(pwd)/$DEB_NAME"
        echo -e "${BLUE}📏 Size:${NC} $DEB_SIZE"
        echo -e "${BLUE}🔐 Signature:${NC} ${DEB_NAME}.asc"
        echo ""
    fi
    
    if [ "$BUILD_APPIMAGE" = "yes" ]; then
        APPIMAGE_SIZE=$(du -sh "$APPIMAGE_NAME" | awk '{print $1}')
        echo -e "${BLUE}📦 AppImage:${NC} $(pwd)/$APPIMAGE_NAME"
        echo -e "${BLUE}📏 Size:${NC} $APPIMAGE_SIZE"
        echo -e "${BLUE}🔐 Signature:${NC} ${APPIMAGE_NAME}.asc"
        echo ""
    fi
    
    echo -e "${BLUE}🔑 GPG Key:${NC} $GPG_KEY_ID"
    echo -e "${BLUE}🔑 Public Key:${NC} qrchat-pubkey.asc"
    echo ""
    echo -e "${GREEN}✅ Signed and ready for distribution${NC}"
    echo ""
}

###############################################################################
# Main Script
###############################################################################

main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🐧 QRChat Linux Code Signing Automation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    check_tools
    check_gpg_key
    build_flutter_app
    
    if [ "$BUILD_DEB" = "yes" ]; then
        create_deb_package
        sign_deb
    fi
    
    if [ "$BUILD_APPIMAGE" = "yes" ]; then
        create_appimage
        sign_appimage
    fi
    
    verify_signatures
    export_public_key
    final_summary
    
    log_success "All steps completed successfully! 🎉"
}

# Run main function
main "$@"
