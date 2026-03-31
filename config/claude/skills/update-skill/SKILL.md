---
name: update-skill
description: Use this skill when creating or updating skill files (SKILL.md). Provides path resolution rules, privacy guidelines, and formatting conventions for skill files.
---

# Update Skill

スキルファイル (SKILL.md) の作成・更新を行うためのガイドライン。

## 絶対禁止事項

- **プライベート情報の記載禁止**: プライベートリポジトリ名、社内サービス名、社内 URL、組織名、チーム名をスキルに含めない
- **具体的すぎる例の禁止**: 例を書く場合は汎用的な名前に置き換える (例: `my-app`, `example-service`, `example.com`)
- **スキルに関するルールはそのスキルファイルに書く**: 特定のスキルの使い方に関するルールは、そのスキルの SKILL.md に追加する。CLAUDE.md や auto memory に書かない。CLAUDE.md は全セッション共通の規約のみ
- **memory に逃げない**: スキルの改善が必要な場合は、memory ではなくスキルファイル自体を更新する。memory はスキルの代替にならない

## スキルファイルの場所

### グローバルスキル (全プロジェクト共通)

グローバルスキル (`/commit`, `/create-pr`, `/delegate-claude` など) は dotfiles リポジトリの `config/claude/skills/` で Git 管理されている。デプロイ時に `~/.claude/skills/` へ symlink されることで、全プロジェクトで利用可能になる。

- **編集先**: `~/ghq/github.com/fohte/dotfiles/config/claude/skills/<skill-name>/SKILL.md`
- **symlink 先**: `~/.claude/skills/<skill-name>/SKILL.md`
- `~/.claude/skills/` は dotfiles リポジトリの symlink。**編集は必ず dotfiles リポジトリ側 (`config/claude/skills/`) で行うこと**
- コミット先: dotfiles リポジトリ (`~/ghq/github.com/fohte/dotfiles`)

#### テンプレート生成型スキル

一部のスキルは SKILL.md 内で `!` + バッククォートによるコマンド実行でテンプレートから内容を動的に生成する。この場合、SKILL.md 自体ではなくテンプレートファイルを編集すること。

- **テンプレート置き場**: `~/ghq/github.com/fohte/dotfiles/config/claude/contexts/skill/<skill-name>/template.md`
- **判定方法**: SKILL.md の本文が `` !`runok exec -- gen-claude-template ...` `` のようなコマンド実行のみの場合、テンプレート生成型である
- **編集先**: SKILL.md ではなく `config/claude/contexts/skill/<skill-name>/template.md`

### プロジェクトローカルスキル (特定プロジェクト専用)

- **編集先**: `<project-root>/.claude/skills/<skill-name>/SKILL.md`
- コミット先: 現在のプロジェクトのリポジトリ

### どちらに配置するかの判断基準

- 特定プロジェクトでしか使わない -> プロジェクトローカル
- 複数プロジェクトで共通して使う -> グローバル (dotfiles)

## スキルファイルのフォーマット

### YAML Front Matter (必須)

```yaml
---
name: <skill-name>
description: <いつこのスキルを使うかの説明。英語で記述>
---
```

- `description` は「Use this skill when ...」の形式で、Claude Code がスキルを自動選択する際の判断基準になる

### 本文の構成

既存スキルに倣い、以下の構成を推奨:

1. **見出し**: スキル名
2. **概要**: スキルの目的を 1-2 行で説明
3. **禁止事項**: やってはいけないことの明記 (必要な場合)
4. **手順/ルール**: ステップバイステップの作業手順やルール
5. **良い例/悪い例**: 具体的な Good/Bad パターンの提示 (必要な場合)

### ライティングルール

- **抽象化を徹底する**: 具体的な事例がきっかけでルールを追加する場合でも、特定のツール名・ブランチ名・プロジェクト固有の概念を含めず、必ず一般化して記述すること。読み手がどのプロジェクト・どの状況でも適用できる表現にする
- 「何を」ではなく「なぜ」を説明する
- 箇条書きを活用し、簡潔に書く
- コードブロックには言語指定を付ける
- ファイル内で言語を統一する。既存ファイルを編集する場合は、そのファイルで使われている言語に合わせる。日本語と英語を混在させない

## 更新手順

1. 対象スキルの種類を判断 (グローバル or プロジェクトローカル)
2. 上記の場所ルールに従って編集先パスを特定
3. 既存のスキルファイルがあれば読んで内容を確認
4. フォーマットに従って作成・更新
5. プライバシーチェック: プライベート情報が含まれていないか確認
6. **コミットする (確認不要)**: 編集が完了したら、ユーザーに確認を求めずそのままコミットすること。グローバルスキルの場合は dotfiles リポジトリ (`~/ghq/github.com/fohte/dotfiles`) で、プロジェクトローカルスキルの場合は現在のリポジトリで `/commit` skill を使ってコミットする。現在のプロジェクトが dotfiles 以外であっても、dotfiles 側で別途コミットが必要。**コミットメッセージは必ず英語で書くこと** (dotfiles リポジトリのルール)

## プライバシーチェックリスト

スキルを書き終えたら以下を確認:

- 特定の会社名・組織名が含まれていないか
- プライベートリポジトリの名前やパスが含まれていないか
- 社内サービスの URL やドメインが含まれていないか
- 個人を特定できる情報が含まれていないか
- 例に使用した名前が汎用的か (`my-app`, `example-service` など)
