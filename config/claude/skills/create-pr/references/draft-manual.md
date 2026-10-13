# Claude がドラフトを書く flow

SKILL.md の Step 1, 2, 4 の中身。

## 1. ドラフトを作成する

以下のルールに従って書く。
ルールは書きながら守る。

ルールは以下のスクリプトの出力。release-please の有無・PR template の有無・`Design decisions` の有無による分岐は出力に反映済みなので、自分で判断し直さず、出力の全文を読んでから書く。

```bash
~/.agents/skills/create-pr/scripts/render-rules
```

### バッククォートのエスケープ

ドラフト本文にバッククォートを含める場合 (Rule 5 のコード要素表記など)、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

### ドラフト投入

`render-rules` の出力にある「PR template の構造」に従ったドラフト本文を投入する (コメント指示 `<!-- ... -->` は削除)。

```bash
cat <<'EOF' | a ai pr-draft new --title "PRタイトル"
<上記の構造に従ったドラフト本文>
EOF
```

ドラフトは決まったパスに作成される (`~/.agents/skills/create-pr/scripts/draft-path` で確認できる)。以降のコマンドではパス指定不要。

### Frontmatter

`a ai pr-draft new` で作成されるファイルには YAML frontmatter が含まれる。

```yaml
---
title: 'PRタイトル'
steps:
    ready-for-translation: false # english_output が true のときだけ存在
    submit: false
---
```

- `title`: PR のタイトル (submit 時に使用)
- `steps.ready-for-translation`: `english_output` が true のときだけ存在する。ドラフト承認フラグ。true になったら翻訳を実行する。`english_output` が true の repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する (改ざん防止)

**投入したら必ず Step 2 に進むこと。** Step 2 を飛ばして Step 3 (`a ai pr-draft review`) に進むのは禁止。

## 2. 文脈を持たないレビュアーによるレビュー (必須・スキップ禁止)

ドラフト投入後、`a ai pr-draft review` でユーザーに見せる前に必ず実行する。
書き手は本文に書かれていない因果を頭の中で補ってしまうので、判定は書き手と文脈を共有しないレビュアーに任せる。
「PR が小さい」「変更が単純」を理由としたスキップは禁止。

レビュアーを subagent (Task ツール) で起動してはならない。subagent への prompt を書き手が書くと、書き手の文脈が混ざる。

### 手順

1. 次のスクリプトを実行する。title と body、base branch との diff だけを渡されたレビュアーが、困りごとが変更でなぜ解消されるかと、不要な行や引用があるかに自由回答で答える。base branch が default branch でないときは引数で渡す

    ```bash
    ~/.agents/skills/create-pr/scripts/review-draft [<base_branch>]
    ```

2. レビュアーの回答を要約せずにユーザーに発話する
3. 指摘があればファイルを直接編集して直し、手順 1 からやり直す。同意しない指摘は、その理由をユーザーに発話する。指摘がなくなるか、残った指摘すべてに理由を発話したら Step 3 に進む

## 4. ユーザーの指示に応じた対応

`vibe_mode` では editor を開かず、委任元の返答に応じて対応する。

- 「draft にコメントを書いた」: draft にある委任元のコメントを反映し、コメント行を削除して create-pr skill の Step 3 に戻る。更新した draft を委任元に再提示するため、`a ai pr-draft review` は実行しない。
- 「承認」: `english_output` が true の場合は `steps.ready-for-translation` を true にし、`references/translate-rules.md` に従って title と body を英訳する。翻訳後は `steps.ready-for-translation` と `steps.submit` を false に戻し、title と body が英語であることを確認して create-pr skill の Step 5 に進む。`english_output` が false の場合は翻訳せず Step 5 に進む。

diff の内容で以下に振り分ける。

### 修正指示の場合

修正のみ行い**翻訳は行わない**。ユーザーが本文に書き込んだコメント行は対応後に削除する。修正後は通常フローでは再度 `a ai pr-draft review` をバックグラウンドで実行し、vibe mode では create-pr skill の Step 3 に戻る。

diff が `(no edits)` なら対応するものがないので、ユーザーに何を変更するか確認する。

### ドラフト承認後の翻訳 (`steps.ready-for-translation: true` かつ日本語含む)

`english_output` が false のリポジトリでは翻訳は発生しない。この節は読み飛ばす。

`english_output` が true のリポジトリでは翻訳必須。`steps.ready-for-translation: true` になったら title と body を英語に翻訳し、`steps.ready-for-translation` と `steps.submit` を false に変更して保存。通常フローでは `a ai pr-draft review` をバックグラウンドで実行し、vibe mode では create-pr skill の Step 5 に進む。すでに英語に翻訳済みなら再翻訳しない。

翻訳ルールは `references/translate-rules.md` を読んで従う。
