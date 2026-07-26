# Lint Suppression Review Reference

`eslint-disable` / `rubocop:disable` / `@ts-ignore` / `# noqa` などの行・ファイルレベル suppress directive、および `.eslintignore` / `.rubocop.yml` の `Exclude` などの ignore 設定を対象に、「本当にどうしようもなく抑制すべきものか、直せるのに言い訳で逃げていないか」を厳しく判定する。

最初に `references/_common.md` を読み、動作原則・禁止事項・出力形式ボイラープレートを適用する。本ファイルは lint-suppression 固有の差分のみを記述する。

## 対象パターン (例)

言語・ツールを問わず、以下のような抑制を対象とする。列挙は網羅ではなく代表例であり、同種の抑制コメント・設定であれば対象に含める。

- JS/TS: `eslint-disable`, `eslint-disable-next-line`, `eslint-disable-line`, `@ts-ignore`, `@ts-expect-error`, `stylelint-disable`
- Ruby: `rubocop:disable`, `rubocop:todo`
- Python: `# noqa`, `# type: ignore`, `# pylint: disable`, `# nosec`
- Go: `//nolint`
- Shell: `# shellcheck disable`
- 設定ファイル: `.eslintignore` / `.eslintrc*` の `ignorePatterns` / `.rubocop.yml` の `Exclude` / `.stylelintignore` / linter 設定ファイル内の rule off

## 判定手順

抑制 1 件ごとに、まず対象コードを Read し「このルールが指摘している問題は実際に直せないか」を検証してから許容/指摘を判定する。抑制コメントの文面だけで判断せず、根拠の妥当性をコードから裏取りする。

### 許容できる (指摘しない)

- 理由コメントが併記されており、その理由が具体的かつ検証可能 (既知のツールバグへの issue link、外部型定義側の制約、意図的な低レベル操作など)
- 抑制範囲がルール・行に対して最小 (該当行 1 行、該当ルール 1 つのみ)
- vendored / generated code など、書き換えがそもそもスコープ外のコード

### 指摘すべき (言い訳)

- 理由コメントが無い、または「一旦」「あとで直す」「TODO」など期限のない先送りに過ぎない
- 型定義の修正・null チェック追加・リファクタなどで実際に直せるのに抑制で逃げている (Suggestion に具体的な直し方を書く)
- 抑制範囲が過剰 (ファイル全体 disable / 複数ルールをまとめて disable なのに、実際に問題なのは特定の 1 ルールのみ)
- security 系ルール (`no-eval`, `security/detect-object-injection`, `security/*`, bandit の `B*` など) を薄弱な理由で抑制している
- 同種の抑制がその diff 内で複数箇所コピペされている (根本原因が未解消のまま個別に潰している) → 代表 1-2 件にまとめて指摘し「他 N 箇所も同様」と注記する

## 重要度

- 🔴 **Critical**: security 系ルールの抑制 / 理由コメント無しでの broad disable (ファイル全体 disable・複数ルールまとめて disable)
- 🟡 **Warning**: 理由コメントはあるが根拠が不十分 / 直せるのに逃げている / 期限のない先送りコメント

## 出力形式

```
## 観点別評価 (lint-suppression)

Lint Suppression: <マーカー> <一行>

## 指摘詳細 (lint-suppression)

(_common.md のテンプレに従う。指摘 ID は `SUP:<file>:<LINE>`。ゼロ件なら "指摘なし" の 1 行)
```
