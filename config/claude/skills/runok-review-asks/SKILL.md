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

## 最重要原則: 最小権限 (least privilege)

allow ルールは「そのコマンドが本来持てる能力の最も狭い範囲」に絞る。コマンド名だけで判断せず、**そのコマンドが何を実行できるか** を毎回評価する。

- 言語処理系 (`perl *`, `python *`, `node *`, `ruby *`, `awk *`, `nlx *`) は `-e` 等で任意コード実行できる。`-i -pe` のような特定オプション限定の literal でしか allow にしない
- `xargs <cmd>`, `find -exec <cmd>`, `bash -c <cmd>`, `eval <cmd>` 等は内側コマンドが任意。wrapper として登録して inner を rule 評価させる (詳細は step 3)
- `<tool> exec`, `<tool> run`, `<tool> shell` 系もインタープリタ的。同様に wrapper 化を優先する

ユーザーが「○○と同じで広く allow」と指示しても、コマンドの実態評価で危険なら**狭めて提案し直す**。広いまま追加するのは禁止。「sed -i と同じで perl も allow」のような類推は罠 (sed は engine が sed の DSL、perl は full programming language)。広い allow を書き込んだ後で「これ任意コード実行できる」と気付くのは事故。書く前に評価する。

## 前提

- スクリプト: `config/bin/runok-pending-asks` (PATH 済)
    - 出力は `runok audit --json` 生 JSONL そのまま (整形なし)。各エントリの `.command` は実行された compound 全体 (例: `cd foo && cargo new --bin tree-check`)、`.command_evaluations[]` に分解後の各サブコマンドと判定がある
    - `--action ask` がデフォルト。`--since` / `--limit` 等は素の `runok audit` と同じフラグを受け付ける
    - 現在 allow / deny に変わっているコマンドと、内部 `IGNORE_COMMANDS` 正規表現にマッチするコマンドは出力から除外済
- 書き込み先候補: `config/runok/{common,git,macos,opensrc,work}.yml` と `config/runok/{languages,tools}/*.yml`
- 設定は `runok.yml` の `extends:` で preset (例: `github:fohte/runok-presets/base`) と `config/runok/*.yml` を合成する。preset 側にも `definitions.wrappers` (bash -c / sh -c / time / env / sudo / xargs / find -exec 等) と readonly 系の allow が既にある
- 設定は symlink なので deploy 不要 (編集だけで反映)

## ワークフロー

ゴールに到達するまで以下を繰り返す。

### 0. セルフチェックリスト (毎ループ開始時)

頭の中で確認するのではなく、実際に該当ファイル / 出力を見て確認する。

- [ ] preset の `definitions.wrappers` を読んだか? (重複 wrapper 提案を防ぐ)
- [ ] preset の rules を読んだか? (重複 allow 提案を防ぐ)
- [ ] `IGNORE_COMMANDS` の現状を読んだか?
- [ ] 既存ルールに code smell (絶対パス, 過広 allow 等) はないか? あれば修正候補として記録
- [ ] wrapper 化可能な候補を ignore に流していないか?
- [ ] default は ask。「allow したくない = deny」になっていないか?
- [ ] user が明示承認した allow だけを書き込もうとしているか? 黙って混ぜていないか?
- [ ] 各 allow パターンの power (最小権限) を評価したか?
- [ ] CEL `when` の path 判定に `env.HOME` を使っているか? (絶対パス直書き禁止)

### 1. 既存資産の把握 (初回のみ)

- preset (`extends:` で参照される) の `definitions.wrappers` と rules を確認。`~/.cache/runok/presets/` 配下にダウンロード済み。最低限 wrappers 一覧は通読する
- `config/bin/runok-pending-asks` 内の `IGNORE_COMMANDS` を確認
- `config/runok/**/*.yml` の既存ルールを通読。code smell (絶対パス, 過広 allow など) を別途修正候補として記録する

### 2. 候補取得

`runok-pending-asks` を引数なしで呼ぶ。出力が空ならゴール達成、終了。

広く片付けたい初回は `--limit 500` などで母集団を広げてよい。2 周目以降は引数なしで良い (audit のデフォルト range が再走査される)。

### 3. 集計・正規化と disposition の事前割り当て

