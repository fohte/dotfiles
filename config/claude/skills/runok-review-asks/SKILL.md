---
name: runok-review-asks
description: Drive `runok-pending-asks` output to zero by converting each pending ask into either an allow rule under `config/runok/` or an entry in the IGNORE_COMMANDS list. Use only when the user explicitly asks to review pending `ask` entries / clean up `runok audit` / convert ask history into allow rules. Do not auto-trigger from incidental mentions of `runok audit`.
---

# runok-review-asks

`runok-pending-asks` で「過去 ask されたが現在もまだ ask のままのコマンド」を列挙し、**その出力をゼロにする**ことをゴールとする skill。

## ゴール

このセッションの終了条件は **`runok-pending-asks` が空出力を返すこと** ただ 1 つ。出力に残った各エントリは必ず以下のいずれかに振り分ける:

- **allow**: `config/runok/*.yml` にルール追記
- **ignore**: `config/bin/runok-pending-asks` の `IGNORE_COMMANDS` に正規表現追加

「保留」「次回検討」「ひとまず見送り」は禁止。これらを許すと判断保留が事実上の第 3 の選択肢になり、出力ゼロに到達しない。allow が安全に書けない候補は ignore に回す (後で必要になれば手動で外せる)。

## 前提

- スクリプト: `config/bin/runok-pending-asks` (PATH 済)
    - 出力は `runok audit --json` 生 JSONL そのまま (整形なし)。各エントリの `.command` は実行された compound 全体 (例: `cd foo && cargo new --bin tree-check`)、`.command_evaluations[]` に分解後の各サブコマンドと判定がある
    - `--action ask` がデフォルト。`--since` / `--limit` 等は素の `runok audit` と同じフラグを受け付ける
    - 現在 allow / deny に変わっているコマンドと、内部 `IGNORE_COMMANDS` 正規表現にマッチするコマンドは出力から除外済
- 書き込み先候補: `config/runok/{common,git,macos,opensrc,work}.yml`
- 設定は symlink なので deploy 不要 (編集だけで反映)

## ワークフロー

ゴールに到達するまで以下を繰り返す。1 周終わったら必ず step 1 に戻り、`runok-pending-asks` が空になるまでループする。

### 1. 候補取得

`runok-pending-asks` を引数なしで呼ぶ。出力が空ならゴール達成、終了。

広く片付けたい初回は `--limit 500` などで母集団を広げてよい。2 周目以降は引数なしで良い (audit のデフォルト range が再走査される)。

### 2. 集計・正規化と disposition の事前割り当て

取得した生コマンド列をグルーピングし、**各グループに必ず disposition (allow 候補 / ignore 候補) を先に割り当てる**。disposition 未定義のままユーザー提案に進まない。

- 同じ argv 前置きを持つコマンドをグルーピング (例: `gh pr view 1`, `gh pr view 2` → `gh pr view`)
- **候補ごとに risk profile を評価する**: そのパターンが allow されたとき「何が任意に実行可能になるか」を言語化する。以下は global allow を避けるべき代表例:
    - **任意コード実行系**: `cargo run *`, `npx *`, `bash -c *`, `sh -c *`, `eval *`, `python -c *`, `node -e *` 等。cwd や引数次第で任意のコードが走る
    - **任意 HTTP 書き込み系**: `gh api -X POST|PUT|PATCH|DELETE *`, `curl -X POST *` 等。リモートリソースを変更できる
    - **広域 destructive**: `rm` の `/tmp` 外、`git push --force *` 等
    - これらは「cwd / target を信頼する」前提無しに global allow にしない。狭い literal (`cargo run --quiet -- doctor` だけ等) か、ignore を選ぶ
- **disposition 決定ルール**:
    - 安全に広い allow が書ける → **allow 候補** (適切な粒度のパターンを設計)
    - 狭い literal なら安全に allow できる → **allow 候補** (literal で)
    - 1 回しか出ておらず再発しなさそう → **ignore 候補** (allow するほどの価値がない)
    - 失敗 / 未インストールのコマンド → **ignore 候補**
    - risk profile 上 allow したくない → **ignore 候補**
    - 「保留」は選択肢に存在しない
