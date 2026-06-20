#!/bin/bash
#
# AWAKE — AWAKE モード（蓋を閉じてもスリープしない）をメニューバーからトグル
#
# <xbar.title>AWAKE</xbar.title>
# <xbar.version>v1.1.0</xbar.version>
# <xbar.author>テープス株式会社</xbar.author>
# <xbar.desc>AWAKE モード（蓋を閉じても外部ディスプレイ無しでもMacをスリープさせない）をメニューバーからON/OFF。長時間ONになると「必ずオフ」ダイアログを出します（時間はメニューで設定可）。</xbar.desc>
# <xbar.dependencies>macOS,pmset</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#
# アイコン: 👀 通常モード(OFF) / 👁️ AWAKE モード(ON)
#
# 仕組み:
#   ON  = /usr/bin/pmset -a disablesleep 1   (root)
#   OFF = /usr/bin/pmset -a disablesleep 0   (root)
#   root取得は osascript の管理者ダイアログ(毎回パスワード)。状態読みはパスワード不要。

# do shell script はPATHが限定されるため、コマンドは必ず絶対パスで。
PMSET="/usr/bin/pmset"
AWK="/usr/bin/awk"
OSASCRIPT="/usr/bin/osascript"

# 状態・設定の保存場所
STATE_DIR="$HOME/Library/Application Support/AWAKE"
ON_SINCE_FILE="$STATE_DIR/on_since"        # AWAKE モードになった時刻
MODAL_LOCK_FILE="$STATE_DIR/modal.lock"    # 「必ずオフ」モーダル稼働中の目印
MODAL_AFTER_FILE="$STATE_DIR/modal_after"  # オフ強制までの秒数(メニューで設定)

MODAL_AFTER_DEFAULT=28800   # 既定 8時間

# 色
GREEN="#34C759"
GRAY="#8E8E93"
BLUE="#0A84FF"

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

# 「必ずオフ」モーダル。OFF が成功するまでダイアログを出し続ける（バックグラウンド）。
# $1 = 表示メッセージ。二重起動を防ぐため osascript の PID をロックに記録する。
show_force_off_modal() {
  (
    "$OSASCRIPT" - "$1" <<'APPLESCRIPT' &
on run argv
  set msg to item 1 of argv
  repeat
    try
      display dialog msg with title "⚠️ AWAKE" buttons {"オフにする"} default button 1 with icon stop
      do shell script "/usr/bin/pmset -a disablesleep 0" with administrator privileges
      exit repeat
    on error
      -- キャンセルされてもループ継続（オフするまで出し続ける）
    end try
  end repeat
end run
APPLESCRIPT
    osapid=$!
    printf '%s' "$osapid" > "$MODAL_LOCK_FILE"
    wait "$osapid"
    rm -f "$MODAL_LOCK_FILE"
  ) >/dev/null 2>&1 &
}

# ---- クリック時のアクション ----
case "$1" in
  on)     set_disablesleep 1; exit 0 ;;
  off)    set_disablesleep 0; exit 0 ;;
  toggle) [ "$(get_state)" = "on" ] && set_disablesleep 0 || set_disablesleep 1; exit 0 ;;
  set-modal) mkdir -p "$STATE_DIR"; printf '%s' "$2" > "$MODAL_AFTER_FILE"; exit 0 ;;
esac

# ---- 設定値の読み込み（無効/0なら既定）----
MODAL_AFTER="$(cat "$MODAL_AFTER_FILE" 2>/dev/null)"
case "$MODAL_AFTER" in ''|*[!0-9]*|0) MODAL_AFTER=$MODAL_AFTER_DEFAULT ;; esac

# ---- メニュー描画 ----
SELF="$0"
STATE="$(get_state)"
NOW="$(date +%s)"

# AWAKE モード継続時間の管理
ELAPSED=0
if [ "$STATE" = "on" ]; then
  mkdir -p "$STATE_DIR"
  SINCE="$(cat "$ON_SINCE_FILE" 2>/dev/null)"
  case "$SINCE" in
    ''|*[!0-9]*) SINCE="$NOW"; printf '%s' "$NOW" > "$ON_SINCE_FILE" ;;
  esac
  ELAPSED=$(( NOW - SINCE ))
  [ "$ELAPSED" -lt 0 ] && ELAPSED=0
else
  rm -f "$ON_SINCE_FILE" "$MODAL_LOCK_FILE" 2>/dev/null
fi

# 「オフ強制までの時間」設定（親に現在値、サブで変更）
emit_settings() {
  mark() { [ "$MODAL_AFTER" = "$1" ] && printf "✓ " || printf "   "; }
  echo "---"
  echo "オフ強制まで：$(( MODAL_AFTER / 3600 ))時間 | color=$GRAY size=12"
  echo "--$(mark 14400)4時間 | bash=\"$SELF\" param1=set-modal param2=14400 terminal=false refresh=true"
  echo "--$(mark 28800)8時間 | bash=\"$SELF\" param1=set-modal param2=28800 terminal=false refresh=true"
  echo "--$(mark 43200)12時間 | bash=\"$SELF\" param1=set-modal param2=43200 terminal=false refresh=true"
}

# ---- 出力（メニューバー1行 → --- → ドロップダウン）----
if [ "$STATE" = "off" ]; then
  echo "👀 | size=15"
  echo "---"
  echo "👀 通常モード | size=14 color=$GRAY"
  echo "👁️ AWAKE モードにする | bash=\"$SELF\" param1=on terminal=false refresh=true size=14 color=$GREEN"
  emit_settings
else
  echo "👁️ | size=15"
  echo "---"
  echo "👁️ AWAKE モード | size=14 color=$GREEN"
  echo "👀 通常モードにする | bash=\"$SELF\" param1=off terminal=false refresh=true size=14 color=$BLUE"
  emit_settings
fi

# ---- 設定時間を超えたら「必ずオフ」モーダルを出す（オフするまで復活）----
if [ "$STATE" = "on" ] && [ "$MODAL_AFTER" -gt 0 ] && [ "$ELAPSED" -ge "$MODAL_AFTER" ]; then
  running=0
  if [ -f "$MODAL_LOCK_FILE" ]; then
    pid="$(cat "$MODAL_LOCK_FILE" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && running=1
  fi
  if [ "$running" = "0" ]; then
    hrs=$(( MODAL_AFTER / 3600 ))
    show_force_off_modal "AWAKE モードが${hrs}時間以上続いています。安全のため、一度オフにしてください。"
  fi
fi
