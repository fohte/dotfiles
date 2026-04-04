# 英語ライティングガイドライン

翻訳時および英語で記述する際の一般的なルール。

## 文の始め方

- **前置きや条件から始めない**: 主語と結論を先に述べる。特に `When`, `If`, `Since`, `Because`, `Without` などで文を始めない
    - ❌ `Need to enforce proper error handling`
    - ❌ `When using this library, memory leaks may occur`
    - ✅ `Enforce proper error handling`
    - ✅ `This library may cause memory leaks under certain conditions`

## 自然な英語表現

- **直訳を避け、意図を伝える**: 日本語の構造をそのまま英語にせず、英語として自然な表現に言い換える
    - ❌ `Fix existing violations and add annotations` (並列に見えるが実際は手段と目的)
    - ✅ `Fix existing violations by adding annotations` (因果関係が明確)
- **冗長な表現を避ける**:
    - ❌ `in order to` -> ✅ `to`
    - ❌ `make sure to` -> ✅ `ensure` or just use imperative

## その他の注意

- **「etc.」の使用を避ける**: 「or similar tools」「and related features」などを使う
