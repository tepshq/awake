# AWAKE 🌙→🚨

Mac を **「蓋を閉じても（外部ディスプレイ無しでも）スリープしない」** 状態に、
メニューバーから ON / OFF できる SwiftBar プラグインです。

- **OFF（通常）**: メニューバーに地味な 🌙
- **ON（寝ないモード）**: メニューバーで **「🚨 寝ないモード」⇔「☀️ AWAKE」が赤く点滅**
  → 付けっぱなしに一発で気づけます

---

## 仕組み

- 「蓋を閉じても寝ない」は `pmset -a disablesleep 1` でのみ実現できます（`caffeinate` や power assertion は蓋を閉じると効きません）。OFF は `pmset -a disablesleep 0`。
- このフラグは `pmset -g` の `System-wide power settings` → `SleepDisabled`（`1`=ON / なし・`0`=OFF）に出ます。**状態の読み取りはパスワード不要**です。
- 切り替えには **root が必要**ですが、AWAKE は sudoers の NOPASSWD 設定や特権ヘルパー（XPC）、Apple Developer 登録などを**一切しません**。代わりに macOS 標準の管理者ダイアログを使い、**切り替えるたびにパスワードを入力**します（権限の作り込みをしないぶん安全）。

  ```sh
  osascript -e 'do shell script "/usr/bin/pmset -a disablesleep 1" with administrator privileges'
  ```

---

## 動作要件

