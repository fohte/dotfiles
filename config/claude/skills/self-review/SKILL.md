---
name: self-review
description: 差分に対する self-review を 3 つの専門観点グループ (behavior / structure / convention) に分けた subagent の並列実行で行う。1 agent に多観点を詰め込むことで生じる見落としを減らす。Use this skill when reviewing a staged diff before committing, a branch diff before pushing, or any multi-dimension review of code changes.
---

# Self Review

差分レビューを 3 つの観点グループに分けた subagent で並列実行し、結果を統合する。変更内容に応じて条件付き reviewer を追加起動する。

## いつ使うか

- コミット前 (`git diff --cached`) のレビュー
- push 前 (`git diff @{u}..HEAD` または `git diff origin/<base>..HEAD`) のレビュー
- PR 作成・更新時のレビュー

## Reviewer 構成

base 3 reviewer は常に起動。conditional reviewer は変更内容が trigger にマッチした場合だけ追加起動する。

### Base reviewers (常時起動)

13 観点を MECE に 3 グループへ分割し、各グループ専用の reference を subagent に読ませる。

| Group        | 観点                                                                           | Reference                  |
| ------------ | ------------------------------------------------------------------------------ | -------------------------- |
| `behavior`   | 1 正しさ / 2 セキュリティ / 3 パフォーマンス / 4 並行性 / 5 エラーハンドリング | `references/behavior.md`   |
| `structure`  | 6 互換性 / 8 保守性 / 9 テスト容易性 / 13 リファクタリング機会                 | `references/structure.md`  |
| `convention` | 7 可観測性 / 10 ドキュメント整合性 / 11 コメントの質 / 12 プロジェクト規約遵守 | `references/convention.md` |

各 group reference は冒頭で `references/_common.md` (動作原則・禁止事項・出力形式ボイラープレート) を読み込み、固有の差分のみを記述する。

### Conditional reviewers (該当時のみ起動)

