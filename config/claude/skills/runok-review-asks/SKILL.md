---
name: runok-review-asks
description: Drive `runok-pending-asks` output to zero by converting each pending ask into either an allow rule under `config/runok/` or an entry in the IGNORE_COMMANDS list. Use only when the user explicitly asks to review pending `ask` entries / clean up `runok audit` / convert ask history into allow rules. Do not auto-trigger from incidental mentions of `runok audit`.
---

# runok-review-asks

`runok-pending-asks` で「過去 ask されたが現在もまだ ask のままのコマンド」を列挙し、**その出力をゼロにする**ことをゴールとする skill。

## ゴール

このセッションの終了条件は **`runok-pending-asks` が空出力を返すこと** ただ 1 つ。出力に残った各エントリは必ず以下のいずれかに振り分ける:

- **allow**: dotfiles の `config/runok/*.yml` または対象 repo の `runok.local.yml` にルール追記。現機能で安全に書けない場合は「runok / preset にどの機能があれば書けるか」を言語化し、機能追加を別タスク化したうえで暫定 ignore する
- **deny**: 明確に害があり、ask で都度判断する余地もないコマンドだけ。閾値は高い
- **ignore (= 意図的に ask 維持)**: `config/bin/runok-pending-asks` の `IGNORE_COMMANDS` に正規表現追加。**user が毎回明示的に判断したい** ものに限る (例: `gh pr merge` を都度承認したい)

「保留」「次回検討」「ひとまず見送り」は禁止。これらを許すと判断保留が事実上の第 4 の選択肢になり、出力ゼロに到達しない。**「allow が書けないからとりあえず ignore」は禁止** — ignore は positive intent (ask を意図的に残したい) でのみ使う。書けない理由が runok の表現力不足なら、必要な機能を言語化して別タスク化し、その上で暫定 ignore する。

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
- [ ] risk 評価が必要な候補を sub-agent batch に分けたか? (main 単独一括評価になっていないか)
- [ ] CEL `when` の path 判定に `env.HOME` を使っているか? (絶対パス直書き禁止)

### 1. 既存資産の把握 (初回のみ)

- preset (`extends:` で参照される) の `definitions.wrappers` と rules を確認。`~/.cache/runok/presets/` 配下にダウンロード済み。最低限 wrappers 一覧は通読する
- `config/bin/runok-pending-asks` 内の `IGNORE_COMMANDS` を確認
- `config/runok/**/*.yml` の既存ルールを通読。code smell (絶対パス, 過広 allow など) を別途修正候補として記録する
- **runok 機能の有無を断言する前に schema を見る**。`https://raw.githubusercontent.com/fohte/runok/main/schema/runok.schema.json` を fetch して `definitions.{aliases,wrappers,vars,flag_groups,paths,sandbox}` 等を grep する。「機能無い」と user に答える前に必ず schema を確認 — 思い込みで断言しない

### 2. 候補取得

`runok-pending-asks` を呼ぶ。出力が空ならゴール達成、終了。

**user が scope を指定した場合は必ず `runok audit` の対応フラグを渡す** (引数なし → 全件、ではない):

- 「<repo> のだけ」→ `--dir <repo path>` (cwd 基準フィルタ。その repo を cwd として実行された全コマンドが対象で、コマンド自体の repo 関連性で絞れるわけではない点を user に説明する)
- 「<command 名> のだけ」→ `--command <substring>`
- 「最近 / 今日 / 今週」→ `--since 1h|7d|<date>`

複数組合せ可。広く片付けたい初回は `--limit 500` 等で母集団を広げる。2 周目以降は前回成果を引き継ぐため同 scope で再走査する。

### 3. 集計・正規化と disposition の事前割り当て

取得した生コマンド列をグルーピングし、**各グループに必ず disposition (allow 候補 / wrapper 候補 / deny 候補 / ignore 候補) を先に割り当てる**。disposition 未定義のままユーザー提案に進まない。

- 同じ argv 前置きを持つコマンドをグルーピング (例: `gh pr view 1`, `gh pr view 2` → `gh pr view`)
- **subcommand の実在を確認**。allow/deny を設計する前に、対象 subcommand が `<cmd> --help` 等で実在することを確認する。typo や過去 API 残骸で実在しない subcommand を deny rule で塞いでも意味が無い (CLI 側で unknown verb として失敗するだけ)。実在しない subcommand は runok の「unknown subcommand auto-deny」機能領域で、現状は暫定 ignore + 機能追加別タスク化で対応する