取得した生コマンド列をグルーピングし、**各グループに必ず disposition (allow 候補 / wrapper 候補 / ignore 候補) を先に割り当てる**。disposition 未定義のままユーザー提案に進まない。

- 同じ argv 前置きを持つコマンドをグルーピング (例: `gh pr view 1`, `gh pr view 2` → `gh pr view`)
- **候補ごとに risk profile を評価する**: そのパターンが allow されたとき「何が任意に実行可能になるか」を言語化する。以下は global allow を避けるべき代表例:
    - **任意コード実行系**: `cargo run *`, `npx *`, `python -c *`, `node -e *`, `perl *`, `awk *` 等
    - **任意 HTTP 書き込み系**: `gh api -X POST|PUT|PATCH|DELETE *`, `curl -X POST *` 等
    - **広域 destructive**: `rm` の `/tmp` 外、`git push --force *` 等
    - これらは「cwd / target を信頼する」前提無しに global allow にしない。狭い literal か wrapper 化か ignore を選ぶ
- **disposition 決定ルール**:
    - 内側コマンドを実行する形 (`bash -c <cmd>`, `eval <cmd>`, `time <cmd>`, `xargs <cmd>`, `find -exec`, `mise exec --` 等) → **wrapper 候補**。preset に既存ならそのまま inner が評価される。preset 未登録なら preset に追加する (`/delegate-claude` 等で別タスク化してよい)。**ignore に流す前に必ず wrapper 化を検討する**
    - 安全に広い allow が書ける (readonly な subcommand 群など) → **allow 候補** (適切な粒度のパターンを設計)
    - 狭い literal なら安全に allow できる → **allow 候補** (literal で)
    - 1 回しか出ておらず再発しなさそう → **ignore 候補** (allow するほどの価値がない)
    - 失敗 / 未インストールのコマンド → **ignore 候補**
    - risk profile 上 allow したくない → **ignore 候補** (deny ではない)
    - 「保留」は選択肢に存在しない
- **deny の閾値**: default が ask の以上、deny は「明確に害があり、ask で都度判断する余地もないほど常に間違っている」場合だけ。「allow したくない」は deny の理由にならない。allow が書けないなら ignore で済む
- **絶対パス禁止**: CEL `when` でユーザーホーム配下を判定する場合は `env.HOME + "/..."` を使う。`/Users/<name>/...` の直書き、`$HOME` 展開前提の書き方は禁止
- **ツール側に機能追加する選択肢も常に検討する**: runok / preset 等の user-owned ツールは変更可能。「現状の表現力だけで考えない」。代表例:
    - cwd で絞れれば安全に書ける (CEL `when` に該当変数が無い) → 変数追加
    - dev build 経由の起動を installed コマンドと同じルールで扱いたい → alias 機能追加
    - 内側コマンドが評価されない wrapper → preset の `definitions.wrappers` に追加
    - 失敗 / 未インストールのコマンドが ask として履歴に残る → 存在しないコマンドの auto-deny
    - 機能追加が別タスク化必要なら、暫定で ignore に入れて出力ゼロを優先する
- 書き込み先 yml を選ぶ (allow 候補のみ)
    - `git *` → `git.yml`
    - macOS 固有 (`defaults`, `osascript` 等) → `macos.yml`
    - `opensrc *` → `opensrc.yml`
    - work ロール固有 → `work.yml`
    - 言語/ツール固有 → `languages/<lang>.yml` / `tools/<tool>.yml`
    - それ以外の汎用コマンド → `common.yml`

### 4. ユーザーへの提案

提案表は確信度別 3 グループに分ける。**1 表に 100 件以上詰め込まない**。

- **確実 OK**: skill のルール上 disposition が一意に決まるもの。例: 高頻度の readonly subcommand (`tar tzf *`, `git stash list`, `brew list *` 等)、既知 wrapper の追加 (`bash -c <cmd>` 等)、任意コード実行系の ignore (`^cargo run` 等)。確認のため一度表として見せるが、原則 user は承認するだけ
- **borderline**: user の方針確認が要るもの。例: 広めの allow パターン (`<tool> *` で powerful な subcommand を含むか不明)、power の評価が分かれるもの、user 個人のワークフロー判断が必要なもの (PR の auto-merge を許すかなど)
- **不明**: 候補の意味自体が把握できていないもの。書き込みに進まず、別途調査して埋めてから再提案

