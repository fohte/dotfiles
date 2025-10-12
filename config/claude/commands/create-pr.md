# Create PR

変更を push した後、以下の手順で PR を作成する。

## 1. PR body のドラフトファイルを作成する

`claude-pr-draft new` コマンドを実行して、一時ファイルのパスを取得する（stdout に出力されるので、その結果を記憶して以降のステップで使用する）。

```bash
claude-pr-draft new
```

次に、Write ツールを使用して、上記コマンドが出力したファイルパスに、以下のフォーマットで PR の説明のドラフトを記述する。このドラフトは日本語で書く。

```markdown
## Why

- なぜこのPRが必要なのかの、目的、背景、動機を説明

## What

- この PR が merge されたら何が変わるのかを、個々のコミットではなく全体的な影響を現在形で記述
```

### 注意事項

- Markdown (`code`、**太字** など) を使ってわかりやすくする
- 関連する項目はネストした箇条書きでグループ化する
- fohte/tasks repo への issue の参照は含めないこと (プライベートリポジトリのため)

## 2. 人間に PR の説明をレビューしてもらう

`claude-pr-draft review` コマンドを実行して、Wezterm の新しいウィンドウで Neovim を開き、ユーザーに直接編集してもらう（引数にはステップ 1 で取得したファイルパスを使用する）。

```bash
claude-pr-draft review <filepath>
```

ユーザーが編集を終えたら、必要に応じて再度ドラフトを確認し、さらに修正が必要な場合は再度 `review` サブコマンドで編集してもらう。

## 3. `claude-pr-draft submit` で PR を作成

2 でレビューが完了したら、`claude-pr-draft submit` コマンドを使用して PR を作成する（引数にはステップ 1 で取得したファイルパスを使用する）。

```bash
claude-pr-draft submit <filepath> <gh pr create と同じオプション>
```

例：
```bash
claude-pr-draft submit <filepath> --title "..." --base "$(git main)"
```

ここで title, body は GitHub リポジトリが public であれば英語で記述し、private であれば日本語で記述する。
public かどうかは `gh repo view --json isPrivate` コマンドで確認できる。

## 4. CI 実行を監視

`gh pr checks --watch`コマンドを使用してCIチェックを監視します。
CI が成功したら完了です。失敗した場合は、問題を調査・修正して再度プッシュしてください。