#### 3a. risk 評価の sub-agent への分割委任 (必須)

**禁止**: main が単独で全候補の risk profile 評価と最小権限パターン設計を一括で行うこと。N 候補をまとめて処理すると後半ほど判断が雑になり、危険な任意コード実行系を「他と同じノリで」広い allow に分類する事故が起きる。1 エージェント内で risk profile を全件評価する近道を取ってはならない。

main がやるのはここまで:

- グルーピング + subcommand 実在確認
- **機械的に決まるもの**だけを即振り分け。fast-path に積める条件は以下 2 種類のみ:
    - 既存 preset wrapper にそのまま乗るもの (例: `bash -c '<cmd>'`、`time <cmd>`) → wrapper 適用済として扱い、内側を別候補として再評価対象に
    - **既存 allow ルールに literal で一致**する重複 → 報告のみ (書き込み対象外)
- 上記 2 種類**以外は全部 sub-agent に回す**。「risk profile は自明」「機械的に ignore で良い」と感じても fast-path に積まない (これが 3a 違反の典型)
- **fast-path 件数の上限**: 候補総数の 30% 未満を目安。fast-path が多数を占めるなら main で risk 評価を一括している兆候 → 戻ってやり直し

それ以外 (= risk 評価が必要な候補) は **5-10 候補単位の batch** に分け、**`general-purpose` sub-agent を並列で起動**して各 batch を評価させる。並列起動は単一メッセージ内で複数 Agent ツール呼び出しを束ねる。候補総数が 3 件以下のときだけ main 内で処理してよい (overhead が見合わない)。

sub-agent prompt には必ず以下を含める (自己完結させる):

- 担当 batch の候補リスト (元コマンドと頻度)
- 本 skill の「最重要原則: 最小権限」セクション全文
- 下の「4a. 各 disposition は固定チェックリストに具体事実で答える」全文 (**SKILL.md の現行版をそのまま転記すること。prompt テンプレに固定化しない**。4a の唯一の source of truth は SKILL.md)
- 下の「3c. disposition 決定ルール」全文 (同上 — disposition 選択フロー)
- 出力フォーマット: 候補ごとに `{disposition, pattern, rationale, risk_profile, suggested_tests, writeto}` を返させる。`rationale` は 4a の R1-R5 / Q1-Q2 / D1-D2 を全件埋めた構造化データとして返すこと
- 強制ルール: 「4a のチェック項目を具体事実で埋められない場合は ignore を選べ。buzzword (`readonly` / `安全` / `狭い` 等の根拠なし語) で埋めるのは違反」

sub-agent 結果に対する main の編集権限:

- **狭める方向 可**: `<tool> *` → `<tool> <subcommand> *` 等
- **ignore への降格 可**
- **wrapper 化見落としの補完 可**: ignore とされた候補に wrapper 化可能なものがあれば wrapper 候補へ振り直す
- **緩める方向 不可**: sub-agent の ignore 判定を main 独断で allow に格上げしない。緩めたい場合のみ borderline として user に提示

#### 3b. risk profile カテゴリ

allow 不可ルートに倒すべき代表カテゴリ。詳細評価項目とフォーマットは **4a の R1-R3** が SSoT。

- **任意コード実行系** (4a R1): `cargo run *`, `npx *`, `python -c *`, `node -e *`, `perl *`, `awk *` 等
- **任意 HTTP 書き込み系** (4a R2): `gh api -X POST|PUT|PATCH|DELETE *`, `curl -X POST *` 等
- **広域 destructive** (4a R3): `rm` 系、`git push --force *` 等

これらは「cwd / target を信頼する」前提無しに global allow にしない。狭い literal か wrapper 化か ignore を選ぶ。

#### 3c. disposition 決定ルール

