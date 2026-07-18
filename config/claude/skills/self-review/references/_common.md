# Common Review Reference

3 グループの reference (`behavior.md` / `structure.md` / `convention.md`) から共通参照される動作原則・禁止事項・出力ボイラープレート。各 group reference は冒頭でこのファイルを読み込み、固有の差分のみ自ファイルに記述する。

## 実行手順 (base reviewer 共通)

`~/.claude/agents/self-review-<group>.md` (`<group>` = `behavior` / `structure` / `convention`) はプロンプトに `range: <値>` の形式で `git diff` の対象範囲を受け取り、以下の手順で動く。

1. 自分の Bash tool で `git diff <range>` を実行し、レビュー対象の diff を取得する。
2. diff で変更されたファイルそれぞれについて、そのディレクトリから repo root まで遡って存在する `CLAUDE.md` を Read する (重複は 1 回のみ)。repo root に `.gemini/styleguide.md` があれば合わせて Read する。
3. `references/<group>.md` の「出力形式」セクションに厳密に従って結果を返す。指摘 1 件ごとに **指摘 ID** (`<観点番号>:<file>:<LINE>`) を必ず付ける。

## 動作原則

- レビュー対象は diff の変更行とその直接的な影響範囲のみ。out-of-scope な提案はしない。
- 修正案を出す前に、同リポジトリ内に同種の問題を正しく扱っている precedent があるか Grep / Read で確認する。
- 指摘の根拠は **precedent / 規約引用 / 具体的な失敗シナリオ** のいずれか。憶測で fix を提案しない。
- 重要度は「ユーザーが実際に困るか」で決める。規約違反でもユーザー影響が無ければ 🟡。
- 同じ観点が複数箇所に出現する場合は、最も代表的な 1-2 件に絞り「他 N 箇所も同様」と注記する。

## 重要度マーカー (汎用基準)

- 🔴 **Critical**: ユーザー observable な故障 / 破壊的変更 / セキュリティ exploit / ビルド即失敗 / データ損失
- 🟡 **Warning**: 条件付きで壊れる / 周辺退行 / 規約違反 / silent な挙動変更

🟢 (Nit) は使わない。指摘する価値が無ければ観点別評価で `✅` にする。

group 固有の重要度補足 (例: structure の「動作非依存指摘は原則 🟡」) は各 group reference 側で上書き定義する。

## 動作を実行して検証したい場合

指摘の裏付けに実際にコードを実行して確かめたい場合、検証用のファイル・スクリプトをこのリポジトリ内に作成しない (他セッションの作業ツリーを汚し、`git clean` 等で消えて再現不能になる)。検証は Docker コンテナ内で行う (`docker run --rm ...`)。`~/ghq` は colima VM に read-only mount されているため (`config/colima/colima.yaml`)、コンテナ内でどれだけ書き込んでもホストのリポジトリには影響しない。

## 禁止事項 (全 group 共通)

- linter / formatter の責務 (型を厳しくしろ、any 禁止、命名規則、インデント、import 順、未使用変数など)
- 「一般的なベストプラクティスでは...」のような precedent でない指摘
- 指摘詳細セクションでのポジティブ評価 (`LGTM` など)
- そのコミットで触っていない箇所への out-of-scope 提案
- 「Consider improving X」「You might want to」のような曖昧表現 (代わりに「X causes Y; do Z」と書く)
- 抽象的なテストカバレッジ要求 (具体的な漏れシナリオが特定できる場合のみ指摘)

## 観点別評価マーカー

- `✅`: この観点で壊れる可能性を検討した上で問題なし
- `⚠️ N/A`: この diff にこの観点が構造上関係しない (理由 1 行)
- `🔴` / `🟡`: 指摘あり。複数指摘がある観点は最重要マーカー + `(+ 🟡 N 件)` の総件数併記

## 出力形式ボイラープレート

ヘッダは `## 観点別評価 (<group>)` と `## 指摘詳細 (<group>)`。指摘詳細ゼロ件なら `指摘なし` の 1 行。

指摘 1 件あたりのテンプレ:

```
### <重要度> <症状を 1 行で>

**指摘 ID**: `<観点番号>:<file>:<LINE>` (集約側 dedup 用)
**観点**: <番号と名前>
**File**: `path/to/file.ext:LINE`

<詳細>: 何が起きるかを具体的に。条件分岐があれば「if X then Y」で。可能なら失敗を再現する具体値で trace。

**Precedent** (同リポジトリ内に正しい例があれば): `path/to/other.ext:LINE`

**Suggestion**:
\`\`\`<lang>
<修正コード>
\`\`\`

**Rule violation** (規約違反の場合のみ):
`<規約ファイル>:NN` は次を要求:
> <該当文言の引用>
```
