#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_PARENT="$HOME/Applications"
INSTALL_PATH="$INSTALL_PARENT/Time.app"

if pgrep -x Time > /dev/null; then
    printf '请先从菜单栏退出 Time，再重新执行安装。\n' >&2
    exit 1
fi

if [[ -L "$INSTALL_PATH" ]]; then
    printf '安装失败：目标路径是符号链接：%s\n' "$INSTALL_PATH" >&2
    exit 1
fi
if [[ -e "$INSTALL_PATH" ]]; then
    EXISTING_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$EXISTING_ID" != 'me.yau.time' ]]; then
        printf '安装失败：%s 已存在，且不是本项目的 Time 应用。\n' "$INSTALL_PATH" >&2
        exit 1
    fi
fi

"$PROJECT_DIR/scripts/build.sh"
mkdir -p "$INSTALL_PARENT"
STAGING_DIR="$(mktemp -d "$INSTALL_PARENT/.Time-install.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
ditto "$PROJECT_DIR/dist/Time.app" "$STAGING_DIR/Time.app"
if [[ -e "$INSTALL_PATH" ]]; then
    mv "$INSTALL_PATH" "$STAGING_DIR/Previous-Time.app"
fi
if ! mv "$STAGING_DIR/Time.app" "$INSTALL_PATH"; then
    if [[ -e "$STAGING_DIR/Previous-Time.app" ]]; then
        mv "$STAGING_DIR/Previous-Time.app" "$INSTALL_PATH"
    fi
    exit 1
fi
open "$INSTALL_PATH"
printf '\n已安装并启动：%s\n' "$INSTALL_PATH"
