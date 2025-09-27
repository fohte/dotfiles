# Create PR

変更を push した後、以下の手順で PR を作成する。

## 1. `.claude/tmp/PULL_REQUEST_BODY.md` を作成する

以下のフォーマットで PR の説明のドラフトを `.claude/tmp/PULL_REQUEST_BODY.md` に記述する。このドラフトは日本語で書く。

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

1 で作成した `.claude/tmp/PULL_REQUEST_BODY.md` を人間にレビューしてもらい、必要に応じて修正する。

## 3. `gh pr create`コマンドでPRを作成

2 でレビューが完了したら、`.claude/tmp/PULL_REQUEST_BODY.md` を body として `gh pr create` コマンドを使用して PR を作成する。

ここで title, body は GitHub リポジトリが publilc であれば英語で記述し、private であれば日本語で記述する。
publc かどうかは `gh repo view --json isPrivate` コマンドで確認できる。

## 4. CI 実行を監視

`gh pr checks --watch`コマンドを使用してCIチェックを監視します。
CI が成功したら完了です。失敗した場合は、問題を調査・修正して再度プッシュしてください。
