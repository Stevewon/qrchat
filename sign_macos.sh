#!/bin/bash

###############################################################################
# QRChat Desktop - Automated macOS Code Signing Script
# 
# This script automates the entire macOS code signing process:
# 1. Build Flutter app
# 2. Sign the app bundle
# 3. Create and sign DMG
# 4. Notarize with Apple
# 5. Staple notarization ticket
#
# Requirements:
# - macOS with Xcode
# - Apple Developer account ($99/year)
# - Developer ID Application certificate installed
# - App-Specific Password generated
#
# Usage:
#   ./sign_macos.sh
#
# Environment variables (set these before running):
#   APPLE_ID              Your Apple ID email
#   APPLE_TEAM_ID         Your Team ID (from developer.apple.com)
#   APPLE_APP_PASSWORD    App-Specific Password
#   CERTIFICATE_NAME      Full certificate name
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
APP_PATH="${PROJECT_ROOT}/build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="QRChat-${APP_VERSION}-macos.dmg"
ENTITLEMENTS="${PROJECT_ROOT}/macos/Runner/Release.entitlements"

# Check environment variables
if [ -z "$APPLE_ID" ]; then
    echo -e "${RED}Error: APPLE_ID environment variable not set${NC}"
    echo "Set it with: export APPLE_ID='your@email.com'"
    exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    echo -e "${RED}Error: APPLE_TEAM_ID environment variable not set${NC}"
    echo "Get it from: https://developer.apple.com/account"
    exit 1
fi

if [ -z "$APPLE_APP_PASSWORD" ]; then
    echo -e "${RED}Error: APPLE_APP_PASSWORD environment variable not set${NC}"
    echo "Generate one at: https://appleid.apple.com/"
    exit 1
fi

# Default certificate name (can be overridden)
if [ -z "$CERTIFICATE_NAME" ]; then
    CERTIFICATE_NAME="Developer ID Application: Your Name (${APPLE_TEAM_ID})"
    echo -e "${YELLOW}Using default certificate name: ${CERTIFICATE_NAME}${NC}"
    echo -e "${YELLOW}Override with: export CERTIFICATE_NAME='Your Certificate Name'${NC}"
fi

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
    
    if ! command -v codesign &> /dev/null; then
        log_error "codesign not found. Install Xcode Command Line Tools"
        exit 1
    fi
    
    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun not found. Install Xcode"
        exit 1
    fi
    
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg not found. Installing..."
        brew install create-dmg || {
            log_error "Failed to install create-dmg"
            exit 1
        }
    fi
    
    log_success "All tools available"
}

check_certificate() {
    log_info "Checking code signing certificate..."
    
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        log_error "Developer ID Application certificate not found"
        log_error "Install your certificate from Apple Developer portal"
        exit 1
    fi
    
    log_success "Certificate found: ${CERTIFICATE_NAME}"
}

create_entitlements() {
    log_info "Creating entitlements file..."
    
    mkdir -p "$(dirname "$ENTITLEMENTS")"
    
    cat > "$ENTITLEMENTS" << 'EOF'
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
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
</dict>
</plist>
EOF
    
    log_success "Entitlements created: $ENTITLEMENTS"
}

build_flutter_app() {
    log_info "Building Flutter macOS app..."
    
    cd "$PROJECT_ROOT"
    
    flutter clean
    flutter pub get
    flutter build macos --release
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Build failed: $APP_PATH not found"
        exit 1
    fi
    
    log_success "Flutter build completed: $APP_PATH"
}

sign_app() {
    log_info "Signing app bundle..."
    
    # Sign all frameworks and dylibs first
    find "$APP_PATH" -type f \( -name "*.dylib" -o -name "*.framework" \) -exec codesign \
        --deep \
        --force \
        --verify \
        --verbose \
        --sign "$CERTIFICATE_NAME" \
        --options runtime \
        {} \;
    
    # Sign the main app
    codesign \
        --deep \
        --force \
        --verify \
        --verbose \
        --sign "$CERTIFICATE_NAME" \
        --options runtime \
        --entitlements "$ENTITLEMENTS" \
        "$APP_PATH"
    
    log_success "App signed"
}

