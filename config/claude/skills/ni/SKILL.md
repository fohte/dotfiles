---
name: ni
description: 'Use ni (@antfu/ni) for package manager operations. IMPORTANT: This skill MUST be used whenever you are about to run npm, yarn, pnpm, bun, npx, or any package manager command in a JavaScript/TypeScript project. This includes: installing dependencies (npm install, yarn add, pnpm add), running scripts (npm run, yarn run), executing packages (npx, pnpm dlx, bunx), updating or removing packages, or running CI installs. Also trigger when the user asks to add a package, run a build/test/lint script, or execute any Node.js tooling. Never run npm/yarn/pnpm/bun/npx directly - always consult this skill first to use the ni equivalent.'
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
