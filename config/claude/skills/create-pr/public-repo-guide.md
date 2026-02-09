# Public repo 向け追加ガイド

## 英語ライティングガイドライン

翻訳時および英語で記述する際の一般的なルール。

### 文の始め方

- **前置きや条件から始めない**: 主語と結論を先に述べる。特に `When`, `If`, `Since`, `Because`, `Without` などで文を始めない
    - ❌ `Need to enforce proper error handling`
    - ❌ `When using this library, memory leaks may occur`
    - ❌ `When running multiple sessions in parallel, notifications did not provide enough context`
    - ❌ `Without the --all-targets option, clippy only checks library targets`
    - ✅ `Enforce proper error handling`
    - ✅ `This library may cause memory leaks under certain conditions`
    - ✅ `Notifications did not provide enough context to distinguish multiple parallel sessions`
    - ✅ `Clippy only checks library targets by default`

### 自然な英語表現

- **直訳を避け、意図を伝える**: 日本語の構造をそのまま英語にせず、英語として自然な表現に言い換える
    - ❌ `Fix existing violations and add annotations` (並列に見えるが実際は手段と目的)
    - ✅ `Fix existing violations by adding annotations` (因果関係が明確)
- **冗長な表現を避ける**: 同じ意味を繰り返さない
    - ❌ `in order to` → ✅ `to`
    - ❌ `make sure to` → ✅ `ensure` or just use imperative

### その他の注意

- **「etc.」の使用を避ける**: 文中での使用はカジュアルすぎる。「or similar tools」「and related features」などを使う
    - ❌ `Claude Code etc.`
    - ✅ `Claude Code or similar tools`

## 翻訳時の注意

public repo では翻訳が必須。翻訳時は以下に注意すること。

- **日本語の意図を正確に反映する**: 直訳ではなく、意図を汲んだ自然な英語にする
- **type との二重表現を英語でも避ける**: `fix: fix ...` のような表現にしない
- **`fix` type の description では解決策を述べる**:
    - `support` は新機能追加のニュアンスが強いので `fix` type では避ける
    - 事実の列挙 (「〜が失敗していた」) ではなく、何を変えて解決したかを述べる
    - Bad: `fix(wm): support \`wm new\` on macOS` (support は feat 向き)
    - Bad: `fix(wm): \`wm new\` failing on macOS` (事実の列挙、解決策が見えない)
    - Good: `fix(wm): use cache directory instead of state directory for macOS compatibility`
- **`feat` type の description では「〜できるようにする」の訳し方に注意**:
    - `enable` は「有効化する」のニュアンスが強いので避ける
    - `support` や `allow` の方が「〜できるようにする」に近い
    - 例: 「gzip 解凍できるようにする」→ `support gzip decompression`
