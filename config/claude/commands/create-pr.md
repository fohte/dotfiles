# Create PR

変更を push した後、以下の手順で PR を作成する。

## 1. PR body のドラフトファイルを作成する

`echo` コマンドを使用して、PR の説明のドラフトを `claude-pr-draft new` コマンドに渡す。

**重要:** このドラフトは **常に日本語で書くこと**（public repo、private repo に関わらず）。

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

コマンドは `/tmp` に YAML frontmatter 付きの一時ファイルを作成し、stdin から受け取った内容を追記して、ファイルパスを stdout に出力する（その結果を記憶して以降のステップで使用する）。

### Frontmatter について

作成されるファイルには以下の YAML frontmatter が含まれる:

```yaml
---
title: ""
english: true  # public repo なら true、private repo なら false
approve: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `english`: true の場合、title と body に日本語が含まれていると submit が失敗する
- `approve`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）

### 注意事項

- **Why/What のみ記述**: それ以外のセクション (「期待される効果」「参考」など) は書かない
- **Why には関連 issue/PR のリンクを含める**: 詳細は issue に記載されているため
- **簡潔に**: 過剰な数値データ、技術的詳細、Markdown 装飾は避ける
- fohte/tasks repo への issue の参照は含めないこと (プライベートリポジトリのため)

## 2. 人間に PR の説明をレビューしてもらう

`claude-pr-draft review` コマンドを実行して、Wezterm の新しいウィンドウで Neovim を開き、ユーザーに直接編集してもらう（引数にはステップ 1 で取得したファイルパスを使用する）。

```bash
claude-pr-draft review <filepath>
```

**重要:** このコマンドは非同期で実行されるため、コマンドが即座に完了してもユーザーはまだ編集中である。ユーザーがレビューを完了して明示的に指示するまで、次のステップには進まないこと。

## 3. draft ファイルを翻訳（english: true の場合のみ）

ユーザーがレビューを完了したら、draft ファイルを読み込んで frontmatter の `english` フィールドを確認する。

`english: false` の場合はこのステップをスキップして、ステップ 4 に進む。

`english: true` の場合:
1. title と body を英語に翻訳する
2. `approve: false` に変更する（翻訳によりハッシュが無効になるため）
3. ファイルを上書き保存する
4. 再度 `claude-pr-draft review <filepath>` を実行して、ユーザーに翻訳内容を確認してもらう
5. ユーザーがレビューを完了して明示的に指示するまで待機する

## 4. `claude-pr-draft submit` で PR を作成

```bash
claude-pr-draft submit <filepath> [--base main]
```

frontmatter の `title` が PR タイトルとして、body 部分が PR 本文として使用される。

**注意:** submit は以下の条件をすべて満たす場合のみ成功する:
- `.lock` ファイルがない（レビュー完了）
- `.approve` ファイルがある（approve: true でエディタを終了した）
- ファイルのハッシュが `.approve` と一致する（承認後に改ざんされていない）

## 5. CI 実行を監視

`gh pr checks --watch`コマンドを使用してCIチェックを監視します。
CI が成功したら完了です。失敗した場合は、問題を調査・修正して再度プッシュしてください。
