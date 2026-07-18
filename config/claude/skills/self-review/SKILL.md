---
name: self-review
description: 差分に対する self-review を 3 つの専門観点グループ (behavior / structure / convention) に分けた subagent の並列実行で行う。1 agent に多観点を詰め込むことで生じる見落としを減らす。Use this skill when reviewing a staged diff before committing, a branch diff before pushing, or any multi-dimension review of code changes.
---

# Self Review

差分レビューを 3 つの観点グループに分けた subagent で並列実行し、結果を統合する。変更内容に応じて条件付き reviewer を追加起動する。各 reviewer の役割・手順は `~/.claude/agents/self-review-*.md` に agent 定義として持たせてあり、この SKILL.md は起動対象の決定・並列起動・結果集約のみを担当する (subagent 起動のたびにここへ大きなプロンプトを組み立てる必要をなくすため)。

## いつ使うか

- コミット前 (`git diff --cached`) のレビュー
- push 前 (`git diff @{u}..HEAD` または `git diff origin/<base>..HEAD`) のレビュー
- PR 作成・更新時のレビュー

## Reviewer 構成

base 3 reviewer は常に起動。conditional reviewer は変更内容が trigger にマッチした場合だけ追加起動する。

### Base reviewers (常時起動)

13 観点を MECE に 3 グループへ分割し、各グループ専用の agent が対応する reference を読み込む。

| Group        | 観点                                                                           | Reference                  | Agent                    |
| ------------ | ------------------------------------------------------------------------------ | -------------------------- | ------------------------ |
| `behavior`   | 1 正しさ / 2 セキュリティ / 3 パフォーマンス / 4 並行性 / 5 エラーハンドリング | `references/behavior.md`   | `self-review-behavior`   |
| `structure`  | 6 互換性 / 8 保守性 / 9 テスト容易性 / 13 リファクタリング機会                 | `references/structure.md`  | `self-review-structure`  |
| `convention` | 7 可観測性 / 10 ドキュメント整合性 / 11 コメントの質 / 12 プロジェクト規約遵守 | `references/convention.md` | `self-review-convention` |

各 agent は起動時に自分で `references/_common.md` (動作原則・禁止事項・出力形式ボイラープレート) と対応する group の reference を Read する。

### Conditional reviewers (該当時のみ起動)

