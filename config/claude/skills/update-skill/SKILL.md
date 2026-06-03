---
name: update-skill
description: Use this skill whenever creating, editing, or improving a skill file (SKILL.md) — including writing a new skill from scratch, tightening an existing one, splitting it into references, or tuning its description for better triggering. Covers file location rules (global vs project, dotfiles symlinks), SKILL.md anatomy, Progressive Disclosure, writing style, description tuning, and the privacy/commit checklist.
---

# Update Skill

スキルファイル (SKILL.md) の作成・更新ガイド。

## 原則

- **スキルのルールはそのスキル内に書く**: 特定スキルの使い方ルールは SKILL.md に置く。CLAUDE.md / auto memory に逃がさない (CLAUDE.md は全セッション共通の規約のみ)
- **memory はスキルの代替にならない**: 改善が必要なら memory ではなく SKILL.md を更新する
- **プライベート情報を書かない**: 詳細は末尾チェックリスト参照

## スキルファイルの場所

### グローバルスキル (全プロジェクト共通)

dotfiles の `config/claude/skills/` で Git 管理し、`~/.claude/skills/` へ symlink される。

- **編集先**: `~/ghq/github.com/fohte/dotfiles/config/claude/skills/<skill-name>/SKILL.md`
- `~/.claude/skills/` は symlink。**必ず dotfiles 側で編集**
- コミット先: dotfiles リポジトリ

### プロジェクトローカルスキル

- **編集先**: `<project-root>/.claude/skills/<skill-name>/SKILL.md`
- 配置基準: 特定プロジェクト専用 → ローカル / 複数プロジェクトで使う → グローバル

### テンプレート生成型スキル (グローバル / ローカル共通)

SKILL.md の本文が `!` + `` `runok exec -- gen-claude-template <type> <name>` `` のようなコマンド実行のみの場合、内容は動的生成される。グローバル / ローカルどちらでも発生しうる。

- **判定**: SKILL.md 本文がコマンド実行のみで構成されているか
- **編集先**: SKILL.md ではなく `config/claude/contexts/skill/<skill-name>/template.md`

## SKILL.md の構造

### YAML Front Matter (必須)

```yaml
---
name: <skill-name>
description: <英語で記述>
---
```

### description の書き方

- **「何をする」+「いつ使う」両方を含める**。when-to-use 情報は description にだけ書き、本文には書かない (本文に書くと trigger 判断に使われない)
- Claude は skill を **undertrigger しがち** → やや pushy に。具体的な trigger キーワード・状況を列挙する
- BAD: `"How to build a dashboard."`
- GOOD: `"Use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data — even if they don't explicitly say 'dashboard'."`

### 本文の構成 (推奨)

1. スキル名見出し
2. 概要 (1-2 行)
3. 原則 / 禁止事項 (必要時)
4. 手順・ルール
5. Good/Bad 例 (必要時)

## Progressive Disclosure とディレクトリ構成

スキルは 3 階層でロードされる。「常に context にある metadata」「trigger 時に読まれる SKILL.md」「必要時のみ読まれる bundled resources」を意識して分割する。

### 行数の目安

- **SKILL.md は 500 行以下**を目安にする。超えたら `references/` に分割し、本文には**いつ読むかのガイダンス**付きでポインタを置く
- 300 行を超える reference には目次を入れる
- 複数 domain / variant を扱うなら domain 別に reference を分ける (例: `references/aws.md`, `gcp.md`)

### Bundled Resources

SKILL.md と同じディレクトリに置けるサブディレクトリ。役割で分ける。

- **`scripts/`**: 決まりきった処理や繰り返し処理を行う実行可能コード。Claude が毎回同じ helper を書いているならここに置くサイン。中身は context にロードされず、Claude が必要時に実行する
- **`references/`**: 必要時に Claude が読む補助ドキュメント。詳細仕様、スキーマ、domain 別ガイド、長大な例など。本文から「いつ読むか」明示してポインタを張る
- **`assets/`**: 出力に使う素材 (テンプレ、アイコン、フォント、雛形ファイル等)

## ライティングルール

- **imperative form (命令形) で書く**
- **「なぜ」を書く**。`MUST` の羅列ではなく、読み手が理由を理解できるようにする
- **全 caps `ALWAYS` / `NEVER` は yellow flag**: 多用しない。可能なら理由を添えて reframe する。`ALWAYS use this exact template:` のように出力フォーマットを強制するケースなど、明確な理由がある場面に限定する
- **抽象化を徹底する**: 具体的事例がきっかけでも、特定ツール名・ブランチ名・プロジェクト固有概念を含めず一般化する
- 箇条書きで簡潔に。コードブロックには言語指定。日本語と英語を混在させない (既存ファイルは既存言語に合わせる)

## 更新手順

1. **場所特定**: グローバル / ローカル / テンプレ生成型を判断して編集先パスを決める
2. **分析**: 期待外れだった事象 (ユーザーの指摘、Claude の出力ずれ) を 1 つずつ列挙する
3. **戦略立案**: 各事象について SKILL.md のどこをどう改修するか決める
    - **効果評価**: 根本原因に効く戦略か? 表面的テクニックでないか?
    - **矮小化禁止**: 「自分の手順不備」「セルフレビュー未実行」「今回は例外」で片付けない。Claude が間違えるなら他セッションも同条件で間違える → ルール側を強化する対象
    - **個別具体に走らない**: 今回の事象を 1 段抽象化した根本原因を言語化し、その派生事象も同じ改修でカバーされるか確認
4. **編集**: 改修を反映。500 行を超えそうなら `references/` 分割を検討
5. **セルフレビュー (必須・スキップ禁止)**: `git diff` を読み、以下をユーザーに発話する。**頭の中の戦略ではなく実際に書かれた文面**を評価する
    - 事象 / 修正内容 (差分から引用) / 改善寄与
    - 懸念 (重複、過剰、効果薄、抽象度不足、循環参照、既存記述との矛盾、文言曖昧)
    - 懸念が残るなら step 3 か 4 に戻る。再修正後はもう一度セルフレビュー
6. **コミット (確認不要)**: 下記チェックリストを通過したら `/commit` でコミット。グローバルスキルは dotfiles リポジトリ側で。**コミットメッセージは英語**

## チェックリスト (コミット前)

- 会社名・組織名・チーム名が含まれていないか
- プライベートリポジトリ名・パス・社内 URL・社内サービス名が含まれていないか
- 個人特定情報がないか
- 例の名前は汎用 (`my-app` 等) か
- 全 caps `ALWAYS` / `NEVER` を必要以上に使っていないか
- when-to-use 情報を description に書いたか (本文に置いていないか)
- SKILL.md が 500 行を超えていないか (超えるなら `references/` 分割)
