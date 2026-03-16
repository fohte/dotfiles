---
name: ni
description: Use ni (@antfu/ni) for package manager operations. Use this skill when installing dependencies, running scripts, or executing packages in JavaScript/TypeScript projects.
---

# ni - Package Manager Agnostic Commands

JavaScript/TypeScript プロジェクトでパッケージマネージャー操作を行う際は、`npm`, `yarn`, `pnpm`, `bun` などを直接使用せず、`@antfu/ni` のコマンドを使用すること。

`ni` はプロジェクトの lockfile を自動検出し、適切なパッケージマネージャーコマンドに変換する。

## コマンド対応表

| ni コマンド   | 用途                   | npm 相当               |
| ------------- | ---------------------- | ---------------------- |
| `ni`          | 依存関係のインストール | `npm install`          |
| `ni <pkg>`    | パッケージ追加         | `npm install <pkg>`    |
| `ni -D <pkg>` | devDependencies に追加 | `npm install -D <pkg>` |
| `nr <script>` | スクリプト実行         | `npm run <script>`     |
| `nlx <pkg>`   | パッケージ実行         | `npx <pkg>`            |
| `nu`          | 依存関係の更新         | `npm update`           |
| `nun <pkg>`   | パッケージ削除         | `npm uninstall <pkg>`  |
| `nci`         | クリーンインストール   | `npm ci`               |

## 使用例

```bash
# 依存関係をインストール
ni

# パッケージを追加
ni axios

# devDependencies に追加
ni -D typescript @types/node

# スクリプト実行
nr build
nr test
nr lint

# npx 相当
nlx eslint --fix .
nlx prettier --write .

# パッケージ削除
nun lodash

# クリーンインストール
nci
```

## 重要: nr を優先して使うこと

- `npx vite build` や `nlx eslint --fix .` のようにパッケージを直接実行する前に、まず `package.json` の `scripts` に対応するスクリプトがないか確認すること
- 対応するスクリプトがあれば `nr build`, `nr lint` など `nr <script>` を使うこと
- `nlx` は `package.json` の `scripts` に対応するものがない場合にのみ使用すること

## 注意事項

- `ni` は mise でグローバルインストール済み (`config/mise/home-config.toml`)
- lockfile が存在しないプロジェクトでは、`ni` はデフォルトで npm を使用する
- `nr` でスクリプトを実行する際、引数は `--` なしでそのまま渡せる
