---
name: delegate-claude
description: 別の worktree で別の Claude Code インスタンスにタスクを委任する。現在のセッションをブロックせずに並列で作業を進めたいときに使用する。
---

# 別の Claude Code インスタンスにタスクを委任する

`a wm new --prompt` を使って、別の worktree で別の Claude Code インスタンスに処理を委任する。

## 使い方

```bash
a wm new <branch-name> --prompt "<instructions>"
```

- `branch-name`: 新しい環境用に作成するブランチ名
- `--prompt`: 新しい Claude Code インスタンスへの指示

### オプション

- `--from <ref>`: ベースとなる ref を指定 (デフォルト: main ブランチ)
    - 例: `a wm new feature-x --from origin/develop --prompt "..."`
    - Renovate の PR をテストする場合: `a wm new test-upgrade --from origin/renovate/some-branch --prompt "..."`

### 例

```bash
# 現在のリポジトリ
a wm new feature-login --prompt "メール/パスワード認証によるログイン機能を実装"

# 別のリポジトリ
cd ~/ghq/github.com/fohte/other-repo && a wm new feature-x --prompt "機能 X を実装"
```

実行すると:

1. 指定したブランチで新しい git worktree を作成
2. Neovim と Claude Code を含む新しい tmux ウィンドウを開く
3. Claude Code にプロンプトを自動送信

## 委任時の注意事項

- **ブランチ名**: ブランチ名に `/` を含めないこと。代わりにハイフンを使う (例: `fix/login-bug` ではなく `fix-login-bug`)。ブランチには `fohte/` がプレフィックスとして付くため、`fix/...` だと `fohte/fix/...` になり冗長
- 新しいインスタンスは独立した worktree で作業するため、現在の作業と競合しない

## プロンプト構造 (必須)

委任先の Claude Code インスタンスは**現在の会話の事前知識を持っていない**。以下の構造を使って十分なコンテキストを含めること。

**最重要: 「背景」セクションに最も力を入れて書く。** 委任先が自律的に適切な判断を下せるかどうかは、背景の質で決まる。

```
## 背景

### 目的・モチベーション
[なぜこのタスクが必要か。何を実現したいか。ユーザーにとってどんな価値があるか]

### 問題の詳細 (バグ修正の場合)
[症状、再現手順、期待される動作と実際の動作の差分]

### 調査済みの内容
[すでに分かっていること。調査結果とその根拠 (ログ、コード箇所、ドキュメントなど)]

### 参考リンク
[関連する Issue / PR / ドキュメントの URL。親 Issue や親 PR がある場合は必ず含める]

## 現状
[現在のコードの状態。関連ファイルやアーキテクチャ。すでに決まっている設計判断]

## ゴール
[最終的に何が達成されていればよいか。成功条件]
```

### 書き方のルール

- **背景を最も厚く書く**: プロンプト全体の半分以上を背景に充てる。委任先が「なぜこの作業をするのか」を深く理解できるようにする
- **ゴールだけ伝え、手順は指示しない**: 「何を達成してほしいか」を書き、「どうやるか」は委任先に任せる。具体的な実装ステップ、commit するかどうか、PR を作るかどうかなどの手順を指示しない
- **根拠を含める**: 調査結果や判断には、その根拠 (ログ、コード箇所、エラーメッセージ、ドキュメント URL など) を添える
- **リンクを貼る**: Issue / PR / ドキュメントなど、参考にしたものは URL を貼る。特に親 Issue や関連 PR は必須

### 良い例

```bash
a wm new fix-auth-timeout --prompt "## 背景

### 目的・モチベーション
セッションタイムアウトが短すぎてユーザーが頻繁に再ログインを強いられている。本来 30 分のはずが 5 分で切れる。

### 問題の詳細
- 症状: ログイン後、5 分間操作しないとセッションが切れて再ログインが必要になる
- 期待される動作: 30 分間操作がなくてもセッションが維持される
- 再現: ログイン後 5 分待つと 401 が返る

### 調査済みの内容
- src/auth/session.ts の SessionManager クラスで TTL を設定しているが、config/auth.json の timeout 値 (1800秒) が反映されていない
- Redis の TTL を確認したところ実際に 300 秒で設定されている (根拠: redis-cli TTL session:xxx の結果)
- 最近の JWT からセッション認証への移行 (PR #142) でデフォルト値のフォールバックが追加され、config の値を上書きしている可能性が高い

### 参考リンク
- Issue: https://github.com/example/repo/issues/210
- 関連 PR (認証移行): https://github.com/example/repo/pull/142

## 現状
- 認証は src/auth/session.ts の SessionManager クラスで処理
- セッション設定は config/auth.json に定義
- Redis をセッションストレージとして使用

## ゴール
セッションタイムアウトが config/auth.json の設定値 (30 分) どおりに動作する。"
```

### 悪い例

```bash
# NG: コンテキスト不足 - 新しいインスタンスは「そのバグ」が何か分からない
a wm new fix-bug --prompt "さっき話したバグを直して"

# NG: 手順を指示しすぎ - 委任先の自律性を奪う
a wm new fix-auth --prompt "## タスク
1. src/auth/session.ts を開く
2. 42 行目の TTL を 300 から 1800 に変更
3. テストを追加
4. commit はしないこと"
```