確実 OK の表を最初に出し、user の確認後に書き込みに進む。borderline は別 turn で扱う。

| #   | disposition | 提案内容                        | 書き込み先 | 元コマンド (頻度)                          |
| --- | ----------- | ------------------------------- | ---------- | ------------------------------------------ |
| 1   | allow       | `gh pr view *`                  | git.yml    | `gh pr view 123` (5), `gh pr view 456` (2) |
| 2   | wrapper     | `bash -c <cmd>` (preset 側追加) | preset     | `bash -c '...'` (3)                        |
| 3   | ignore      | `^cargo run( \| $)` (IGNORE へ) | -          | `cargo run --bin foo` (1)                  |

採否は番号指定 (`1,3 だけ採用`、`2 は gh pr * に広げて`、`全部 OK` 等) で受ける。

**書き込みに混ぜてはいけないもの**:

- user が明示承認していない項目を「ついでに」追加するのは禁止。提案表に無かった候補は次の turn で別途出す
- skill のルール上 disposition が決まっている項目について、user に「ignore でいい?」「これでいい?」のような単純確認を繰り返すのも禁止 (= 「保留」の言い換えに当たる)。user 判断が要るのは **「skill のルールから外れた判断をしたい」とき** のみ (例: 通常 ignore のところを literal allow にしたい)

### 5. 書き込み

採用された disposition を反映する。

**allow ルール**: 対応する yml に追記。**全ルールに inline `tests:` を必須で付ける**。フォーマットは `config/runok/common.yml` の既存ルールに倣う:

```yaml
- allow: 'gh pr view *'
  tests:
      - allow: 'gh pr view 123'
      - allow: 'gh pr view 456'
```

tests には最低 1 件、提案を導いた実際のコマンドを入れる。広いパターン (`*` を含むもの) ほど tests を厚めにし、意図しないマッチを早期検出できるようにする。

**wrapper エントリ**: preset の `definitions.wrappers` に追加。preset 側変更は別リポジトリへの PR が必要 (`/delegate-claude` でデリゲートが定石)。

**ignore エントリ**: `config/bin/runok-pending-asks` の `IGNORE_COMMANDS` 配列に正規表現を 1 行追加。元コマンドから機械的に作る:

- `a wm new foo bar` → `^a wm new( |$)`
- 引数違いを許容する場合 (`^a wm new` で前方一致) を基本にする

### 6. テスト

`runok test -c <config>` を実行する。失敗した場合は LLM 側で原因を分析して修正する:

- パターンが意図と違う (例: 別ルールの deny と衝突) → パターンを狭める
- tests の expected が誤っている → tests を直す
- 既存ルールとの優先順位問題 → 該当ルールを取り下げて ignore に回す (出力ゼロのゴールを優先)

ユーザーに「どうしましょう?」と聞かない。直してリトライする。何度試しても通らない場合のみユーザーに報告。

### 7. 収束確認

`runok-pending-asks` を再実行する。

- 空出力 → ゴール達成、step 8 へ
- 残っている → step 0 (セルフチェック) に戻る。残ったエントリは「前回の処理で取りこぼした」「新規 ask が間に挟まった」のいずれか。同じ手順で disposition を割り当てて潰す

ループ回数の上限は設けない。出力ゼロが達成条件。

### 8. コミット

`runok test` が通り、`runok-pending-asks` が空になったら `commit` skill を呼び出す。scope は `runok` (および必要なら `bin`)。intent には「ask 履歴の allow ルール化 / ignore 整理」相当を書く。

## やらないこと

- 起動引数なしのときに「いつから?」「どこに書く?」とユーザーに細かく聞かない。自分で判断する
- deploy (`dot deploy -t runok` 等) は実行しない。runok 設定は symlink で即時反映される
- push は行わない (commit skill の責務に従う)
- 「残りは次回」で途中終了しない。出力ゼロに到達するまでループを抜けない
- default が ask で済むものを deny にしない (deny の閾値は高い)
- user が明示承認していない allow を「ついでに」追加しない
- wrapper 化できるコマンドを ignore に流さない (内側コマンドは rule 評価に乗せる)
- コマンド本来の能力を評価せず広い allow を書かない (最小権限の原則)
- CEL `when` に絶対パスを直書きしない (`env.HOME` を使う)
- preset / 既存ルールを読まずに「新規追加」と称して重複を提案しない
