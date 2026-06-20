#!/bin/bash
#
# AWAKE — AWAKEモード（蓋を閉じてもスリープしない）をメニューバーからトグル
#
# <xbar.title>AWAKE</xbar.title>
# <xbar.version>v1.1.0</xbar.version>
# <xbar.author>テープス株式会社</xbar.author>
# <xbar.desc>AWAKEモード（蓋を閉じても外部ディスプレイ無しでもMacをスリープさせない）をメニューバーからON/OFF。ONが長時間続くと🚨で切り忘れを警告します。</xbar.desc>
# <xbar.dependencies>macOS,pmset</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#
# アイコン: 👀 通常モード(OFF) / 👁️ AWAKEモード(ON) / 🚨 AWAKEモードが長時間続いたときの警告
#
# 仕組み:
#   ON  = /usr/bin/pmset -a disablesleep 1   (root)
#   OFF = /usr/bin/pmset -a disablesleep 0   (root)
#   root取得は osascript の管理者ダイアログ(毎回パスワード)。状態読みはパスワード不要。

# ===== 設定 =====================================================
# AWAKEモードのまま この秒数を超えたら、メニューバーを 🚨 にして切り忘れを警告する。
#   3600 = 1時間 / 1800 = 30分 / 7200 = 2時間 / 0 = 警告しない
SIREN_AFTER=3600
# ================================================================

# do shell script はPATHが限定されるため、コマンドは必ず絶対パスで。
PMSET="/usr/bin/pmset"
AWK="/usr/bin/awk"
OSASCRIPT="/usr/bin/osascript"

# AWAKEモード継続時間を覚えておく場所
STATE_DIR="$HOME/Library/Application Support/AWAKE"
ON_SINCE_FILE="$STATE_DIR/on_since"

# 現在の状態: "on" / "off"
get_state() {
  local v
  v="$("$PMSET" -g | "$AWK" '/SleepDisabled/{print $2; exit}')"
  [ "$v" = "1" ] && echo "on" || echo "off"
}

# disablesleep を切り替える(root)。$1 = 1/0。キャンセル時は何もしない。
set_disablesleep() {
  "$OSASCRIPT" -e "do shell script \"$PMSET -a disablesleep $1\" with administrator privileges" >/dev/null 2>&1
}

# ---- クリック時のアクション ----
case "$1" in
  on)     set_disablesleep 1; exit 0 ;;
  off)    set_disablesleep 0; exit 0 ;;
  toggle) [ "$(get_state)" = "on" ] && set_disablesleep 0 || set_disablesleep 1; exit 0 ;;
esac

# ---- メニュー描画 ----
SELF="$0"
STATE="$(get_state)"
NOW="$(date +%s)"

# AWAKEモード継続時間の管理 & サイレン判定
SIREN=0
ELAPSED=0
if [ "$STATE" = "on" ]; then
  mkdir -p "$STATE_DIR"
  SINCE="$(cat "$ON_SINCE_FILE" 2>/dev/null)"
  case "$SINCE" in
    ''|*[!0-9]*) SINCE="$NOW"; printf '%s' "$NOW" > "$ON_SINCE_FILE" ;;
  esac
  ELAPSED=$(( NOW - SINCE ))
  [ "$ELAPSED" -lt 0 ] && ELAPSED=0
  if [ "$SIREN_AFTER" -gt 0 ] && [ "$ELAPSED" -ge "$SIREN_AFTER" ]; then
    SIREN=1
  fi
else
  rm -f "$ON_SINCE_FILE" 2>/dev/null
fi

# 経過秒を「N時間M分」に
human() {
  local s="$1" h m
  h=$(( s / 3600 )); m=$(( (s % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then echo "${h}時間${m}分"; else echo "${m}分"; fi
}

# ---- 出力（メニューバー1行 → --- → ドロップダウン）----
if [ "$STATE" = "off" ]; then
  echo "👀 | size=15"
  echo "---"
  echo "👀 通常モード（OFF） | color=#8E8E93"
  echo "---"
  echo "👁️ AWAKEモードにする | bash=\"$SELF\" param1=on terminal=false refresh=true"
elif [ "$SIREN" = "1" ]; then
  echo "🚨 | size=15"
  echo "---"
  echo "🚨 AWAKEモードのまま $(human "$ELAPSED") 経過 — 切り忘れ注意 | color=#FF3B30"
  echo "---"
  echo "👀 通常モードにする | bash=\"$SELF\" param1=off terminal=false refresh=true"
else
  echo "👁️ | size=15"
  echo "---"
  echo "👁️ AWAKEモード（ON） | color=#34C759"
  echo "---"
  echo "👀 通常モードにする | bash=\"$SELF\" param1=off terminal=false refresh=true"
fi