- 内側コマンドを実行する形 (`bash -c <cmd>`, `eval <cmd>`, `time <cmd>`, `xargs <cmd>`, `find -exec`, `mise exec --` 等) → **wrapper 候補**。preset に既存ならそのまま inner が評価される。preset 未登録なら 3d の判断で preset / dotfiles / repo-local のいずれかに追加 (preset 追加は runok-presets README policy を満たす universal wrapper のみ。stack-specific は dotfiles)
- 安全に広い allow が書ける (readonly な subcommand 群など) → **allow 候補** (適切な粒度のパターンを設計)
- 狭い literal なら安全に allow できる → **allow 候補** (literal で)
- 一見 risky だが cwd 限定 / argv 制約 / wrapper 化 / CEL `when` / `<var:>` / `definitions.aliases` 等で安全 allow に書き換えられる → **allow 候補**。「現状の表現力だけ」で考えず、runok 機能を駆使する
- 現状の runok 機能では安全 allow が書けない → **runok 機能追加領域**。必要な機能を言語化 (例: URL host helper、unknown subcommand auto-deny、git-tracked path helper、二重 wrapper) し、別タスク化。暫定 ignore で出力ゼロを保つが、`# awaiting runok feature: <feature name>` のコメントを付ける
- user が **意図的に毎回 ask したい** (例: `gh pr merge` を都度承認したい、destructive op を毎回判断したい) → **ignore 候補**。これが ignore の本来意味
- 「保留」「allow したくないからとりあえず ignore」は選択肢に存在しない

**ignore の本来意味**: ignore は「default の ask 動作を維持する」+「review 対象から外す」の組合せ。「user が毎回明示判断したいから ask を継続したい」という positive intent でだけ使う。「allow できない時の捨て場」として使うと、本当に意図的 ask したい項目との区別が消え、後で見直す手がかりも失う。

**deny の閾値**: deny は「明確に害があり、ask で都度判断する余地もないほど常に間違っている」場合だけ。「allow したくない」は deny の理由にならない。`deny` にすると user が「ask flow を回したい」場合も塞いでしまうので、稀にでも意図的に実行したい余地があれば ignore (= ask 維持) を選ぶ。

**絶対パス禁止**: CEL `when` でユーザーホーム配下を判定する場合は `env.HOME + "/..."` を使う。`/Users/<name>/...` の直書き、`$HOME` 展開前提の書き方は禁止。

**ツール側に機能追加する選択肢も常に検討する**: runok / preset 等の user-owned ツールは変更可能。「現状の表現力だけで考えない」。代表例:

- cwd で絞れれば安全に書ける (CEL `when` に該当変数が無い) → 変数追加
- dev build 経由の起動を installed コマンドと同じルールで扱いたい (例: runok repo で `cargo run -- check` を `runok check` と同じ allow rule で扱う) → `definitions.aliases` を使う
- 内側コマンドが評価されない wrapper → 3d の判断で配置 (preset: universal な inner-evaluating wrapper のみ / dotfiles: stack-specific な wrapper、例: `docker exec <c> sh -c <inner>` / `uvx [--from *] <cmd>`)
- 失敗 / 未インストールのコマンドが ask として履歴に残る → 存在しないコマンドの auto-deny 機能
- URL の host 部分で絞りたい (`curl -X POST http://localhost:*` のみ allow) → CEL の URL parse helper
- 機能追加が別タスク化必要なら、暫定で ignore に入れて出力ゼロを優先する

#### 3d. 書き込み先の選択

allow / deny / wrapper / `definitions.*` すべてに共通して、以下の優先順で配置場所を決める:

