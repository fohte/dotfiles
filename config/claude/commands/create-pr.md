# Create PR

変更を push した後、以下の手順で PR を作成する。

## 1. PR body のドラフトファイルを作成する

`echo` コマンドを使用して、PR の説明のドラフトを `claude-pr-draft new` コマンドに渡す。このドラフトは日本語で書く。

```bash
echo "## Why

- なぜこのPRが必要なのかの、目的、背景、動機を説明

## What

- この PR が merge されたら何が変わるのかを、個々のコミットではなく全体的な影響を現在形で記述" | claude-pr-draft new
```

注意: Markdown のコードブロックにバッククォートを含める場合、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```


コマンドは `/tmp` に一時ファイルを作成し、stdin から受け取った内容を書き込んで、ファイルパスを stdout に出力する（その結果を記憶して以降のステップで使用する）。

### 注意事項

- Markdown (`code`、**太字** など) を使ってわかりやすくする
- 関連する項目はネストした箇条書きでグループ化する
- fohte/tasks repo への issue の参照は含めないこと (プライベートリポジトリのため)

## 2. 人間に PR の説明をレビューしてもらう

`claude-pr-draft review` コマンドを実行して、Wezterm の新しいウィンドウで Neovim を開き、ユーザーに直接編集してもらう（引数にはステップ 1 で取得したファイルパスを使用する）。

```bash
claude-pr-draft review <filepath>
```

**重要:** このコマンドは非同期で実行されるため、コマンドが即座に完了してもユーザーはまだ編集中である。ユーザーがレビューを完了して明示的に指示するまで、次のステップには進まないこと。

## 3. `claude-pr-draft submit` で PR を作成

ユーザーがレビュー完了を伝えたら、`claude-pr-draft submit` コマンドを使用して PR を作成する（引数にはステップ 1 で取得したファイルパスを使用する）。

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
