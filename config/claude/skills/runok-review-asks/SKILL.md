---
name: runok-review-asks
description: Triage `runok audit` ask entries and convert recurring ones into allow rules under `config/runok/`. Use only when the user explicitly asks to review pending `ask` entries / clean up `runok audit` / convert ask history into allow rules. Do not auto-trigger from incidental mentions of `runok audit`.
---

# runok-review-asks

`runok-pending-asks` で「過去 ask されたが現在もまだ ask のままのコマンド」を列挙し、allow ルール化を半自動で進める skill。

## 前提

- スクリプト: `config/bin/runok-pending-asks` (PATH 済)
    - 出力は `runok audit --json` 生 JSONL そのまま (整形なし)。各エントリの `.command` は実行された compound 全体 (例: `cd foo && cargo new --bin tree-check`)、`.command_evaluations[]` に分解後の各サブコマンドと判定がある
    - `--action ask` がデフォルト。`--since` / `--limit` 等は素の `runok audit` と同じフラグを受け付ける
    - 現在 allow / deny に変わっているコマンドと、内部 `IGNORE_COMMANDS` 正規表現にマッチするコマンドは出力から除外済
- 書き込み先候補: `config/runok/{common,git,macos,opensrc,work}.yml`
- 設定は symlink なので deploy 不要 (編集だけで反映)

## ワークフロー

### 1. 候補取得

`runok-pending-asks` を呼び出して JSONL を取得する。`--since` / `--limit` はタスクの文脈に応じて選ぶ:

- 普段の片付け: 引数なし (全期間、audit のデフォルト `--limit 50`)
- 件数が少なくて広く見たい: `--limit 500` など
- 直近の検証: `--since 1d` など

### 2. 集計・正規化

取得した生コマンド列から、自分で以下を判断する:

- 同じ argv 前置きを持つコマンドをグルーピング (例: `gh pr view 1`, `gh pr view 2` → `gh pr view`)
- **候補ごとに risk profile を評価する**: そのパターンが allow されたとき「何が任意に実行可能になるか」を言語化する。以下は global allow を避けるべき代表例:
    - **任意コード実行系**: `cargo run *`, `npx *`, `bash -c *`, `sh -c *`, `eval *`, `python -c *`, `node -e *` 等。cwd や引数次第で任意のコードが走る
    - **任意 HTTP 書き込み系**: `gh api -X POST|PUT|PATCH|DELETE *`, `curl -X POST *` 等。リモートリソースを変更できる
    - **広域 destructive**: `rm` の `/tmp` 外、`git push --force *` 等
    - これらは「cwd / target を信頼する」前提無しに global allow にしない。狭い literal (`cargo run --quiet -- doctor` だけ等) か、ask 維持を選ぶ
- **安全に allow できない候補は「ask 維持」で諦めない**: 以下を選択肢に並べてユーザーに提示する
    - ask 維持
    - 狭い literal で部分許可
    - **ツール側に機能追加**: runok / その他 user-owned ツールは変更可能。「現状の表現力だけで考えない」。runok 側の機能拡張で解決する代表例:
        - cwd で絞れれば安全に書ける (CEL `when` に `cwd` 変数が無い) → cwd 変数追加
        - dev build 経由の起動を installed コマンドと同じルールで扱いたい → alias 機能追加
        - 失敗 / 未インストールのコマンドが ask として履歴に残る → 存在しないコマンドの auto-deny
- 適切な runok パターンを設計 (`gh pr view *` / `cargo run --quiet -- doctor` のような literal、など)
    - 広げすぎると意図せず危険なサブコマンドまで通る。`gh *` のような全許可は避け、サブコマンド粒度で止める
    - 1 回しか出ていないものは無理に allow 化せず、提案に含めるかをコスト感で判断
- 書き込み先 yml を選ぶ
    - `git *` → `git.yml`
    - macOS 固有 (`defaults`, `osascript` 等) → `macos.yml`
    - `opensrc *` → `opensrc.yml`
    - work ロール固有 → `work.yml`
    - それ以外の汎用コマンド → `common.yml`

### 3. ユーザーへの提案

提案は全件まとめて 1 つの表で出す:

| #   | 提案パターン                  | 書き込み先 | 元コマンド (頻度)                          |
| --- | ----------------------------- | ---------- | ------------------------------------------ |
| 1   | `gh pr view *`                | common.yml | `gh pr view 123` (5), `gh pr view 456` (2) |
| 2   | `cargo run --quiet -- doctor` | common.yml | 同 (3)                                     |

採否は番号指定 (`1,3 だけ採用`、`2 は gh pr * に広げて`、`全部 OK` 等) で受ける。

### 4. 書き込み

採用されたルールを対応する yml に追記する。**全ルールに inline `tests:` を必須で付ける**。フォーマットは `config/runok/common.yml` の既存ルールに倣う:

```yaml
- allow: 'gh pr view *'
  tests:
      - allow: 'gh pr view 123'
      - allow: 'gh pr view 456'
```

tests には最低 1 件、提案を導いた実際のコマンドを入れる。広いパターン (`*` を含むもの) ほど tests を厚めにし、意図しないマッチを早期検出できるようにする。

### 5. テスト

`runok test` を実行する。失敗した場合は LLM 側で原因を分析して修正する:

- パターンが意図と違う (例: 別ルールの deny と衝突) → パターンを狭める
- tests の expected が誤っている → tests を直す
- 既存ルールとの優先順位問題 → 問題のあるルールを取り下げる

ユーザーに「どうしましょう?」と聞かない。直してリトライする。何度試しても通らない場合のみユーザーに報告。

### 6. ユーザーが「無視」したコマンドの処理

ステップ 3 でユーザーが採用せず「これは恒久的に無視」と意思表示したコマンドは、自動で `config/bin/runok-pending-asks` の `IGNORE_COMMANDS` 配列に正規表現として追記する (確認なし)。書き込みは Edit ツールで配列内に 1 行追加。

正規表現は元コマンドから機械的に作る:

- `a wm new foo bar` → `^a wm new( |$)`
- 引数違いを許容する場合 (`^a wm new` で前方一致) を基本にする

### 7. コミット

`runok test` が通り、`IGNORE_COMMANDS` の更新も済んだら `commit` skill を呼び出す。scope は `runok` (および必要なら `bin`)。intent には「ask 履歴の allow ルール化」相当を書く。

## やらないこと

- 起動引数なしのときに「いつから?」「どこに書く?」とユーザーに細かく聞かない。自分で判断する
- deploy (`dot deploy -t runok` 等) は実行しない。runok 設定は symlink で即時反映される
- push は行わない (commit skill の責務に従う)