| Name               | 出力セクション     | ID prefix | Agent                          | Focus skill                  | 詳細                                        |
| ------------------ | ------------------ | --------- | ------------------------------ | ---------------------------- | ------------------------------------------- |
| `gha-security`     | `GHA Security`     | `GHA`     | `self-review-gha-security`     | `gha-security-review`        | 下記 [#gha-security](#gha-security)         |
| `test-philosophy`  | `Test Philosophy`  | `TEST`    | `self-review-test-philosophy`  | `test-philosophy`            | 下記 [#test-philosophy](#test-philosophy)   |
| `db-schema`        | `DB Schema`        | `DB`      | `self-review-db-schema`        | `postgresql-table-design`    | 下記 [#db-schema](#db-schema)               |
| `japanese-writing` | `Japanese Writing` | `JA`      | `self-review-japanese-writing` | `japanese-tech-writing`      | 下記 [#japanese-writing](#japanese-writing) |
| `readme`           | `Documentation`    | `DOC`     | `self-review-readme`           | `crafting-effective-readmes` | 下記 [#readme](#readme)                     |

各 conditional reviewer のブロックは「Trigger (検知コマンド + 対象)」「Agent (定義ファイルへの参照)」の 2 要素を持つ。起動時の指示は対応する `Agent` の定義ファイル (`~/.claude/agents/self-review-<name>.md`) に持たせてあるため、ブロック本文には書かない。新しい reviewer を追加するときは Trigger + Agent 参照のブロック、この表の行、および対応する agent 定義ファイルを追加する。

## 実行手順

1. **対象差分の確定**: 呼び出し元 skill (`commit` / `create-pr` など) が指定した範囲から `<range>` (`--cached` / `@{u}..HEAD` / `origin/<base>..HEAD` など、`git diff` に渡す引数) を確定する。`git diff --stat <range>` などで `<range>` が解決できることを確認してから先に進む。解決できない場合はここで中断してユーザーに報告し、subagent は 1 件も起動しない (全件が同一原因で個別に失敗するのを防ぐ)。diff 本体はここでは取得しない。各 subagent が自分の Bash tool で `git diff <range>` を実行して取得する。ファイルに書き出さないことで、`.git` 配下への誤生成や一時ファイルの雑な命名・削除漏れを避ける。`<range>` は subagent 起動から結果集約完了までの間、値を変えない (この間は追加の `git add` / `reset` / `commit` を行わない)。各 subagent が個別に diff を取得する設計上、ここが動くと group 間でレビュー対象が食い違う。
2. **Conditional reviewer の検知**: 下記「Conditional reviewers の定義」セクションの各 reviewer の Trigger コマンドを順に実行する。マッチしたものは step 3 の起動対象に加え、Trigger の出力 (対象ファイルパスのリスト) をそのまま `targets` として保持しておく。最大で base 3 + conditional 5 = 8 件。
3. **subagent を並列 background 起動**: base 3 + step 2 でマッチした conditional を、**単一のアシスタントメッセージ内に Agent ツール呼び出しを並べて** **全件 `run_in_background: true`** で起動する。`subagent_type` に「Reviewer 構成」表の `Agent` 列の値を指定する。プロンプトは `range` (conditional は `targets` も) のみを渡す。reviewer ごとの指示は agent 定義ファイル側に埋め込み済みなので、ここでプロンプトを組み立てる必要はない。

    禁止:
    - 1 件起動して結果を待ってから次を起動する逐次パターン
    - `run_in_background` を省略 / `false` で foreground 起動 (最初の結果が返るまで他の起動メッセージを送れない = 直列と同じ)
    - 複数ラウンドに分けて起動 (1 ラウンドで全件揃える)

    起動形 (3 〜 8 ブロック並列):

    ```
    Agent({ description: "behavior review",   run_in_background: true, subagent_type: "self-review-behavior",   prompt: "range: <range>" })
    Agent({ description: "structure review",  run_in_background: true, subagent_type: "self-review-structure",  prompt: "range: <range>" })
    Agent({ description: "convention review", run_in_background: true, subagent_type: "self-review-convention", prompt: "range: <range>" })
    // step 2 でマッチした conditional reviewer ごとに追加 (targets は Trigger で得たファイルパスを改行区切りで並べる)
    Agent({ description: "<name> review",     run_in_background: true, subagent_type: "self-review-<name>",     prompt: "range: <range>\ntargets:\n<file1>\n<file2>" })
    ```

4. **完了通知を待つ**: 起動した全件 (3 〜 8) の `<task-notification>` が届くまで集約に進まない。polling・sleep・出力ファイルの先読みは禁止。通知のみが完了の根拠。**1 件でも未完了なら他の作業はせず通知を待つ**。
5. **結果集約**: 全通知到着後、各 Agent の最終出力を踏まえて以下のルールで統合する:
    - 観点別評価: behavior + structure + convention の 13 観点を通し番号順に並べる。起動した conditional reviewer ごとに、Reviewer 構成表の「出力セクション」名で独立セクションを末尾に追加 (13 観点には混ぜない)
    - 指摘詳細: 重要度順 (Critical → Warning) に並べる。`GHA-NNN` findings は HIGH=Critical / MEDIUM=Warning として、その他 conditional の `<prefix>:` findings は subagent が付けた重要度のまま混ぜて並べる
    - 重複指摘のマージは下記「Dedup ルール」に従う
    - **subagent 失敗時 fallback**: いずれかの subagent が空応答・エラー・タイムアウトした場合、該当 group / セクションを `⚠️ 未評価 (subagent 失敗)` とマークし、それだけ単独で再起動する (同じ `subagent_type` と、初回起動時と同一のプロンプト (conditional reviewer は `targets` を含めたもの) で、`run_in_background: true`)。再起動も失敗するなら最終出力でその旨を明示する
6. **最終出力**: 下記「出力形式」セクションに従い、3 セクション構造で出す。

## Conditional reviewers の定義

各 reviewer は Trigger と Agent 参照を持つ。Trigger は step 2 の起動要否判定・対象ファイル特定に使う。起動時の指示は Agent 参照先の agent 定義ファイル (`~/.claude/agents/self-review-<name>.md`) に持たせてあり、ここには書かない。

### gha-security

**Trigger**:

```bash
git diff --name-only <range> | grep -E '^(\.github/workflows/.*\.ya?ml|\.github/actions/.+/action\.ya?ml|action\.ya?ml)$'
```

対象: `.github/workflows/` 配下の workflow / `.github/actions/<name>/action.yml` 形式の reusable composite action / リポジトリルート直下の `action.yml` (action リポジトリ自体)。それ以外の場所に置かれた composite action は意図的に対象外。

**Agent**: `self-review-gha-security` (`~/.claude/agents/self-review-gha-security.md`)

### test-philosophy

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)(tests?|__tests__|spec)/|(\.|_)(test|spec)\.[a-zA-Z]+$|_test\.(go|py|rb)$|_spec\.rb$'
```

対象: `test/`・`tests/`・`__tests__/`・`spec/` 配下のファイル / `*.test.*`・`*.spec.*`・`*_test.go`・`*_test.py`・`*_test.rb`・`*_spec.rb` などのテスト命名規約に該当するファイル。

**Agent**: `self-review-test-philosophy` (`~/.claude/agents/self-review-test-philosophy.md`)

### db-schema

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)(db|database)/(migrate|migrations|schema)/|(^|/)(migrations?|schema)/.*\.(sql|rb|py|ts|js)$|(^|/)schema\.(rb|sql|prisma)$|(^|/)structure\.sql$|\.(sql|prisma)$'
```

対象: `db/migrate/`・`db/migrations/`・`migrations/`・`migrate/` 配下のマイグレーション / `schema.rb`・`schema.sql`・`structure.sql`・`schema.prisma` / リポジトリ内の `*.sql`・`*.prisma` ファイル全般。マッチしても DDL 以外の SQL (seed・data fixture など) しか含まない場合は起動を見送ってよい。プロジェクトが PostgreSQL を使っていない場合 (例: MySQL only) も見送ってよい。

**Agent**: `self-review-db-schema` (`~/.claude/agents/self-review-db-schema.md`)

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

**Agent**: `self-review-japanese-writing` (`~/.claude/agents/self-review-japanese-writing.md`)

### readme

**Trigger**:

```bash
git diff --name-only <range> | grep -iE '(^|/)README\.(md|mdx|markdown|rst)$|^docs/.+\.(md|mdx|markdown|rst)$'
```

対象: 任意ディレクトリの `README.*` / リポジトリルートの `docs/` 配下のドキュメント。テンプレートや雛形ファイル (例: skill の `templates/*.md`) は対象外。コードとドキュメントの整合性は base reviewer の `convention` group (観点 10) が見るので、ここでは README / docs の設計品質に絞る。

**Agent**: `self-review-readme` (`~/.claude/agents/self-review-readme.md`)

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
