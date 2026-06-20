#!/bin/bash
#
# AWAKE インストーラ
#   - SwiftBar が無ければ Homebrew で入れる
#   - プラグインを SwiftBar のプラグインフォルダに配置する
#   - SwiftBar を起動 / リフレッシュする
#
# 使い方:
#   ローカル（clone/zip）から:  ./install.sh
#   ネット越し（1行）:          curl -fsSL https://raw.githubusercontent.com/tepshq/awake/main/install.sh | bash
#
set -uo pipefail

# ===== 配布元 ============================================================
# curl|bash で使うときの取得先。clone/zip して使う場合は自動でローカルを優先する。
REPO="${AWAKE_REPO:-tepshq/awake}"
BRANCH="${AWAKE_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
# ========================================================================

PLUGIN_NAME="awake.30s.sh"
BUNDLE_ID="com.ameba.SwiftBar"
DEFAULT_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"

# このスクリプトと同じ場所に plugins/ があればローカル版を使う（clone/zip 実行時）。
# curl|bash 実行時は場所が不定なので、無ければネットから取得する。
SELF_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
LOCAL_PLUGIN="$SELF_DIR/plugins/$PLUGIN_NAME"

echo "▶ Homebrew を確認..."
if ! command -v brew >/dev/null 2>&1; then
  echo "  ✗ Homebrew が必要です。https://brew.sh を参照してインストールしてください。"
  exit 1
fi

echo "▶ SwiftBar を確認..."
if [ ! -d "/Applications/SwiftBar.app" ]; then
  echo "  SwiftBar が無いのでインストールします (brew install --cask swiftbar)..."
  brew install --cask swiftbar
else
  echo "  SwiftBar は導入済みです。"
fi

echo "▶ プラグインフォルダを判定..."
DIR="$(defaults read "$BUNDLE_ID" PluginDirectory 2>/dev/null || true)"
if [ -z "$DIR" ]; then
  DIR="$DEFAULT_DIR"
  mkdir -p "$DIR"
  defaults write "$BUNDLE_ID" PluginDirectory "$DIR"
  echo "  既定フォルダを設定しました: $DIR"
  echo "  （初回起動時に SwiftBar からフォルダを聞かれたら、上記と同じパスを選んでください）"
else
  mkdir -p "$DIR"
  echo "  既存フォルダを使用します: $DIR"
fi

echo "▶ プラグインを配置..."
if [ -f "$LOCAL_PLUGIN" ]; then
  cp "$LOCAL_PLUGIN" "$DIR/$PLUGIN_NAME"
  echo "  ローカルから配置しました: $LOCAL_PLUGIN"
else
  echo "  ネットから取得します: $RAW_BASE/plugins/$PLUGIN_NAME"
  if ! curl -fsSL "$RAW_BASE/plugins/$PLUGIN_NAME" -o "$DIR/$PLUGIN_NAME"; then
    echo "  ✗ プラグインの取得に失敗しました。リポジトリ（$REPO）が公開か、ブランチ（$BRANCH）を確認してください。"
    exit 1
  fi
fi
chmod +x "$DIR/$PLUGIN_NAME"
echo "  配置完了: $DIR/$PLUGIN_NAME"

echo "▶ SwiftBar を起動 / リフレッシュ..."
open -a SwiftBar 2>/dev/null || true
sleep 1
open "swiftbar://refreshallplugins" 2>/dev/null || true

echo ""
echo "✅ 完了です。メニューバーに 🌙 (OFF) または 🚨/☀️ (ON) が表示されます。"
echo "   表示されない場合は SwiftBar を一度終了→再起動してください。"
