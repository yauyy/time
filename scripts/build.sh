#!/bin/bash
set -euo pipefail

ARCH_SETTING="${TIME_ARCHS:-native}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --universal)
            ARCH_SETTING='arm64 x86_64'
            ;;
        --help|-h)
            printf '用法：%s [--universal]\n' "$0"
            printf '默认构建本机架构；--universal 或 TIME_ARCHS="arm64 x86_64" 构建 Apple Silicon + Intel。\n'
            exit 0
            ;;
        *)
            printf '未知构建参数：%s\n' "$1" >&2
            exit 1
            ;;
    esac
    shift
done

ARCH_SETTING="${ARCH_SETTING//,/ }"
if [[ "$ARCH_SETTING" == native ]]; then
    ARCH_SETTING="$(uname -m)"
elif [[ "$ARCH_SETTING" == universal ]]; then
    ARCH_SETTING='arm64 x86_64'
fi
if [[ -z "${ARCH_SETTING//[[:space:]]/}" ]]; then
    printf '请至少指定一个目标架构。\n' >&2
    exit 1
fi
BUILD_ARM64=false
BUILD_X86_64=false
read -r -a REQUESTED_ARCHITECTURES <<< "$ARCH_SETTING"
for ARCH in "${REQUESTED_ARCHITECTURES[@]}"; do
    case "$ARCH" in
        arm64) BUILD_ARM64=true ;;
        x86_64) BUILD_X86_64=true ;;
        *)
            printf '不支持的架构：%s；仅支持 arm64 和 x86_64。\n' "$ARCH" >&2
            exit 1
            ;;
    esac
done
ARCHITECTURES=()
if [[ "$BUILD_ARM64" == true ]]; then ARCHITECTURES+=(arm64); fi
if [[ "$BUILD_X86_64" == true ]]; then ARCHITECTURES+=(x86_64); fi

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
ACTIVE_DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ "$ACTIVE_DEVELOPER_DIR" == */CommandLineTools ]]; then
    printf '构建需要完整 Xcode：当前 SDK 的 SwiftUI 宏插件及 XCTest 不包含在独立 Command Line Tools 中。\n' >&2
    printf '请安装 Xcode，或设置 DEVELOPER_DIR 指向已有 Xcode.app/Contents/Developer。\n' >&2
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$DIST_DIR/Time.app"
ICON_SOURCE="$PROJECT_DIR/Resources/AppIcon.png"
if [[ ! -f "$ICON_SOURCE" ]]; then
    printf '构建失败：缺少图标素材 %s。请先准备新的 AppIcon.png。\n' "$ICON_SOURCE" >&2
    exit 1
fi
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/time-build.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

BINARIES=()
MINIMUM_MACOS="$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$PROJECT_DIR/Resources/Info.plist")"
for ARCH in "${ARCHITECTURES[@]}"; do
    SCRATCH_PATH="$PROJECT_DIR/.build/packaging/$ARCH"
    TARGET_TRIPLE="$ARCH-apple-macosx$MINIMUM_MACOS"
    swift build --package-path "$PROJECT_DIR" --configuration release --product Time \
        --triple "$TARGET_TRIPLE" --scratch-path "$SCRATCH_PATH"
    BIN_DIR="$(swift build --package-path "$PROJECT_DIR" --configuration release \
        --triple "$TARGET_TRIPLE" --scratch-path "$SCRATCH_PATH" --show-bin-path)"
    xcrun lipo "$BIN_DIR/Time" -verify_arch "$ARCH"
    BINARIES+=("$BIN_DIR/Time")
done

STAGED_APP="$STAGING_DIR/Time.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
if [[ ${#BINARIES[@]} -gt 1 ]]; then
    xcrun lipo -create "${BINARIES[@]}" -output "$STAGED_APP/Contents/MacOS/Time"
else
    cp "${BINARIES[0]}" "$STAGED_APP/Contents/MacOS/Time"
fi
# Some Apple lipo versions parse a second -verify_arch argument as an input file.
# Verify each required slice separately for compatibility across Xcode versions.
for ARCH in "${ARCHITECTURES[@]}"; do
    xcrun lipo "$STAGED_APP/Contents/MacOS/Time" -verify_arch "$ARCH"
done
cp "$PROJECT_DIR/Resources/Info.plist" "$STAGED_APP/Contents/Info.plist"
cp "$ICON_SOURCE" "$STAGED_APP/Contents/Resources/AppIcon.png"
printf 'APPL????' > "$STAGED_APP/Contents/PkgInfo"

xcrun swift "$PROJECT_DIR/scripts/generate-icon.swift" "$ICON_SOURCE" "$STAGING_DIR/AppIcon.iconset"
iconutil --convert icns --output "$STAGED_APP/Contents/Resources/AppIcon.icns" "$STAGING_DIR/AppIcon.iconset"
plutil -lint "$STAGED_APP/Contents/Info.plist"
codesign --force --sign - "$STAGED_APP"
codesign --verify --deep --strict "$STAGED_APP"
xcrun lipo "$STAGED_APP/Contents/MacOS/Time" -info

mkdir -p "$DIST_DIR"
if [[ -L "$APP_PATH" ]]; then
    printf '构建失败：目标路径是符号链接：%s\n' "$APP_PATH" >&2
    exit 1
fi
if [[ -e "$APP_PATH" ]]; then
    rm -rf "$APP_PATH"
fi
mv "$STAGED_APP" "$APP_PATH"
printf '\n构建完成：%s\n' "$APP_PATH"
