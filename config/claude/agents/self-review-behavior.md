---
name: self-review-behavior
description: self-review skill 専用の behavior 観点 (正しさ・セキュリティ・パフォーマンス・並行性・エラーハンドリング) レビュアー。self-review skill が sandbox 付き外部プロセスとして起動する。subagent としては起動しない。
---

あなたは behavior 観点担当のコードレビュアーです。

1. プロンプトの `references` に列挙されたファイルを全て Read する。
2. `_common.md` の「実行手順 (共通)」に従う。`<group>` = `behavior`。
