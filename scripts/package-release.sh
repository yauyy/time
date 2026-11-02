#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$DIST_DIR/Time.app"
SKIP_BUILD=false
CUSTOM_APP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)
            SKIP_BUILD=true
            ;;
        --app)
            if [[ $# -lt 2 ]]; then
                printf '%s\n' '--app 需要一个已构建的 universal .app 路径。' >&2
                exit 1
            fi
            APP_PATH="$2"
            CUSTOM_APP=true
            shift
            ;;
        --help|-h)
            printf '用法：%s [--skip-build] [--app /path/to/Time.app]\n' "$0"
            printf '默认构建 universal 应用后打包；--skip-build 只验证并打包已有应用。\n'
            exit 0
            ;;
        *)
            printf '未知打包参数：%s\n' "$1" >&2
            exit 1
            ;;
    esac
    shift
done

if [[ "$CUSTOM_APP" == true && "$SKIP_BUILD" != true ]]; then
    printf '%s\n' '指定 --app 时必须同时使用 --skip-build，避免混淆构建来源。' >&2
    exit 1
fi
if [[ "$SKIP_BUILD" != true ]]; then
    "$PROJECT_DIR/scripts/build.sh" --universal
fi

APP_INFO="$APP_PATH/Contents/Info.plist"
APP_EXEC="$APP_PATH/Contents/MacOS/Time"
if [[ ! -f "$APP_INFO" || ! -x "$APP_EXEC" ]]; then
    printf '打包失败：不是有效的 Time.app：%s\n' "$APP_PATH" >&2
    exit 1
fi
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_INFO")"
APP_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_INFO")"
if [[ "$APP_VERSION" != "$VERSION" || "$APP_ID" != me.yau.time ]]; then
    printf '打包失败：应用标识或版本不匹配，预期 me.yau.time / %s，实际 %s / %s。\n' "$VERSION" "$APP_ID" "$APP_VERSION" >&2
    exit 1
fi
if [[ ! -f "$APP_PATH/Contents/Resources/AppIcon.png" || ! -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]]; then
    printf '%s\n' '打包失败：缺少 PNG 或 ICNS 图标资源。' >&2
    exit 1
fi
for REQUIRED_ARCH in arm64 x86_64; do
    xcrun lipo "$APP_EXEC" -verify_arch "$REQUIRED_ARCH"
done
codesign --verify --deep --strict "$APP_PATH"

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/time-release.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
ZIP_NAME='Time-macOS-universal.zip'
DMG_NAME='Time-macOS-universal.dmg'
DMG_SOURCE="$STAGING_DIR/dmg-source"
mkdir -p "$DMG_SOURCE"
ditto "$APP_PATH" "$DMG_SOURCE/Time.app"
codesign --verify --deep --strict "$DMG_SOURCE/Time.app"
ln -s /Applications "$DMG_SOURCE/Applications"
cat > "$DMG_SOURCE/安装说明.txt" <<EOF
Time $VERSION

支持 macOS 13 或更高版本，兼容 Apple Silicon 和 Intel Mac。

安装：
1. 将 Time.app 拖入本磁盘映像中的 Applications 快捷方式。
2. 从“应用程序”打开 Time。时间显示在菜单栏，点击可调整时区和格式。
3. 默认显示上海时间；应用不修改系统时间或系统时区。

本版本采用 ad hoc 签名，尚未使用 Developer ID 签名或通过 Apple 公证。
首次打开时 macOS 可能显示安全提示。请先尝试打开，再在“系统设置 → 隐私与安全性”中查看并确认 Time 的打开选项。

更新前请从菜单栏退出旧版 Time。登录启动可在应用设置中调整。
EOF

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$STAGING_DIR/$ZIP_NAME"
unzip -tq "$STAGING_DIR/$ZIP_NAME"
hdiutil create -volname "Time $VERSION" -srcfolder "$DMG_SOURCE" -fs HFS+ \
    -format UDZO -imagekey zlib-level=9 -nospotlight "$STAGING_DIR/$DMG_NAME"
hdiutil verify "$STAGING_DIR/$DMG_NAME"
(
    cd "$STAGING_DIR"
    shasum -a 256 "$ZIP_NAME" "$DMG_NAME" > SHA256SUMS.txt
    shasum -a 256 -c SHA256SUMS.txt
)

mkdir -p "$DIST_DIR"
mv "$STAGING_DIR/$ZIP_NAME" "$DIST_DIR/$ZIP_NAME"
mv "$STAGING_DIR/$DMG_NAME" "$DIST_DIR/$DMG_NAME"
mv "$STAGING_DIR/SHA256SUMS.txt" "$DIST_DIR/SHA256SUMS.txt"
printf '\nTime %s 发布包已生成：\n%s\n%s\n%s\n' "$VERSION" \
    "$DIST_DIR/$ZIP_NAME" "$DIST_DIR/$DMG_NAME" "$DIST_DIR/SHA256SUMS.txt"