verify_signature() {
    log_info "Verifying signature..."
    
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    spctl --assess --verbose "$APP_PATH"
    
    log_success "Signature verified"
}

create_dmg() {
    log_info "Creating DMG..."
    
    cd "$PROJECT_ROOT/build/macos/Build/Products/Release"
    
    # Remove old DMG if exists
    rm -f "$DMG_NAME"
    
    # Create DMG
    create-dmg \
        --volname "QRChat" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        --no-internet-enable \
        "$DMG_NAME" \
        "$APP_PATH" || {
            log_warning "create-dmg returned non-zero, but DMG may still be created"
        }
    
    if [ ! -f "$DMG_NAME" ]; then
        log_error "DMG creation failed"
        exit 1
    fi
    
    log_success "DMG created: $DMG_NAME"
}

sign_dmg() {
    log_info "Signing DMG..."
    
    cd "$PROJECT_ROOT/build/macos/Build/Products/Release"
    
    codesign --sign "$CERTIFICATE_NAME" "$DMG_NAME"
    codesign --verify --verbose "$DMG_NAME"
    
    log_success "DMG signed"
}

notarize_app() {
    log_info "Submitting for notarization..."
    log_warning "This may take 5-10 minutes..."
    
    cd "$PROJECT_ROOT/build/macos/Build/Products/Release"
    
    # Create ZIP for notarization
    ditto -c -k --keepParent "$APP_PATH" "${APP_NAME}.zip"
    
    # Submit for notarization
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "${APP_NAME}.zip" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait 2>&1)
    
    echo "$SUBMISSION_OUTPUT"
    
    # Extract submission ID
    SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
    
    if [ -z "$SUBMISSION_ID" ]; then
        log_error "Failed to get submission ID"
        exit 1
    fi
    
    log_info "Submission ID: $SUBMISSION_ID"
    
    # Check if notarization succeeded
    if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
        log_success "Notarization successful"
    else
        log_error "Notarization failed"
        xcrun notarytool log "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_APP_PASSWORD"
        exit 1
    fi
    
    # Clean up ZIP
    rm -f "${APP_NAME}.zip"
}

staple_ticket() {
    log_info "Stapling notarization ticket..."
    
    cd "$PROJECT_ROOT/build/macos/Build/Products/Release"
    
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
    
    log_success "Ticket stapled to app"
}

final_verification() {
    log_info "Final verification..."
    
    cd "$PROJECT_ROOT/build/macos/Build/Products/Release"
    
    # Verify app
    spctl --assess --type execute --verbose "$APP_PATH"
    
    # Get app info
    APP_SIZE=$(du -sh "$APP_PATH" | awk '{print $1}')
    DMG_SIZE=$(du -sh "$DMG_NAME" | awk '{print $1}')
    
    log_success "Final verification passed"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 macOS Build Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📦 App:${NC} $APP_PATH"
    echo -e "${BLUE}📏 Size:${NC} $APP_SIZE"
    echo ""
    echo -e "${BLUE}💿 DMG:${NC} $(pwd)/$DMG_NAME"
    echo -e "${BLUE}📏 Size:${NC} $DMG_SIZE"
    echo ""
    echo -e "${GREEN}✅ Signed and notarized${NC}"
    echo -e "${GREEN}✅ Ready for distribution${NC}"
    echo ""
}

###############################################################################
# Main Script
###############################################################################

main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🍎 QRChat macOS Code Signing Automation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    check_tools
    check_certificate
    create_entitlements
    build_flutter_app
    sign_app
    verify_signature
    create_dmg
    sign_dmg
    notarize_app
    staple_ticket
    final_verification
    
    log_success "All steps completed successfully! 🎉"
}

# Run main function
main "$@"
