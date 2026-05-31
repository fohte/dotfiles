# Structure Review Reference

最初に `references/_common.md` を読み、動作原則・禁止事項・出力形式ボイラープレートを適用する。本ファイルは structure グループ固有の差分のみを記述する。

## 担当観点

各観点について「この diff でこの軸は壊れうるか」を必ず一度問い、結論を出力に残す。

6. **互換性 (Compatibility)**: 後方互換・破壊的変更・API / スキーマ進化・既存呼び出し側への影響。
7. **保守性 (Maintainability)**: 不要な複雑性・重複・抽象化レベル。可読性そのものは linter / formatter の責務なので扱わない。
8. **テスト容易性 (Testability)**: 副作用の分離・mock 可能性・テストの isolation。テスト自体の不足は具体的な漏れシナリオがある場合のみ指摘。
9. **リファクタリング機会**: 動作を変えずに構造を改善できる箇所。具体的には下記:
    - **重複 / near-duplicate**: 同一ロジックのコピペ、parameterize できるテストケース。可能なら `similarity-rs` / `similarity-ts` / `similarity-py` (mizchi/similarity) を該当パスに走らせて裏取りする
    - **God function / 長すぎる関数**: 1 関数で複数責務を抱えている (例: fetch + validate + calculate + update をまとめて 1 関数)
    - **不要な抽象化**: YAGNI 違反、使われていない拡張ポイント、抽象化レベルがバラついている呼び出し
    - **dead code / 未使用パラメータ**: 触ったコード経路で到達不能な分岐、未使用の引数や戻り値
    - **misleading naming**: 振る舞いと一致していない関数名・変数名 (`get_X` が副作用を持つ、`is_X` が bool を返さない等)

## 固有原則・重要度補足

- 互換性指摘は既存 caller の grep で実際の breaking 範囲を確認してから出す。
- リファクタリング機会は **動作非依存** のため原則 🟡。動作バグを伴う場合は該当する behavior 観点で 🔴 を別途出す。

## 追加禁止事項

- 可読性そのもの (formatter 責務)

## 出力形式

```
## 観点別評価 (structure)

6. 互換性: <マーカー> <一行>
8. 保守性: <マーカー> <一行>
9. テスト容易性: <マーカー> <一行>
13. リファクタリング機会: <マーカー> <一行>

## 指摘詳細 (structure)

(_common.md のテンプレに従う。ゼロ件なら "指摘なし" の 1 行)
```
