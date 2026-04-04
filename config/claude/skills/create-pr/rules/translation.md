# 翻訳ルール

public repo では翻訳が必須。翻訳時は以下に注意すること。

- **日本語の意図を正確に反映する**: 直訳ではなく、意図を汲んだ自然な英語にする
- **type との二重表現を英語でも避ける**: `fix: fix ...` のような表現にしない
- **`fix` type の description では解決策を述べる**:
    - `support` は新機能追加のニュアンスが強いので `fix` type では避ける
    - 事実の列挙 (「〜が失敗していた」) ではなく、何を変えて解決したかを述べる
    - Bad: `fix(wm): support \`wm new\` on macOS`
    - Good: `fix(wm): use cache directory instead of state directory for macOS compatibility`
- **`feat` type の description では「〜できるようにする」の訳し方に注意**:
    - `enable` は「有効化する」のニュアンスが強いので避ける
    - `support` や `allow` の方が「〜できるようにする」に近い
    - 例: 「gzip 解凍できるようにする」-> `support gzip decompression`
