# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

このリポジトリは macOS と Linux 環境用の個人用 dotfiles です。シンボリックリンクベースのデプロイシステムで、Neovim、Zsh、tmux、WezTerm などの様々な開発ツールの設定を管理しています。

## デプロイメントシステム

### コアコンセプト

- **シンボリックリンク管理**: `symlinks` ファイルが設定ソース (`config/*`) からシステムの宛先へのマッピングを定義
- **タグベースデプロイ**: `scripts/deploy` スクリプトが `-t` オプションで選択的なデプロイをサポート

### ファイルを追加・変更する際の注意

1. 新しい設定ファイルを追加する場合は `symlinks` ファイルを更新すること
2. 設定は `config/<tool-name>/` ディレクトリに配置すること
3. タグベースのデプロイをサポートするため、`symlinks` に適切な `match_tag` ブロックを追加すること

## ツールバージョン管理

### mise

このリポジトリは mise を使用してツールバージョンを管理しています:

- **グローバル設定**: `config/mise/config.toml` (Node、Python、Ruby、CLI ツールなど)
- **リポジトリローカル設定**: `mise.toml` (pre-commit、shellcheck、shfmt など)

## 設定の構造

### config/ ディレクトリ

各ツールの設定は `config/<tool-name>/` に配置されています:

```
config/
├── nvim/                    # Neovim 設定 (Lua)
│   ├── init.lua             # エントリーポイント
│   ├── lua/
│   │   ├── core/            # コア設定 (コマンド、マッピング、filetype)
│   │   ├── plugins/         # プラグイン設定 (40+ ファイル)
│   │   ├── user/            # カスタム機能
│   │   └── utils.lua        # ユーティリティ関数
│   ├── ftplugin/            # ファイルタイプ別設定
│   ├── snippets/            # コードスニペット
│   └── queries/             # Treesitter クエリ
│
├── zsh/                     # Zsh 設定
│   ├── root_zshenv          # エントリーポイント (~/.zshenv)
│   ├── starship.toml        # Starship プロンプト設定
│   ├── env/                 # 環境変数とパス設定
│   │   ├── fzf.zsh
│   │   ├── mise.zsh
│   │   └── ...
│   └── rc/                  # ランタイム設定
│       ├── alias.rc.zsh     # エイリアス定義
│       ├── history.rc.zsh   # 履歴設定
│       ├── bindkey/         # キーバインディング設定
│       ├── functions/       # カスタム関数
│       ├── install/         # プラグインマネージャーインストール
│       └── zinit.rc.zsh     # プラグイン定義
│
├── bin/                     # カスタムスクリプト (PATH が通っている)
│
├── claude/                  # Claude Code 設定
│   ├── _CLAUDE.md           # グローバルな CLAUDE.md (~/.claude/CLAUDE.md)
│   └── settings.json        # Claude Code 設定
│
├── tmux/                    # tmux 設定
├── git/                     # Git グローバル設定と ignore パターン
├── wezterm/                 # WezTerm 設定
├── hammerspoon/             # hammerspoon 設定
├── karabiner/               # Karabiner-Elements 設定
├── mise/                    # mise (グローバル) 設定
├── aquaskk/                 # AquaSKK (日本語入力) 設定
├── bettertouchtool/         # BetterTouchTool プリセット
├── espanso/                 # espanso 設定
├── gh/                      # gh 設定
├── raycast/                 # Raycast 設定 (quicklinks のみ)
├── editorconfig/            # EditorConfig 設定
├── gnupg/                   # GnuPG 設定
├── ime/                     # IME の汎用的な設定
├── prettier/                # Prettier 設定
├── rg/                      # ripgrep 設定
├── rubocop/                 # RuboCop 設定
└── tig/                     # tig 設定
```

### Makefile 構造

- **ルート Makefile**: すべてのサブディレクトリの Makefile を再帰的に実行
- **サブ Makefile**: 特定の設定用のビルドタスク (例: `config/aquaskk/Makefile` は romaji テーブルを生成)

```bash
# すべてのサブ Makefile を実行
make

# 特定のディレクトリの Makefile を実行
make -C config/aquaskk
```
