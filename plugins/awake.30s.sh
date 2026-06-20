#!/bin/bash
#
# AWAKE — 蓋を閉じてもスリープしないモードをメニューバーからトグル
#
# <xbar.title>AWAKE</xbar.title>
# <xbar.version>v1.0.1</xbar.version>
# <xbar.author>TePs</xbar.author>
# <xbar.desc>蓋を閉じても(外部ディスプレイ無しでも)Macをスリープさせない状態をメニューバーからON/OFF。ON中はメニューバーで赤く点滅して強く警告します。</xbar.desc>
# <xbar.dependencies>macOS,pmset</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#
# 仕組み:
#   ON  = /usr/bin/pmset -a disablesleep 1   (root必須)
#   OFF = /usr/bin/pmset -a disablesleep 0   (root必須)
#   root取得は osascript の「管理者として実行」ダイアログ(毎回パスワード入力)で行う。
#   状態読み取りは pmset -g の SleepDisabled を見るだけなのでパスワード不要。
#
# アイコン:
#   👀 = 普通(OFF) / 👁️ = 寝ないモード(ON) / 🚨 = アラート(ON中の点滅相方)

# ===== 設定 =====================================================
# ON中のメニューバーを点滅させて最大限目立たせる。
#   1 = 点滅あり(👁️ ⇔ 🚨 を赤⇔橙で交互) … 付けっぱなし事故を最も防ぎやすい(既定)
#   0 = 点滅なし(👁️ のみ)
BLINK=1

# do shell script はPATHが限定されるため、コマンドは必ず絶対パスで。
PMSET="/usr/bin/pmset"
AWK="/usr/bin/awk"
OSASCRIPT="/usr/bin/osascript"
# ================================================================

# 現在の状態を返す: "on" または "off"
# SleepDisabled の行が無い/0 の場合は off 扱い。
get_state() {
  local v
  v="$("$PMSET" -g | "$AWK" '/SleepDisabled/{print $2; exit}')"
  if [ "$v" = "1" ]; then
    echo "on"
  else
    echo "off"
  fi
}

# disablesleep を切り替える(root)。$1 = 1 または 0。
# 管理者ダイアログでパスワードを入力させる。キャンセル時は何もしない(非0終了)。
set_disablesleep() {
  "$OSASCRIPT" -e "do shell script \"$PMSET -a disablesleep $1\" with administrator privileges" >/dev/null 2>&1
  return $?
}

# ---- クリック時のアクション(SwiftBarが param1 を渡して再実行する) ----
case "$1" in
  on)
    set_disablesleep 1
    exit 0
    ;;
  off)
    set_disablesleep 0
    exit 0
    ;;
  toggle)
    if [ "$(get_state)" = "on" ]; then
      set_disablesleep 0
    else
      set_disablesleep 1
    fi
    exit 0
    ;;
esac

# ---- ここから下: 引数なし = メニュー描画 ----
SELF="$0"   # SwiftBar はプラグインを絶対パスで実行する
STATE="$(get_state)"

if [ "$STATE" = "on" ]; then
  # === メニューバー: ON中は超目立たせる（👁️ ⇔ 🚨 の点滅）===
  # 最初の "---" より前に複数行を出すと SwiftBar がフレームとして交互表示(=点滅)する。
  echo "👁️ | color=#FF3B30 size=14"
  if [ "$BLINK" = "1" ]; then
    echo "🚨 | color=#FF9500 size=14"
  fi

  echo "---"
  echo "👁️ 蓋を閉じても寝ません (ON) | color=#FF3B30 size=14"
  echo "外部ディスプレイ無しでもスリープしません | size=12 color=#FF3B30"
  echo "---"
  echo "👀 OFFにする（通常スリープに戻す） | bash=\"$SELF\" param1=off terminal=false refresh=true color=#0A84FF"
else
  # === メニューバー: OFF(普通)は地味に 👀 ===
  echo "👀 | color=#8E8E93 size=14"

  echo "---"
  echo "👀 通常スリープ (OFF) | color=#8E8E93 size=14"
  echo "蓋を閉じると通常どおりスリープします | size=12 color=#8E8E93"
  echo "---"
  echo "👁️ ONにする（蓋を閉じても寝ない） | bash=\"$SELF\" param1=on terminal=false refresh=true color=#FF9500"
fi

# ---- 共通フッタ ----
echo "---"
echo "⚠️ 注意: 蓋を閉じて外部ディスプレイ無しのまま長時間ONにすると発熱しやすいです | color=#FF9500 size=12"
echo "---"
echo "ⓘ 仕組み / 実行コマンド | color=#8E8E93"
echo "--ON:  $PMSET -a disablesleep 1 | font=Menlo size=11 color=#8E8E93"
echo "--OFF: $PMSET -a disablesleep 0 | font=Menlo size=11 color=#8E8E93"
echo "--管理者権限が必要です（切り替えるたびにパスワードを入力します） | size=11 color=#8E8E93"
echo "---"
echo "更新 | refresh=true"
