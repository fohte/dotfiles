---
name: self-review
description: 差分に対する self-review を 3 つの専門観点グループ (behavior / structure / convention) に分けた subagent の並列実行で行う。1 agent に多観点を詰め込むことで生じる見落としを減らす。Use this skill when reviewing a staged diff before committing, a branch diff before pushing, or any multi-dimension review of code changes.
---

# Self Review

差分レビューを 3 つの観点グループに分けた subagent で並列実行し、結果を統合する。

## いつ使うか

- コミット前 (`git diff --cached`) のレビュー
- push 前 (`git diff @{u}..HEAD` または `git diff origin/<base>..HEAD`) のレビュー
- PR 作成・更新時のレビュー

## 観点グループ

13 観点を MECE に 3 グループへ分割する。各グループ専用の reference を subagent に読ませる。

| Group        | 観点                                                                           | Reference                  |
| ------------ | ------------------------------------------------------------------------------ | -------------------------- |
| `behavior`   | 1 正しさ / 2 セキュリティ / 3 パフォーマンス / 4 並行性 / 5 エラーハンドリング | `references/behavior.md`   |
| `structure`  | 6 互換性 / 8 保守性 / 9 テスト容易性 / 13 リファクタリング機会                 | `references/structure.md`  |
| `convention` | 7 可観測性 / 10 ドキュメント整合性 / 11 コメントの質 / 12 プロジェクト規約遵守 | `references/convention.md` |

各 group reference は冒頭で `references/_common.md` (動作原則・禁止事項・出力形式ボイラープレート) を読み込み、固有の差分のみを記述する。

## 実行手順

1. **対象差分の確定**: 呼び出し元 skill (`commit` / `create-pr` など) が指定した範囲 (`git diff --cached` / `git diff @{u}..HEAD` / PR 番号など) を取得する。
2. **diff をファイルに書き出す**: subagent への埋め込みではなくパス渡しにする (3 並列起動でのトークン消費を 1/3 に抑える)。

    ```bash
    git diff --cached > /tmp/self-review-diff-$$.patch
    # または push 前
    git diff @{u}..HEAD > /tmp/self-review-diff-$$.patch
    ```

3. **規約パスの特定**: `CLAUDE.md` (root + 対象サブディレクトリ) と `.gemini/styleguide.md` (存在すれば) のパスをリストアップする。**ここでは読み込まない** — 各 subagent が自分で読む。
4. **追加 subagent 起動対象の検知**: 以下をそれぞれ実行し、マッチした種別ごとに次ステップで専用 subagent を追加起動する。両方マッチすれば最大 5 件起動。
    - **GitHub Actions workflow 変更** (`gha-security-review` を追加):

        ```bash
        git diff --name-only <range> | grep -E '^(\.github/workflows/.*\.ya?ml|\.github/actions/.+/action\.ya?ml|action\.ya?ml)$'
        ```

        対象: `.github/workflows/` 配下の workflow / `.github/actions/<name>/action.yml` 形式の reusable composite action / リポジトリルート直下の `action.yml` (action リポジトリ自体)。それ以外の場所に置かれた composite action は意図的に対象外。

    - **テストファイル変更** (`test-philosophy-review` を追加): `test-philosophy` skill が定義する「テストの設計指針」観点で評価する。テストコードの追加・変更時のみ起動する。

        ```bash
        git diff --name-only <range> | grep -iE '(^|/)(tests?|__tests__|spec)/|(\.|_)(test|spec)\.[a-zA-Z]+$|_test\.(go|py|rb)$|_spec\.rb$'
        ```

        対象: `test/`・`tests/`・`__tests__/`・`spec/` 配下のファイル / `*.test.*`・`*.spec.*`・`*_test.go`・`*_test.py`・`*_test.rb`・`*_spec.rb` などのテスト命名規約に該当するファイル。

    - **DB スキーマ変更** (`postgresql-table-design-review` を追加): `postgresql-table-design` skill が定義する PostgreSQL テーブル設計指針 (型選択・制約・index・命名・JSONB 使い分けなど) で評価する。スキーマ定義ファイルの追加・変更時のみ起動する。プロジェクトが PostgreSQL を使っていない場合 (例: MySQL only) は起動を見送ってよい。

        ```bash
        git diff --name-only <range> | grep -iE '(^|/)(db|database)/(migrate|migrations|schema)/|(^|/)(migrations?|schema)/.*\.(sql|rb|py|ts|js)$|(^|/)schema\.(rb|sql|prisma)$|(^|/)structure\.sql$|\.(sql|prisma)$'
        ```

        対象: `db/migrate/`・`db/migrations/`・`migrations/`・`migrate/` 配下のマイグレーション / `schema.rb`・`schema.sql`・`structure.sql`・`schema.prisma` / リポジトリ内の `*.sql`・`*.prisma` ファイル全般。マッチしても DDL 以外の SQL (seed・data fixture など) しか含まない場合は起動を見送ってよい。

