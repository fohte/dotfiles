# pr-draft ワークフロー詳細

## Frontmatter

`a ai pr-draft new` で作成されるファイルには YAML frontmatter が含まれる。

### public repo の場合

```yaml
---
title: 'PRタイトル'
steps:
    ready-for-translation: false
    submit: false
---
```

- `title`: PR のタイトル (submit 時に使用)
- `steps.ready-for-translation`: ドラフト承認フラグ。true になったら翻訳を実行する。public repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
- `steps.submit`: true ���するとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する (改ざん防止)

### private repo の場合

```yaml
---
title: 'PRタイトル'
steps:
    submit: false
---
```

- `title`: PR のタイトル (submit 時に使用)
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する (改ざん防止)

## バッククォートのエスケープ

Markdown のコードブロックにバッククォートを含める場合、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

## `a ai pr-draft review` の exit code

- exit code 0: ユーザーが承認した
- exit code 1: 未承認 (エディタを承認せず閉じた)。ユーザーに何を変更するか確認する
- exit code 2: エディタが既に開いている。追加アクションは不要。ユーザーにエディタ上でファイルを読み込み直すよう伝える (例: Neovim なら `:e`)。再度 review コマンドを実行したり、エディタを閉じるよう促してはならない