1. **preset (`github:fohte/runok-presets/*`)**: **stack-agnostic で virtually every developer が使う universal なものだけ**。`runok-presets` README (https://github.com/fohte/runok-presets#presets) の policy を必ず確認すること。policy 抜粋:
    - 対象: Unix utilities、popular modern alternatives、git、GitHub CLI (`gh`)、`bash -c` / `sh -c` / `time` / `env` / `sudo` / `xargs` / `find -exec` のような universal wrapper
    - **対象外**: infrastructure tools (docker / kubectl)、cloud CLIs (aws / gcloud / az)、language runtimes (node / python / ruby / rust)、package managers (npm / cargo / pip / uv / nlx / uvx 等)
    - 「fohte の手元では普遍的」≠ 「preset 受益者全員に普遍的」。fohte 個人 workflow に閉じるなら preset でなく dotfiles。preset PR を提案する前に「stack 問わず誰でも使うか」を判断すること
2. **dotfiles (`~/ghq/github.com/fohte/dotfiles/config/runok/...`)**: 複数 repo で共通に意味を持つ rule。fohte の workflow で広く使う stack-specific な wrapper / allow (例: `uvx <cmd>` wrapper、docker / mise の subcommand allow)、cross-cutting な deny
3. **対象 repo の `runok.local.yml`** (無ければ新規作成): その repo 固有の literal allow。project-specific subcommand (`cargo run -- <project subcmd>` 等)、repo 内 script path、repo 内サービス向け curl 等。他 repo で意味を持たない literal

判断軸:

- preset vs dotfiles: 「stack 問わず誰でも使うか」= preset / 「fohte 個人または特定 stack に閉じるか」= dotfiles。preset 配置は runok-presets README policy に従って判定
- dotfiles vs repo-local: 「fohte の他の repo でも有用か」= dotfiles / 「この repo 限定の慣習に依存するか」= repo local

dotfiles 内の yml 選択 (allow / deny / wrapper / definitions 共通):

- `git *` → `git.yml`
- macOS 固有 (`defaults`, `osascript` 等) → `macos.yml`
- `opensrc *` → `opensrc.yml`
- work ロール固有 → `work.yml`
- 言語/ツール固有 → `languages/<lang>.yml` / `tools/<tool>.yml` (例: `uvx <cmd>` wrapper → `languages/python.yml`)
- それ以外の汎用コマンド → `common.yml`

### 4. ユーザーへの提案

提案表は確信度別 3 グループに分ける。**1 表に 100 件以上詰め込まない**。

- **確実 OK**: skill のルール上 disposition が一意に決まるもの。例: 高頻度の readonly subcommand (`tar tzf *`, `git stash list`, `brew list *` 等)、既知 wrapper の追加 (`bash -c <cmd>` 等)、任意コード実行系の ignore (`^cargo run` 等)。確認のため一度表として見せるが、原則 user は承認するだけ
- **borderline**: user の方針確認が要るもの。例: 広めの allow パターン (`<tool> *` で powerful な subcommand を含むか不明)、power の評価が分かれるもの、user 個人のワークフロー判断が必要なもの (PR の auto-merge を許すかなど)
- **不明**: 候補の意味自体が把握できていないもの。書き込みに進まず、別途調査して埋めてから再提案

確実 OK の表を最初に出し、user の確認後に書き込みに進む。borderline は別 turn で扱う。

#### 4a. 各 disposition は固定チェックリストに具体事実で答える

「rationale を書け」を自由記述に任せると `readonly / 実在 / 狭い` のような **buzzword 羅列** で済まされ、評価が抜ける。これを防ぐため、disposition ごとに **固定のチェック項目** を全件「具体的な事実」で埋めさせる。1 項目でも事実で埋められない (= 「危険ではない」「たぶん」「読み取り専用」のような根拠なし語で逃げる) なら、その disposition は不適切とみなす。

**「具体的な事実」とは**: パターン中の引数構造の列挙、実際に叩いた確認コマンド、公式 docs URL、`*` が展開した実例 など、検証可能なもの。意見・印象・自己評価は不可。

##### allow の R1-R5 チェックリスト

allow を提案するには **R1-R5 を全件埋める**。1 つでも埋まらない / 不可なら allow にしない (狭い literal 化 / wrapper 化 / ignore 降格)。

| #   | 項目                           | 答え方 (具体事実)                                                                                                                                                                                                       | 不適例                                                         |
| --- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| R1  | 任意コード実行を含まないか     | 引数中に `-e`/`-c`/`--eval`/`--exec` 等のスクリプト解釈 flag が **無いこと** をコマンド spec から示す                                                                                                                   | 「コード実行系ではない」(根拠なし)                             |
| R2  | 任意 HTTP 書き込みを含まないか | `-X POST/PUT/PATCH/DELETE` / `--method` / 書き込み系 subcommand が **無いこと** を示す。`curl` / `gh api` / `http` 等の HTTP client が絡む場合は必須                                                                    | 「読み取りだけ」(根拠なし)                                     |
| R3  | 広域 destructive を含まないか  | ファイル削除 / 上書き / `git push --force` / 再帰削除等が **無いこと** を 1 行で示す                                                                                                                                    | 「危険ではない」(根拠なし)                                     |
| R4  | subcommand が CLI に実在するか | 確認手段を明示: 実行した確認コマンドの literal (`gh pr view --help` 等) or 公式 docs URL                                                                                                                                | 「使ったことがある」「たぶんある」                             |
| R5  | パターン中の `*` の到達範囲    | `<cmd> --help` の usage 行 (`gh pr view {<number> \| <url> \| <branch>} [flags]` 等) を引用 + `*` が展開しうる **具体例を 2-3 個列挙** + 「subcommand 位置に `*` が来ない」根拠 (positional 引数名が固定種別であること) | 「狭い」「想定内」「PR 番号のみ」(usage 引用なし / 具体例なし) |

R1-R3 のどれかが「含まれる」 → 狭い literal か wrapper 化か ignore に倒す (Q1 で `R番号 不可` を明示)。R4 が「不在」 → 暫定 ignore (Q1 で `runok 機能不足: unknown subcommand auto-deny` を併記必須)。R5 が「想定外まで到達」 → `*` を狭めるか literal 化。

##### ignore の Q1-Q2 チェックリスト

ignore を提案するには Q1 / Q2 両方を具体的に書く。

- **Q1: なぜ allow に倒せないか** — 以下のいずれかで具体根拠を書く:
    - `R1-R5 のどれかが不可`: **どの R 番号が、なぜ不可か** を 1 行 (例: `R1 不可: cargo run は任意 Rust コードを build & 実行できる`)。**R4 不可 (subcommand 不在) のときは下の `runok 機能不足: unknown subcommand auto-deny` を併記必須**
    - `runok 機能不足`: **必要機能名を必ず挙げる** (例: `URL host helper` / `unknown subcommand auto-deny` / `git-tracked path helper`)。yml or `IGNORE_COMMANDS` 側に `# awaiting runok feature: <feature name>` を付ける
    - `positive intent`: user が毎回判断したい意図を 1 行で書く (例: `gh pr merge は merge タイミングを毎回確認したい`)
- **Q2: なぜ deny に倒せないか** — user が **稀にでも意図的に実行する余地がある** 根拠を 1 行 (例: `dev build を走らせる正当用途あり` / `lint 走らせる正当用途あり`)

却下例: 「allow も deny も難しいから ignore」「念のため ignore」「広すぎるから ignore」 — これらは Q1 / Q2 のどちらにも具体事実が無い、適当な書き方の典型。

##### deny の D1-D2 チェックリスト

- **D1: なぜ allow に倒せないか** — R1-R5 のどれが不可か
- **D2: なぜ ignore に倒せないか** — 「user が稀にでも意図的に実行する余地が **無い** 」根拠 (常に間違っている / 害が即時発生 / 別 CLI に同等手段がある etc.)

D2 が書けないなら ignore に降格 (user 都度判断の余地を残す)。

#### 4b. 提案表フォーマット

サマリ表 + 各候補のチェックリスト展開ブロックの 2 段で出す。**rationale を表のセルに詰め込まない** (詰めると物理的に書ききれず buzzword 化する)。

サマリ表 (採否を番号で受けるための一覧):

| #   | disposition | 提案内容           | 書き込み先 | 元コマンド (頻度)                          |
| --- | ----------- | ------------------ | ---------- | ------------------------------------------ |
| 1   | allow       | `gh pr view *`     | git.yml    | `gh pr view 123` (5), `gh pr view 456` (2) |
| 2   | wrapper     | `bash -c <cmd>`    | preset     | `bash -c '...'` (3)                        |
| 3   | ignore      | `^cargo run( \|$)` | IGNORE     | `cargo run --bin foo` (1)                  |

各 # ごとに 4a のチェックリスト回答を以下の形で展開する。**見出しは `**#N** (4a 評価)` のみとする** — disposition / pattern / 書き込み先はサマリ表のみ source of truth とし、展開ブロックには再掲しない (drift 防止)。

```
**#1** (4a R1-R5 評価)
- R1 任意コード実行 不適合: `gh pr view` の引数は <pr-number-or-url> と表示系 flag (`--json`, `--web`, `--comments` 等) のみ。スクリプト解釈 flag なし (`gh pr view --help` 確認済)
- R2 任意 HTTP 書き込み 不適合: `gh pr view` は GET 系のみ (https://cli.github.com/manual/gh_pr_view)
- R3 広域 destructive 不適合: 表示専用、ファイル操作 / git ref 変更なし
- R4 subcommand 実在 適合: `gh pr view --help` 確認済
- R5 `*` 到達範囲 適合: `gh pr view --help` の usage 行 `gh pr view [<number> | <url> | <branch>] [flags]` を引用。`*` は PR 番号 (例: `123`)、URL (例: `https://github.com/x/y/pull/1`)、flag (`--json fields`, `--web`) に展開。subcommand 位置は `view` で固定済、`*` が subcommand 位置に来ることは文法上不可能

**#2** (wrapper 適用根拠)
- preset README の universal wrapper policy に合致 (shell wrapper)
- inner は再評価対象になり、wrapper 追加で権限は広がらない

**#3** (4a Q1-Q2 評価)
- Q1 allow 不可: R1 不可 — `cargo run` は `Cargo.toml` の任意 Rust コードを build & 実行できる (= 任意コード実行系)。引数の literal 化も `--bin <name>` の `<name>` で任意 binary を起動できるため意味なし
- Q2 deny 不可: 開発中に dev build を走らせる正当用途があるため毎回判断を残す
- awaiting runok feature: 該当無し (positive intent + R1 不可)
```

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

**wrapper エントリ**: 3d の判断で **preset / dotfiles / repo-local** のいずれかに追加。

- **preset (runok-presets)** に追加するのは README policy を満たす **universal wrapper** のみ。preset PR は別リポジトリ向けなので `/delegate-claude` でデリゲートが定石
- **dotfiles** (`config/runok/runok.yml` または `config/runok/{languages,tools}/*.yml`) の `definitions.wrappers` に追加するのは **stack-specific な wrapper** (例: `uvx [--from *] <cmd>` → `languages/python.yml`、`docker exec <c> sh -c <cmd>` → `tools/docker.yml`)
- **repo-local** (`<repo>/runok.local.yml`) は repo 固有の wrapper のみ。一般的な wrapper はここに置かない

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

- 起動引数なしのときに「いつから?」「どこに書く?」とユーザーに細かく聞かない。自分で判断する。一方 user が scope を明示指定したら必ず audit フラグで反映する
- deploy (`dot deploy -t runok` 等) は実行しない。runok 設定は symlink で即時反映される
- push は行わない (commit skill の責務に従う)
- 「残りは次回」で途中終了しない。出力ゼロに到達するまでループを抜けない
- default が ask で済むものを deny にしない (deny の閾値は高い)
- **allow が安全に書けない候補を ignore に流さない**。ignore は「user が意図的に毎回 ask したい」 positive intent のみ。書けない理由が runok の表現力不足なら、必要な機能を言語化して別タスク化 + 暫定 ignore (コメント付き)
- user が明示承認していない allow を「ついでに」追加しない
- **チェックリスト (4a の R1-R5 / Q1-Q2 / D1-D2) を「具体的な事実」で全件埋めないまま allow / deny を提案しない**。「危険ではない」「読み取り専用」「狭い」のような根拠なし語は事実ではない。埋められない candidate は ignore に降格して表に残す (= 表から除外しない)。除外すると user は当該コマンドが ask 履歴に残り続けていることに気付けない
- wrapper 化できるコマンドを ignore に流さない (内側コマンドは rule 評価に乗せる)
- コマンド本来の能力を評価せず広い allow を書かない (最小権限の原則)
- risk 評価が必要な候補を main 単独で一括処理しない (3a の sub-agent 分割を skip しない)
- sub-agent が ignore 判定した候補を main の独断で allow に格上げしない (緩める方向の編集禁止)
- CEL `when` に絶対パスを直書きしない (`env.HOME` を使う)
- preset / 既存ルールを読まずに「新規追加」と称して重複を提案しない
- **runok 機能の有無を schema 確認せずに user に断言しない** (`definitions.aliases`, `flag_groups`, `paths` 等は schema にある)
- **実在しない subcommand を deny 設計対象として扱わない**。CLI 側で unknown verb として失敗するだけで、deny rule の意味が無い。runok の auto-deny 機能領域
- **repo 固有の literal allow を dotfiles の global yml に書かない**。`<repo>/runok.local.yml` を使う
- **runok-presets README policy を確認せず preset PR を提案しない**。preset は stack-agnostic universal なものだけ (Unix utilities / git / gh / `bash -c` 等の universal wrapper)。stack-specific (docker / kubectl / language runtimes / package managers / uvx / nlx 等) は preset 対象外 → dotfiles 側