- macOS
- [Homebrew](https://brew.sh)
- [SwiftBar](https://github.com/swiftbar/SwiftBar)（インストーラが自動で入れます。SwiftBar 自体は署名済みアプリです）

---

## インストール

> ℹ️ **公開リポジトリ**前提です: <https://github.com/tepshq/awake>

### 最短: ネット越しに 1 行（おすすめ）

ターミナルにコピペして実行するだけ。SwiftBar の導入 → プラグイン配置 → 反映まで自動です。

```sh
curl -fsSL https://raw.githubusercontent.com/tepshq/awake/main/install.sh | bash
```

すでに SwiftBar を使っている人は、ブラウザや Slack で次のリンクをクリックするだけでも追加できます（プラグインのみ／SwiftBar 本体は別途必要）:

```
swiftbar://addplugin?src=https://raw.githubusercontent.com/tepshq/awake/main/plugins/awake.30s.sh
```

### 方法 A: リポジトリから（clone / zip）

```sh
git clone <このリポジトリ>        # もしくは zip を展開
cd awake
./install.sh
```

`install.sh` は次を自動で行います。

1. SwiftBar が無ければ `brew install --cask swiftbar`
2. SwiftBar のプラグインフォルダを判定（未設定なら `~/Library/Application Support/SwiftBar/Plugins` を作成して設定）
3. `plugins/awake.30s.sh` をそこへコピーして実行権限を付与
4. SwiftBar を起動 / リフレッシュ

> 初回起動時に SwiftBar から「プラグインフォルダを選んで」と聞かれたら、上の手順 2 と同じパスを指定してください。

### 方法 B: 手動

```sh
# 1. SwiftBar を入れる（初回のみ）
brew install --cask swiftbar

# 2. SwiftBar を起動し、プラグインフォルダを 1 つ決める
#    （例: ~/Library/Application Support/SwiftBar/Plugins）

# 3. プラグインをそのフォルダにコピーして実行権限を付与
cp plugins/awake.30s.sh "<プラグインフォルダ>/"
chmod +x "<プラグインフォルダ>/awake.30s.sh"

# 4. SwiftBar メニュー → Refresh All
```

---

## 使い方

1. メニューバーのアイコンをクリックしてメニューを開く
2. 状態に応じたボタンを押す
   - OFF のとき: **☀️ ONにする（蓋を閉じても寝ない）**
   - ON のとき: **🌙 OFFにする（通常スリープに戻す）**
3. macOS のパスワードダイアログが出るので入力 → 切り替わってメニューバー表示が更新されます

### メニューバーの見方

| 表示 | 状態 | 意味 |
|------|------|------|
| 🌙（グレー・地味） | OFF | 通常どおり、蓋を閉じるとスリープします |
| 「🚨 寝ないモード」⇔「☀️ AWAKE」（赤く点滅） | ON | 蓋を閉じても・外部ディスプレイ無しでもスリープしません |

> **状態は必ずメニューバーで確認できます。** ON のときは赤く点滅して強く主張するので、「気づかず付けっぱなし」を防げます。

### 点滅がうるさい場合

`plugins/awake.30s.sh` 冒頭の `BLINK=1` を `BLINK=0` にすると、点滅せず「🚨 寝ないモード」の赤いテキストのみになります（保存後 SwiftBar をリフレッシュ）。

---

## ⚠️ 注意

- **蓋を閉じて外部ディスプレイ無しのまま長時間 ON にすると発熱しやすい**です。カバンの中などでの放置に特に注意してください。
- ON はあくまで一時的な用途（ビルド・ダウンロード・配信などの放置作業）に。**用が済んだら OFF に戻す**運用を推奨します。状態が一目で分かる UI にしているのは、この「付けっぱなし事故」を防ぐためです。

---

## 更新方法

AWAKE は **2 ステップ**で更新します（GitHub を更新しても、各自の Mac は自動では新しくなりません）。

### ① 開発者: ソースを直して push

`plugins/awake.30s.sh` などを編集して push すると、`main` と raw URL が新しくなり、**以降に入れる人は自動で新版**になります。

```sh
cd awake
# 例: plugins/awake.30s.sh を編集したあと
git add -A
git commit -m "プラグインを更新"
git push
```

> 更新時は `plugins/awake.30s.sh` 冒頭の `<xbar.version>` を上げておくと、どの版か分かりやすいです。

### ② 利用者: 新版を取り込む

SwiftBar のプラグインは一度コピーしたら自動更新されません。**もう一度インストールの 1 行を実行するだけ**で最新になります。

```sh
curl -fsSL https://raw.githubusercontent.com/tepshq/awake/main/install.sh | bash
```

（clone 派は `git pull && ./install.sh`、`swiftbar://addplugin` 派は同じリンクを再クリックでも OK）

---

## アンインストール

```sh
./uninstall.sh
```

- スリープ抑止を OFF に戻し（パスワードを聞かれます）、プラグインファイルを削除します。
- SwiftBar 本体も消す場合: `brew uninstall --cask swiftbar`

---

## チーム配布

- **最短は、GitHub に公開して上の「1 行コマンド」を共有するだけ**です。各自はその 1 行を実行すれば、SwiftBar 導入からプラグイン配置まで完了します。
- リポジトリ（または `plugins/awake.30s.sh` 単体）を git / Slack / MDM で配布できます。
- 各自は **`brew install --cask swiftbar` を 1 回** ＋ **プラグイン 1 ファイルを配置**するだけ。`install.sh` を使えばこの両方を自動化できます。
- 配布物に秘密情報は含まれません（root 権限はあくまで実行時にパスワードで取得）。

---

## 技術メモ / FAQ

- **なぜ「アイコンを 1 クリックで即トグル」ではないの？**
  SwiftBar はメニューバーアイコンをクリックすると必ずドロップダウンが開く仕様で、「タイトルのクリック＝即アクション」はできません。そのためドロップダウン先頭の切り替えボタンを押す **実質 2 クリック**になります。これは「現在の ON/OFF をメニューバーに表示する」ための割り切りです（状態表示が不要なら Apple「ショートカット」で 1 クリック化も可能ですが、状態は出せません）。

- **自動 OFF タイマーは？**
  入れていません。OFF も root が必要で、AWAKE は「毎回パスワード」方針のため、**無人で勝手に OFF にすることが原理的にできません**（OFF のたびにパスワードダイアログが出てしまう）。中途半端になるため、代わりに **ON 中は赤く点滅**させて切り忘れに気づける UI にしています。

- **メニューバーの表示が実際の状態とズレる**
  プラグインは 30 秒ごと（ファイル名の `30s`）＋メニューを開いたときに自動更新します。手動で `pmset` を叩いた直後などは、メニューを開けば最新化されます。更新間隔を変えたい場合はファイル名の `30s` を `10s` などに変更してください。

- **実行している内容を確認したい**
  メニュー内の「ⓘ 仕組み / 実行コマンド」に、ON/OFF それぞれで実行する `pmset` コマンドを表示しています。

---

## リポジトリ構成

```
awake/
├── README.md
├── install.sh                  # SwiftBar 導入＋プラグイン配置を自動化
├── uninstall.sh                # OFF に戻してプラグイン削除
└── plugins/
    └── awake.30s.sh            # SwiftBar プラグイン本体（30秒ごとに状態を更新）
```