5. **subagent を並列 background 起動**: Agent ツールを **単一のアシスタントメッセージ内に 3〜6 件まとめて記述** し、**全件 `run_in_background: true`** で起動する。subagent_type は指定しない (= general-purpose)。次のいずれも禁止:
    - 1 件起動して結果を待ってから次を起動する逐次パターン
    - `run_in_background` を省略 / `false` にして foreground で起動する (foreground だと最初の Agent の結果が返るまで他の Agent を起動するメッセージを送れない = 直列と同じになる)
    - 2 件まとめて起動した後に 1 件追加で起動するような分割パターン (1 ラウンドで全件揃える)

    具体的な起動形 (単一メッセージ内に 3〜6 ブロック並べる):

    ```
    Agent({
      description: "behavior review",
      run_in_background: true,
      prompt: "<下記テンプレに behavior を埋めたもの>"
    })
    Agent({
      description: "structure review",
      run_in_background: true,
      prompt: "<下記テンプレに structure を埋めたもの>"
    })
    Agent({
      description: "convention review",
      run_in_background: true,
      prompt: "<下記テンプレに convention を埋めたもの>"
    })
    // workflow 変更検知時のみ追加
    Agent({
      description: "gha-security review",
      run_in_background: true,
      prompt: "<下記 gha テンプレ>"
    })
    // テストファイル変更検知時のみ追加
    Agent({
      description: "test-philosophy review",
      run_in_background: true,
      prompt: "<下記 test-philosophy テンプレ>"
    })
    // DB スキーマ変更検知時のみ追加
    Agent({
      description: "postgresql-table-design review",
      run_in_background: true,
      prompt: "<下記 postgresql-table-design テンプレ>"
    })
    ```

    behavior / structure / convention 各 Agent に渡すプロンプトテンプレ:

    ```
    あなたは <group> 観点担当のコードレビュアーです。

    1. 以下を Read する:
       - <skill のフルパス>/references/_common.md (動作原則・禁止事項・出力形式ボイラープレート)
       - <skill のフルパス>/references/<group>.md (担当観点・固有原則)
       - <規約ファイルのパスリスト>
    2. 以下の patch をレビュー対象とする (Read で読み込む):
       <patch のフルパス>
    3. reference の「出力形式」セクションに厳密に従って結果を返す。
       指摘 1 件ごとに **指摘 ID** (`<観点番号>:<file>:<LINE>`) を必ず付ける。
    ```

    `<group>` には `behavior` / `structure` / `convention` のいずれかが入る。

    `gha-security-review` Agent に渡すプロンプトテンプレ:

    ```
    あなたは GitHub Actions workflow のセキュリティレビュー担当です。

    1. `~/.claude/skills/gha-security-review/SKILL.md` を Read し、その手順に厳密に従う。
       必要に応じて同 skill 配下の `references/*.md` を選択的に Read する。
    2. レビュー対象は以下の patch に含まれる workflow / action 関連ファイル:
       <patch のフルパス>
       patch では文脈が不足する場合に限り、リポジトリ内の対象 workflow 本体を Read してよい。
    3. skill の出力形式 (GHA-NNN の findings 形式) で HIGH / MEDIUM confidence のみ返す。
       各 finding に **指摘 ID** として `GHA:<file>:<LINE>` を付ける (self-review の dedup と統合するため)。
    ```

    `test-philosophy-review` Agent に渡すプロンプトテンプレ:

    ```
    あなたは test-philosophy 観点担当のテストレビュアーです。

    1. `~/.claude/skills/test-philosophy/SKILL.md` を Read し、その規範に厳密に従う。
       プロジェクト固有の test 規約 (root + 対象サブディレクトリの `CLAUDE.md` 等) もあれば Read する。
    2. レビュー対象は以下の patch に含まれるテストファイル変更のみ:
       <patch のフルパス>
       テストの種類分類 (exploratory / regression / specification) の整合、テスト名・構造・前提共有・モックの過剰使用・並列性などを評価する。プロダクションコード本体の指摘は他 group に任せ、ここではテストコードの設計品質に絞る。
    3. 指摘 1 件ごとに **指摘 ID** として `TEST:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
    ```

    `postgresql-table-design-review` Agent に渡すプロンプトテンプレ:

    ```
    あなたは postgresql-table-design 観点担当の DB スキーマレビュアーです。

    1. `~/.claude/skills/postgresql-table-design/SKILL.md` を Read し、その規範に厳密に従う。
       プロジェクト固有の DB 規約 (root + 該当サブディレクトリの `CLAUDE.md`、`db/` 配下の README 等) もあれば Read する。
    2. レビュー対象は以下の patch に含まれるスキーマ定義の追加・変更のみ:
       <patch のフルパス>
       評価軸: 型選択 (timestamptz / numeric / text 等の使い分け、禁止型の混入)、NOT NULL・DEFAULT・CHECK・UNIQUE・FK の妥当性、index 設計 (FK index 漏れ、複合 index の並び、partial / expression index の活用)、命名 (snake_case)、JSONB の使い分け、partitioning・identity 採用の妥当性、安全なスキーマ進化 (volatile default による rewrite 等)。アプリケーションロジック側の指摘は他 group に任せ、ここではスキーマ設計に絞る。
    3. プロジェクトが PostgreSQL でないと patch から判断できる場合 (例: MySQL 固有構文・MongoDB スキーマなど) は冒頭で「対象外: <理由>」と返して終了する。
    4. 指摘 1 件ごとに **指摘 ID** として `DB:<file>:<LINE>` を付け、重要度 (Critical / Warning) と症状要約を含めて返す。指摘ゼロなら「指摘なし」と返す。
    ```

6. **完了通知を待つ**: 起動した全件 (3〜6) の `<task-notification>` が届くまで集約に進まない。polling・sleep・出力ファイルの先読みは禁止 — 通知のみが完了の根拠。**1 件でも未完了なら他の作業はせず通知を待つ**。
7. **結果集約**: 全通知到着後、各 Agent の最終出力を踏まえて以下のルールで統合する:
    - 観点別評価: behavior + structure + convention の 13 観点を通し番号順に並べる。`gha-security-review` / `test-philosophy-review` / `postgresql-table-design-review` を起動した場合は末尾に独立セクション `GHA Security` / `Test Philosophy` / `DB Schema` として findings 件数サマリを追加する (13 観点には混ぜない)
    - 指摘詳細: 重要度順 (Critical → Warning) に並べる。`GHA-NNN` findings は HIGH=Critical / MEDIUM=Warning として、`TEST:` / `DB:` findings は subagent が付けた重要度のまま混ぜて並べる
    - 重複指摘のマージは下記「Dedup ルール」に従う。特に test-philosophy と structure (9 テスト容易性)、postgresql-table-design と behavior (1 正しさ / 2 セキュリティ) や structure (6 互換性) は cross-cutting が起きやすいので注意する
    - **subagent 失敗時 fallback**: いずれかの subagent が空応答・エラー・タイムアウトした場合、該当 group の観点を `⚠️ 未評価 (subagent 失敗)` とマークし、その group だけ単独で再起動する (これも `run_in_background: true`)。再起動も失敗するなら最終出力でその旨を明示する。`gha-security-review` / `test-philosophy-review` / `postgresql-table-design-review` が失敗した場合も対応する独立セクションに `⚠️ 未評価 (subagent 失敗)` を出力し、同条件で 1 回だけ再起動する。
8. **最終出力**: 下記「出力形式」セクションに従い、3 セクション構造で出す。

## Dedup ルール

グループを MECE に分けたため subagent 間の衝突は起きにくいが、cross-cutting なケース (例: コメント内のドキュメント整合性違反が `convention` で指摘されつつ、同じコメントが `structure` で「不要」と指摘される等) はあり得る。各 subagent が出した **指摘 ID** (`<観点番号>:<file>:<LINE>`) と症状要約を key に以下を適用する:

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

GHA Security: <マーカー> <一行> (workflow 変更がない場合は行ごと省略)
Test Philosophy: <マーカー> <一行> (テストファイル変更がない場合は行ごと省略)
DB Schema: <マーカー> <一行> (DB スキーマ変更がない場合は行ごと省略)
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
