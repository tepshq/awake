#!/bin/bash
#
# AWAKE アンインストーラ
#   - スリープ抑止を OFF に戻す(パスワードを聞かれます)
#   - プラグインファイルを削除する
#   - SwiftBar 本体は残します(消す場合は最後の案内を参照)
#
# 使い方:  ./uninstall.sh
#
set -uo pipefail

BUNDLE_ID="com.ameba.SwiftBar"
PLUGIN_NAME="awake.30s.sh"

echo "▶ スリープ抑止を OFF に戻します（パスワードを聞かれます）..."
if /usr/bin/osascript -e 'do shell script "/usr/bin/pmset -a disablesleep 0" with administrator privileges' >/dev/null 2>&1; then
  echo "  OFF に戻しました。"
else
  echo "  （スキップ/キャンセルされました。必要なら手動で: sudo pmset -a disablesleep 0）"
fi

echo "▶ プラグインを削除..."
DIR="$(defaults read "$BUNDLE_ID" PluginDirectory 2>/dev/null || true)"
if [ -n "$DIR" ] && [ -f "$DIR/$PLUGIN_NAME" ]; then
  rm -f "$DIR/$PLUGIN_NAME"
  echo "  削除しました: $DIR/$PLUGIN_NAME"
else
  echo "  プラグインが見つかりませんでした（既に削除済み？）"
fi

open "swiftbar://refreshallplugins" 2>/dev/null || true

echo ""
echo "✅ アンインストール完了です。"
echo "   SwiftBar 本体も消す場合: brew uninstall --cask swiftbar"