- **ツール側に機能追加する選択肢も常に検討する**: runok / その他 user-owned ツールは変更可能。「現状の表現力だけで考えない」。代表例:
    - cwd で絞れれば安全に書ける (CEL `when` に `cwd` 変数が無い) → cwd 変数追加
    - dev build 経由の起動を installed コマンドと同じルールで扱いたい → alias 機能追加
    - 失敗 / 未インストールのコマンドが ask として履歴に残る → 存在しないコマンドの auto-deny
    - ただし機能追加は別タスク化が必要なら、暫定で ignore に入れて出力ゼロを優先する
- 書き込み先 yml を選ぶ (allow 候補のみ)
    - `git *` → `git.yml`
    - macOS 固有 (`defaults`, `osascript` 等) → `macos.yml`
    - `opensrc *` → `opensrc.yml`
    - work ロール固有 → `work.yml`
    - それ以外の汎用コマンド → `common.yml`

### 3. ユーザーへの提案

全件 (allow 候補・ignore 候補ともに) を 1 つの表で出す。disposition 列を必ず含める:

| #   | disposition | 提案内容                        | 書き込み先 | 元コマンド (頻度)                          |
| --- | ----------- | ------------------------------- | ---------- | ------------------------------------------ |
| 1   | allow       | `gh pr view *`                  | common.yml | `gh pr view 123` (5), `gh pr view 456` (2) |
| 2   | allow       | `cargo run --quiet -- doctor`   | common.yml | 同 (3)                                     |
| 3   | ignore      | `^cargo run( \| $)` (IGNORE へ) | -          | `cargo run --bin foo` (1)                  |

採否は番号指定 (`1,3 だけ採用`、`2 は gh pr * に広げて`、`全部 OK` 等) で受ける。**「保留」と言われた候補は ignore に回す** (= 出力から除外する)。ユーザーが明示的に allow に変えない限り、保留は ignore と同じ扱いとして処理する。

### 4. 書き込み

採用された disposition を反映する。

**allow ルール**: 対応する yml に追記。**全ルールに inline `tests:` を必須で付ける**。フォーマットは `config/runok/common.yml` の既存ルールに倣う:

```yaml
- allow: 'gh pr view *'
  tests:
      - allow: 'gh pr view 123'
      - allow: 'gh pr view 456'
```

tests には最低 1 件、提案を導いた実際のコマンドを入れる。広いパターン (`*` を含むもの) ほど tests を厚めにし、意図しないマッチを早期検出できるようにする。

**ignore エントリ**: `config/bin/runok-pending-asks` の `IGNORE_COMMANDS` 配列に正規表現を 1 行追加。元コマンドから機械的に作る:

- `a wm new foo bar` → `^a wm new( |$)`
- 引数違いを許容する場合 (`^a wm new` で前方一致) を基本にする

### 5. テスト

`runok test` を実行する。失敗した場合は LLM 側で原因を分析して修正する:

- パターンが意図と違う (例: 別ルールの deny と衝突) → パターンを狭める
- tests の expected が誤っている → tests を直す
- 既存ルールとの優先順位問題 → 該当ルールを取り下げて ignore に回す (出力ゼロのゴールを優先)

ユーザーに「どうしましょう?」と聞かない。直してリトライする。何度試しても通らない場合のみユーザーに報告。

### 6. 収束確認

`runok-pending-asks` を再実行する。

- 空出力 → ゴール達成、step 7 へ
- 残っている → step 2 に戻る。残ったエントリは「前回の処理で取りこぼした」「新規 ask が間に挟まった」のいずれか。同じ手順で disposition を割り当てて潰す

ループ回数の上限は設けない。出力ゼロが達成条件。

### 7. コミット

`runok test` が通り、`runok-pending-asks` が空になったら `commit` skill を呼び出す。scope は `runok` (および必要なら `bin`)。intent には「ask 履歴の allow ルール化 / ignore 整理」相当を書く。

## やらないこと

- 起動引数なしのときに「いつから?」「どこに書く?」とユーザーに細かく聞かない。自分で判断する
- deploy (`dot deploy -t runok` 等) は実行しない。runok 設定は symlink で即時反映される
- push は行わない (commit skill の責務に従う)
- 「残りは次回」で途中終了しない。出力ゼロに到達するまでループを抜けない