| Name               | 出力セクション     | ID prefix | Focus skill                  | 詳細                                        |
| ------------------ | ------------------ | --------- | ---------------------------- | ------------------------------------------- |
| `gha-security`     | `GHA Security`     | `GHA`     | `gha-security-review`        | 下記 [#gha-security](#gha-security)         |
| `test-philosophy`  | `Test Philosophy`  | `TEST`    | `test-philosophy`            | 下記 [#test-philosophy](#test-philosophy)   |
| `db-schema`        | `DB Schema`        | `DB`      | `postgresql-table-design`    | 下記 [#db-schema](#db-schema)               |
| `japanese-writing` | `Japanese Writing` | `JA`      | `japanese-tech-writing`      | 下記 [#japanese-writing](#japanese-writing) |
| `readme`           | `Documentation`    | `DOC`     | `crafting-effective-readmes` | 下記 [#readme](#readme)                     |

各 conditional reviewer のブロックは「Trigger (検知コマンド + 対象)」「Prompt template」の 2 セクション固定。新しい reviewer を追加するときも同じフォーマットで 1 ブロック増やす。

## 実行手順

1. **対象差分の確定**: 呼び出し元 skill (`commit` / `create-pr` など) が指定した範囲から `<range>` (`--cached` / `@{u}..HEAD` / `origin/<base>..HEAD` など、`git diff` に渡す引数) を確定する。`git diff --stat <range>` などで `<range>` が解決できることを確認してから先に進む。解決できない場合はここで中断してユーザーに報告し、subagent は 1 件も起動しない (全件が同一原因で個別に失敗するのを防ぐ)。diff 本体はここでは取得しない。各 subagent が自分の Bash tool で `git diff <range>` を実行して取得する。ファイルに書き出さないことで、`.git` 配下への誤生成や一時ファイルの雑な命名・削除漏れを避ける。`<range>` は subagent 起動から結果集約完了までの間、値を変えない (この間は追加の `git add` / `reset` / `commit` を行わない)。各 subagent が個別に diff を取得する設計上、ここが動くと group 間でレビュー対象が食い違う。
2. **規約パスの特定**: `CLAUDE.md` (root + 対象サブディレクトリ) と `.gemini/styleguide.md` (存在すれば) のパスをリストアップする。**ここでは読み込まない**。各 subagent が自分で読む。
3. **Conditional reviewer の検知**: 下記「Conditional reviewers の定義」セクションの各 reviewer の Trigger コマンドを順に実行し、マッチしたものを step 4 の起動対象に加える。最大で base 3 + conditional 5 = 8 件。
4. **subagent を並列 background 起動**: base 3 + step 3 でマッチした conditional を、**単一のアシスタントメッセージ内に Agent ツール呼び出しを並べて** **全件 `run_in_background: true`** で起動する。subagent_type は指定しない (= general-purpose)。

    禁止:
    - 1 件起動して結果を待ってから次を起動する逐次パターン
    - `run_in_background` を省略 / `false` で foreground 起動 (最初の結果が返るまで他の起動メッセージを送れない = 直列と同じ)
    - 複数ラウンドに分けて起動 (1 ラウンドで全件揃える)

    起動形 (3 〜 8 ブロック並列):

    ```
    Agent({ description: "behavior review",   run_in_background: true, prompt: "<base テンプレに behavior を埋めたもの>" })
    Agent({ description: "structure review",  run_in_background: true, prompt: "<base テンプレに structure を埋めたもの>" })
    Agent({ description: "convention review", run_in_background: true, prompt: "<base テンプレに convention を埋めたもの>" })
    // step 3 でマッチした conditional reviewer ごとに追加
    Agent({ description: "<name> review",     run_in_background: true, prompt: "<該当 reviewer の Prompt template>" })
    ```

    base reviewer 用プロンプトテンプレ:

    ```
    あなたは <group> 観点担当のコードレビュアーです。

    1. 以下を Read する:
       - <skill のフルパス>/references/_common.md (動作原則・禁止事項・出力形式ボイラープレート)
       - <skill のフルパス>/references/<group>.md (担当観点・固有原則)
       - <規約ファイルのパスリスト>
    2. 以下のコマンドを自分の Bash tool で実行し、レビュー対象の diff を取得する:
       git diff <range>
    3. reference の「出力形式」セクションに厳密に従って結果を返す。
       指摘 1 件ごとに **指摘 ID** (`<観点番号>:<file>:<LINE>`) を必ず付ける。
    ```

    `<group>` には `behavior` / `structure` / `convention` のいずれかが入る。conditional reviewer のプロンプトは下記の各ブロックからそのまま使う (`<range>` と `<対象ファイルパスのリスト>` のプレースホルダを差し替える)。

5. **完了通知を待つ**: 起動した全件 (3 〜 8) の `<task-notification>` が届くまで集約に進まない。polling・sleep・出力ファイルの先読みは禁止。通知のみが完了の根拠。**1 件でも未完了なら他の作業はせず通知を待つ**。
6. **結果集約**: 全通知到着後、各 Agent の最終出力を踏まえて以下のルールで統合する:
    - 観点別評価: behavior + structure + convention の 13 観点を通し番号順に並べる。起動した conditional reviewer ごとに、Reviewer 構成表の「出力セクション」名で独立セクションを末尾に追加 (13 観点には混ぜない)
    - 指摘詳細: 重要度順 (Critical → Warning) に並べる。`GHA-NNN` findings は HIGH=Critical / MEDIUM=Warning として、その他 conditional の `<prefix>:` findings は subagent が付けた重要度のまま混ぜて並べる
    - 重複指摘のマージは下記「Dedup ルール」に従う
    - **subagent 失敗時 fallback**: いずれかの subagent が空応答・エラー・タイムアウトした場合、該当 group / セクションを `⚠️ 未評価 (subagent 失敗)` とマークし、それだけ単独で再起動する (これも `run_in_background: true`)。再起動も失敗するなら最終出力でその旨を明示する
7. **最終出力**: 下記「出力形式」セクションに従い、3 セクション構造で出す。

## Conditional reviewers の定義

各 reviewer は Trigger と Prompt template を持つ。Trigger は step 3 の検知に使い、Prompt template は step 4 の Agent 起動でそのまま埋め込む。

### gha-security

**Trigger**:

```bash
git diff --name-only <range> | grep -E '^(\.github/workflows/.*\.ya?ml|\.github/actions/.+/action\.ya?ml|action\.ya?ml)$'
```

対象: `.github/workflows/` 配下の workflow / `.github/actions/<name>/action.yml` 形式の reusable composite action / リポジトリルート直下の `action.yml` (action リポジトリ自体)。それ以外の場所に置かれた composite action は意図的に対象外。

**Prompt template**:

```
あなたは GitHub Actions workflow のセキュリティレビュー担当です。

1. `~/.claude/skills/gha-security-review/SKILL.md` を Read し、その手順に厳密に従う。
   必要に応じて同 skill 配下の `references/*.md` を選択的に Read する。
2. レビュー対象は以下の workflow / action 関連ファイルの diff。自分の Bash tool で実行して取得する:
   git diff <range> -- <対象ファイルパスのリスト>
   diff では文脈が不足する場合に限り、リポジトリ内の対象 workflow 本体を Read してよい。
3. skill の出力形式 (GHA-NNN の findings 形式) で HIGH / MEDIUM confidence のみ返す。
   各 finding に **指摘 ID** として `GHA:<file>:<LINE>` を付ける (self-review の dedup と統合するため)。
```

### test-philosophy

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)(tests?|__tests__|spec)/|(\.|_)(test|spec)\.[a-zA-Z]+$|_test\.(go|py|rb)$|_spec\.rb$'
```

対象: `test/`・`tests/`・`__tests__/`・`spec/` 配下のファイル / `*.test.*`・`*.spec.*`・`*_test.go`・`*_test.py`・`*_test.rb`・`*_spec.rb` などのテスト命名規約に該当するファイル。

**Prompt template**:

```
あなたは test-philosophy 観点担当のテストレビュアーです。

1. `~/.claude/skills/test-philosophy/SKILL.md` を Read し、その規範に厳密に従う。
   プロジェクト固有の test 規約 (root + 対象サブディレクトリの `CLAUDE.md` 等) もあれば Read する。
2. レビュー対象は以下のテストファイル変更のみ。自分の Bash tool で diff を実行して取得する:
   git diff <range> -- <対象ファイルパスのリスト>
   テストの種類分類 (exploratory / regression / specification) の整合、テスト名・構造・前提共有・モックの過剰使用・並列性などを評価する。プロダクションコード本体の指摘は他 group に任せ、ここではテストコードの設計品質に絞る。
3. 指摘 1 件ごとに **指摘 ID** として `TEST:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
```

### db-schema

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)(db|database)/(migrate|migrations|schema)/|(^|/)(migrations?|schema)/.*\.(sql|rb|py|ts|js)$|(^|/)schema\.(rb|sql|prisma)$|(^|/)structure\.sql$|\.(sql|prisma)$'
```

対象: `db/migrate/`・`db/migrations/`・`migrations/`・`migrate/` 配下のマイグレーション / `schema.rb`・`schema.sql`・`structure.sql`・`schema.prisma` / リポジトリ内の `*.sql`・`*.prisma` ファイル全般。マッチしても DDL 以外の SQL (seed・data fixture など) しか含まない場合は起動を見送ってよい。プロジェクトが PostgreSQL を使っていない場合 (例: MySQL only) も見送ってよい。

**Prompt template**:

```
あなたは postgresql-table-design 観点担当の DB スキーマレビュアーです。

1. `~/.claude/skills/postgresql-table-design/SKILL.md` を Read し、その規範に厳密に従う。
   プロジェクト固有の DB 規約 (root + 該当サブディレクトリの `CLAUDE.md`、`db/` 配下の README 等) もあれば Read する。
2. レビュー対象は以下のスキーマ定義の追加・変更のみ。自分の Bash tool で diff を実行して取得する:
   git diff <range> -- <対象ファイルパスのリスト>
   評価軸: 型選択 (timestamptz / numeric / text 等の使い分け、禁止型の混入)、NOT NULL・DEFAULT・CHECK・UNIQUE・FK の妥当性、index 設計 (FK index 漏れ、複合 index の並び、partial / expression index の活用)、命名 (snake_case)、JSONB の使い分け、partitioning・identity 採用の妥当性、安全なスキーマ進化 (volatile default による rewrite 等)。アプリケーションロジック側の指摘は他 group に任せ、ここではスキーマ設計に絞る。
3. プロジェクトが PostgreSQL でないと diff から判断できる場合 (例: MySQL 固有構文・MongoDB スキーマなど) は冒頭で「対象外: <理由>」と返して終了する。
4. 指摘 1 件ごとに **指摘 ID** として `DB:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
```

### japanese-writing

**Trigger**:

```bash
# 1. ドキュメント候補ファイルを抽出
candidates=$(git diff --name-only <range> | grep -iE '\.(md|mdx|markdown|rst|adoc|txt)$')
# 2. diff の追加行に日本語 (ひらがな / カタカナ / 漢字) が含まれるファイルだけ残す
for f in $candidates; do
  git diff <range> -- "$f" | grep -E '^\+' | grep -qE '[ぁ-んァ-ヶ一-龯]' && echo "$f"
done
```

対象: `*.md`・`*.mdx`・`*.markdown`・`*.rst`・`*.adoc`・`*.txt` のうち、diff の追加行に日本語文字を含むもの。コード内コメントや英語のみのドキュメントは対象外。

**Prompt template**:

```
あなたは japanese-tech-writing 観点担当の日本語ドキュメントレビュアーです。

1. `~/.claude/skills/japanese-tech-writing/SKILL.md` を Read し、その規範に厳密に従う。
2. レビュー対象は以下の日本語ドキュメントの追加・変更行のみ。自分の Bash tool で diff を実行して取得する:
   git diff <range> -- <対象ファイルパスのリスト>
   評価軸: 整形 (一文一行、引用ブロック、脚注、コラム記法)、全角記号の混入 (丸括弧・感嘆符・疑問符・コロンは半角、半角英数字との間にスペース)、パラグラフ構成、論証の厳密さ、LLM 的な空句・冗長表現、視点と語りの一貫性。技術的事実の正否は他 group に任せ、ここでは文章規範に絞る。
3. diff 内の差分が日本語を含まない箇所 (英語のみ・コードブロック・URL など) はスキップする。
4. 指摘 1 件ごとに **指摘 ID** として `JA:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
```

### readme

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)README\.(md|mdx|markdown|rst)$|^docs/.+\.(md|mdx|markdown|rst)$'
```

対象: 任意ディレクトリの `README.*` / リポジトリルートの `docs/` 配下のドキュメント。テンプレートや雛形ファイル (例: skill の `templates/*.md`) は対象外。コードとドキュメントの整合性は base reviewer の `convention` group (観点 10) が見るので、ここでは README / docs の設計品質に絞る。

**Prompt template**:

```
あなたは crafting-effective-readmes 観点担当のドキュメントレビュアーです。

1. `~/.claude/skills/crafting-effective-readmes/SKILL.md` と必要に応じて `references/*.md` を Read し、その規範に厳密に従う。特に「Scope and source boundaries」「Project Types」「Essential Sections」を重視する。
2. レビュー対象は以下の README / docs の追加・変更。自分の Bash tool で diff を実行して取得する:
   git diff <range> -- <対象ファイルパスのリスト>
   評価軸: スコープ境界 (このリポジトリ外の実装詳細・private 由来情報の混入、コードに裏付けのない限定的記述)、project type に対するセクション欠落・過剰、利用者が次に取る行動を支える例の有無、外部依存の抽象度 (内部パス・hostname・secret store 名などが漏れていないか)。文章規範 (全角記号・段落構成) は `japanese-writing` reviewer に任せ、コードとの整合性は base reviewer の convention group に任せる。
3. 指摘 1 件ごとに **指摘 ID** として `DOC:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
```

## Dedup ルール

グループを MECE に分けたため subagent 間の衝突は起きにくいが、cross-cutting なケースはあり得る。代表的な重なり:

- `test-philosophy` ↔ `structure` (9 テスト容易性)
- `db-schema` ↔ `behavior` (1 正しさ / 2 セキュリティ) / `structure` (6 互換性)
- `japanese-writing` ↔ `convention` (10 ドキュメント整合性 / 11 コメントの質)
- `readme` ↔ `convention` (10 ドキュメント整合性) / `japanese-writing` (文章規範)

各 subagent が出した **指摘 ID** (`<prefix>:<file>:<LINE>`) と症状要約を key に以下を適用する:

1. **同 file:line・同 issue**: 1 件にマージし、両方のグループ名を記録
2. **同 file:line・異なる issue**: 別件として残し、`co-located` タグを付ける
3. **同 issue・異なる location**: 別件として残し、互いを cross-reference
4. **severity 食い違い**: 高い方を採用

## 出力形式

出力は次の 3 セクションを **この順序で必ず** 出す。指摘ゼロでも 3 セクション全てのヘッダを出す。

### 1. 観点別評価 (必須)

13 観点を **全件** リスト化し、各項目に以下のいずれかを付ける:

- `✅`: この観点で壊れる可能性を検討した上で問題なし
- `⚠️ N/A`: この diff にこの観点が構造上関係しない (理由 1 行)。同一理由を 3 観点以上に流用する場合は冒頭で一括宣言してよい
- `⚠️ 未評価`: subagent 失敗による (上記 fallback 参照)
- `🔴` / `🟡`: 指摘あり。複数指摘がある観点は最重要マーカー + `(+ 🟡 N 件)` の総件数併記

13 観点の後に、起動した conditional reviewer の出力セクションを Reviewer 構成表の順序で追記する。未起動 (trigger 非マッチ) のセクションは行ごと省略する。

```
## 観点別評価

1. 正しさ: <マーカー> <一行>
2. セキュリティ: <マーカー> <一行>
3. パフォーマンス: <マーカー> <一行>
4. 並行性: <マーカー> <一行>
5. エラーハンドリング: <マーカー> <一行>
6. 互換性: <マーカー> <一行>
7. 可観測性: <マーカー> <一行>
8. 保守性: <マーカー> <一行>
9. テスト容易性: <マーカー> <一行>
10. ドキュメント整合性: <マーカー> <一行>
11. コメントの質: <マーカー> <一行>
12. プロジェクト規約遵守: <マーカー> <一行>
13. リファクタリング機会: <マーカー> <一行>

GHA Security: <マーカー> <一行>      (gha-security 未起動時は省略)
Test Philosophy: <マーカー> <一行>   (test-philosophy 未起動時は省略)
DB Schema: <マーカー> <一行>         (db-schema 未起動時は省略)
Japanese Writing: <マーカー> <一行>  (japanese-writing 未起動時は省略)
Documentation: <マーカー> <一行>     (readme 未起動時は省略)
```

### 2. 指摘詳細

`🔴` / `🟡` が付いた箇所を `references/_common.md` の指摘テンプレに従って出す。ゼロ件でも `## 指摘詳細` ヘッダ + `指摘なし` の 1 行は出す。同じ観点が複数箇所に出現する場合は最も代表的な 1-2 件に絞り「他 N 箇所も同様」と注記する。観点別評価の件数併記には省略分も含めた総数を書く。

### 3. サマリ (必須)

```
## Summary

- Critical: <件数>
- Warning: <件数>
- Files reviewed: <件数>
```
