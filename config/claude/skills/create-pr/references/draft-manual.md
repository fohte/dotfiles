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

## 2. ドラフトのレビュー (必須・スキップ禁止)

ドラフト投入後、`a ai pr-draft review` でユーザーに見せる前に必ず実行する。
「PR が小さい」「変更が単純」を理由としたスキップは禁止。

### 手順

`review-draft` は `self-review/reviewers.yaml` と role overlay の `review_draft` 設定から engine / model / reasoning effort を解決し、各値の出典と実効値を表示する。Codex は macOS sandbox または Linux seccomp profile が使える環境だけを許可する。fake credential と架空 prompt を外部通信なしの sandbox 内から loopback endpoint に送る probe の request trace を検査し、request と client metadata が許可済みの形であること、実効 sandbox が OS に応じて `seatbelt` / `seccomp` であること、developer input が bundled base instructions、user input が script の review prompt、追加 input や tool schema がないことを確認してから、同じ catalog と gate 設定で実レビューを行う。tool declarations がない probe で bundled base instructions が重複して送られる経路を避けるため、`features.incremental_tools=false` も指定する。mise shim の trust state 用に `MISE_STATE_DIR` を優先し、未設定なら `XDG_STATE_HOME/mise`、さらに未設定なら `$HOME/.local/state/mise` を使う。相対 path は wrapper の呼出元 PWD 基準で絶対化する。隔離環境へ渡す mise state の値は解決した `MISE_STATE_DIR` のみとし、`HOME` / `CODEX_HOME` / `XDG_CONFIG_HOME` などは引き続き隔離する。Linux では seccomp profile を開始できない環境、または request capture を検証できない場合に fail closed する。model metadata または probe request が検証条件と合わない場合も script は非 0 で終了する。Claude は `claude.ai` 認証と `configDirectory` の解決を確認した後、clean env で空の cwd から起動する。`restricted` / `safe mode`、session persistence 無効、tools / MCP / slash commands の無効化、hooks / skills / plugins の無効化を適用し、`system/init` の tools / MCP / skills / plugins / agents / slash commands が空であることを検証する。assistant message に tool_use がなく、`parent_tool_use_id` が null で、先頭の init が 1 件、末尾に成功した result が 1 件あることも確認する。未知の stream-json event type と `system` の非 `init` subtype は許容する。失敗、`invalid` / `partial` / `empty` な回答、設問 1 と 2 の回答が揃わない結果は必須レビュー未完了として扱い、fallback engine へ自動で切り替えない。

review-draft は HEAD / base / draft / prompt の hash を記録し、実行中にどれかが変われば失敗する。Codex は `turn.started` の後に唯一の completed agent message があり、エラー event がなく、末尾が `turn.completed` のときだけ採用する。Claude は exit 0 かつ result subtype が success、is_error が false、stop_reason が `end_turn` または `stop_sequence` の最終 result だけを採用する。stdout が 1 MiB を超える場合、または設問 1 と 2 の見出しと回答が揃わない場合も失敗する。

Claude helper は OS レベルの network sandbox を設けず、CLI は claude.ai の API 通信にネットワークを使う。managed settings、remote settings cache、user settings による provider と review context への影響は事前検査しない。Linux は init-context の検証経路が未確認のため fail closed する。

1. 機械的に判定できるルールをスクリプトで検査する。違反があれば内容を出力して非 0 で終わるので、ファイルを直して exit 0 になるまで繰り返す

    ```bash
    ~/.agents/skills/create-pr/scripts/lint-draft.ts
    ```

2. draft を書いたセッションの context を持たないレビュアーに draft を読ませる。書いたセッションは、本文に書かれていない因果も context にある委任内容や調査結果から読み取ってしまうので、意味の判定はレビュアーに任せる。次のスクリプトを実行すると、title と body、base branch との diff だけを渡されたレビュアーが、困りごとが変更でなぜ解消されるかと、不要な行や引用、1 行にまとめられる行があるかに自由回答で答える。base branch が default branch でないときは引数で渡す

    ```bash
    ~/.agents/skills/create-pr/scripts/review-draft [<base_branch>]
    ```

    レビュアーを subagent (Task ツール) で起動してはならない。subagent への prompt を書き手が書くと、書き手の文脈が混ざる。

3. レビュアーの回答を要約せずにユーザーに発話する
4. 指摘があればファイルを直接編集して直す。同意しない指摘は、その理由をユーザーに発話する。直したら手順 1 と手順 2 を 1 回だけやり直し、その回答も手順 3 のとおり発話して Step 3 に進む。レビュアーは毎回何かしら指摘するので、指摘がなくなるまで繰り返さない。残った指摘はユーザーが Step 3 で判断する

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
