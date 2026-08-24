{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $repo_specs := eq $v.repo.name "specs" -}}
{{- $release_please := eq (conv.ToString $v.has_release_please) "true" -}}
{{- $has_pr_template := ne (conv.ToString $v.pr_template) "" -}}
{{- $has_design_decisions := and $has_pr_template (strings.Contains "Design decisions" (conv.ToString $v.pr_template)) -}}
{{- $agy := eq $v.role "private" -}}

# Create PR

以下の手順で PR を作成する。

**重要:** diff の確認には必ず remote の default branch と比較すること (`git diff "origin/$(git main)...HEAD"`)。ローカルの default branch は古い可能性がある。

## 開始時の宣言 (必須・最初の応答で実行)

create-pr skill を起動したら、**最初の応答で**以下の必須ステップを列挙し、これから実行する旨を宣言すること。宣言なしに Step 1 以降に進むのは禁止。

- Step 0: 未 push コミットの push (`commit` skill の push 手順に従う) と、branch の diff の crit story 作成 + crit レビュー (承認まで loop 中はコミット・push しない)
  {{- if not $agy }}
- Step 2: PR body セルフレビュー (全ルール照合 + 原則照合 + 減算の独立 3 工程)
  {{- end }}

「小さい PR だから」「変更が単純だから」「明らかに問題ないから」「効率を優先したい」を理由としたスキップは禁止。これらは典型的な自己判断スキップシグナルで、検出したら必ず実行する。skill のテキストに「必須」「スキップ禁止」と書かれているステップを Claude 側の判断で省略しない。スキップしてよいのはユーザーが該当ステップを名指しで明示的に skip 指示した場合のみ。

## 0. push と diff の crit story 作成 + crit レビュー (必須)

未 push のコミットがあれば `commit` skill の push 手順 (`self-review` skill でのレビュー → 🔴/🟡 対応 → `git push`) に従って push する。
`self-review` はこの skill から直接呼び出さない。呼び出しは `commit` skill 側の責務とし、二重実行を避ける。

```bash
git log @{u}..HEAD --oneline
# upstream 未設定なら
git log "origin/$(git main)..HEAD" --oneline
```

未 push のコミットがなければ push は不要。

push の要否にかかわらず、base branch との diff をユーザーにレビューしてもらい、承認されるまで Step 1 に進まない。委任先の無人セッションでも待つ。手順は以下の 2 段階:

1. `crit:crit-story` skill で story を作成する。story の文章 (prologue の `title` / `overview` / `key_changes` / `risks`、各 chapter の `title` / `summary`) は**日本語で書く**。`crit story --guide` が返す guide 本文は英語だが、それは出力言語の指定ではない
    - ingest (`crit story --story-file`) には必ず `--no-open` を付ける。ブラウザを開くのは次のレビュー loop の責務で、両方が開くと同じレビューが 2 タブになる
2. `crit:crit` skill でレビュー loop を回し、承認を待つ。`crit story` は story を保存して即座に終了するため、承認待ちのブロックは `crit:crit` 側が担う

指摘への対応は crit の loop 内で完結させる。**loop 中はコミットも push もしない** (= `commit` skill も `self-review` skill も呼ばない)。crit の diff は base branch から working tree までなので、未コミットの修正もそのまま次の round でレビューできる。1 指摘ごとに self-review + コミットを挟むと、承認前の中間状態に重い工程を繰り返すことになる。

1. 指摘を修正する
2. `crit comment --reply-to <id>` で対応内容を返信する (作法は `crit:crit-cli` skill)
3. 修正で diff の構成が変わり story の記述とずれたなら story を作り直す (ingest 時に `--refresh --no-open`)。story の文章が依然として正しい微修正なら作り直さない
4. 次の round に進む

承認された時点で初めて、`commit` skill の push 手順に従って loop 中の修正をまとめてコミット・push し、Step 1 に進む。

## 1. PR body のドラフトを作成する

ドラフトは **常に日本語で書くこと**。日本語の文体・表現については `japanese-tech-writing` skill の規範に従う (一文一行、LLM っぽい空句の禁止、冗長の排除など)。
{{- if $repo_specs }}

`gh pr create` で直接作成。body は雑でよい。完璧さより速度を優先。

```bash
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## Why

- ...

## What

- ...
EOF
)"
```

{{- else }}
{{- if $agy }}

Claude は本文を読まない。以下のスクリプトが diff・コミットメッセージ・書き方ルールをまとめて agy (Antigravity CLI) に渡し、ルールを満たした本文を 1 回の呼び出しで書かせて `a ai pr-draft new` に投入する。セルフレビューはこの中で完結しており、独立した工程はない。

```bash
~/.claude/skills/create-pr/scripts/agy-write-draft
```

失敗したら (非 0 終了) 標準エラーを確認して対応する。成功したら Step 2 はないので、そのまま Step 3 (`a ai pr-draft review`) に進む。
{{- else }}

以下のルールに従って書く。
ルール本文は「書きながら守る」ためのもので、書き終えたら Step 2 で全ルールを 1 件ずつ照合する。
ルール本文中の減算チェックも書きながら当てるものであり、Step 2 の独立工程の代替にはならない。

{{ tmpl.Inline "create-pr-rules" (file.Read (print (env.Getenv "HOME") "/.claude/contexts/skill/create-pr/rules.md")) }}

### バッククォートのエスケープ

ドラフト本文にバッククォートを含める場合 (Rule 5 のコード要素表記など)、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

### ドラフト投入

上記の PR template の構造に従ったドラフト本文を投入する (コメント指示 `<!-- ... -->` は削除)。

```bash
cat <<'EOF' | a ai pr-draft new --title "PRタイトル"
<上記の構造に従ったドラフト本文>
EOF
```

ドラフトは決まったパスに作成される (`~/.claude/skills/create-pr/scripts/draft-path` で確認できる)。以降のコマンドではパス指定不要。

### Frontmatter

`a ai pr-draft new` で作成されるファイルには YAML frontmatter が含まれる。

```yaml
---
title: 'PRタイトル'
steps:
{{- if $public }}
    ready-for-translation: false
{{- end }}
    submit: false
---
```

- `title`: PR のタイトル (submit 時に使用)
  {{- if $public }}
- `steps.ready-for-translation`: ドラフト承認フラグ。true になったら翻訳を実行する。public repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
  {{- end }}
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する (改ざん防止)

**投入したら必ず Step 2 に進むこと。** Step 2 を飛ばして Step 3 (`a ai pr-draft review`) に進むのは禁止。

## 2. セルフレビュー (必須・スキップ禁止)

ドラフト投入後、`a ai pr-draft review` でユーザーに見せる前に必ず実行する。スキップすると「ながすぎ」「内訳多い」等の差し戻しを受ける。

**「PR が小さい」「変更が単純」「明らかに問題ない」「効率を優先したい」を理由としたスキップは禁止**。これらは典型的な自己判断スキップシグナルで、検出したら必ず実行する。PR の規模に関わらず本ステップは実行する (Rule 14「変更規模に body を合わせる」は self-review の中で適用するルールであって、self-review 自体の省略理由ではない)。

**本ステップは subagent (Task ツール) に委任してはならない。**
判定は本セッションでユーザーに発話することが要件であり、委任すると発話がユーザーに届かず、レビュー可能な形で残らない。
context 残量の少なさは委任理由にならない。

### 手順

1. 投入されたファイル (`~/.claude/skills/create-pr/scripts/draft-path` で確認できるパス) を Read する
2. **Step 1 で示した全ルールを順に**、各ルールについて以下の形式でユーザーに発話する{{ if $has_design_decisions }} (Rule 1〜14){{ else }} (Rule 1〜8, 10〜14。Rule 9 は省略){{ end }}:

    ```
    Rule N. <名前>: <ドラフトの該当箇所と判定理由> → ✅ または ❌
    ```

    - ドラフト全体を一括で「OK」と判定するのは禁止。各ルールごとに必ず 1 行発話する
    - 該当箇所がないルール (例: バグ修正でない PR の Rule 2 後半、リンクがない PR の Rule 5) は `→ N/A (該当なし)` と書く
    - ❌ の場合は引用とともに具体的な該当行を示し、修正方針を 1 行添える
    - 「許容範囲」「軽微なので OK」のような曖昧な ✅ 判定は禁止。違反していれば ❌

3. **原則照合 (独立工程)**: 各バレット・テーブルセルが大原則 (「本質だけ短く書く」「中身の列挙ではなく意図を書く」) を守っているかを 1 行ごとに直接評価する。Rule 6 の文章レビューでは「文全体の意味が意図寄りだから OK」と通してしまう経路があるため、この独立工程で原則を直接照合する。判定は主観に依存するが、「機械的抽出のフリ」をせず原則を正面から評価することで判定責任を明確化する。形式:

    ```
    原則照合: <該当行> → 「中身の列挙ではなく意図」: ✅ または ❌ (理由)
    ```

4. **減算チェック (独立工程)**: ルール照合後、各行・サブバレット・テーブルセルを 1 つずつ取り上げ、以下 3 つの問いを順に当てる:
    - Q1. この行を消したらレビュアーが判断できなくなるか?
    - Q2. その情報は起点 issue / コード差分 / コミットメッセージ / 運用ダッシュボード等で確認できるか?
    - Q3. PR を出すリポジトリのレビュアー (同 org / 同チーム前提) が既に知っている内容ではないか? 社内標準ツールの説明、組織内の通例パターン、内部コマンドの動作などを「外部の人向け」に冗長に解説していないか?

    Q1「いいえ」/ Q2「はい」/ Q3「既知」のいずれかに該当したら削る。「あった方が親切」「念のため」「補足として」「裏取り材料として」は全て削除対象。これも以下の形式で発話する:

    ```
    減算: <該当行> → 残す (理由) または 削る
    ```

    **警戒シグナル絶対則**: 減算チェックで「削る」判定が一個も出なかった場合は基準が緩んでいる確定シグナル。以下を強制する:
    - **「再評価しても全部残す妥当」「判断微妙だが残す」は警戒シグナル発動時には無効判定**。これらは典型的な逃げ道。判定を見直すための再評価であって、現状追認するための再評価ではない
    - 警戒シグナルが鳴ったら、各行に対して「これは本質か?」を問い直す。本質でない (= 残す理由が「あった方が親切」「網羅性のため」「裏取り材料」止まり) と判明した行は削除または隣接バレットへ統合する。**少なくとも 1 件の削除/統合を実行するまで次のステップに進んではならない**
    - 量で測るな (「半分以下にする」等の量的目標を立てない)。本質か否かの質的判定で残す/削るを決め、結果として短くなる
    - 「中規模 PR だからこの長さで適切」「網羅性として必要」は self-justification の典型。Rule 14 は「埋めにいくと必ず過剰になる」と明記している。網羅志向で「埋める」のではなく、本質志向で「本質でないものを残さない」

5. ❌ と「削る」判定があればファイルを直接編集して修正。修正後、もう一度 Step 2 を最初からやり直す (1 回の修正で複数ルール違反が連鎖して発生することがあるため)
   {{- end }}
   {{- end }}

## 3. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断する:

- exit code 0: ユーザーが承認した
- exit code 1: 未承認 (エディタを承認せず閉じた)。ユーザーに何を変更するか確認する
- exit code 2: エディタが既に開いている。**追加アクションは不要**。ユーザーにエディタ上でファイルを読み込み直すよう伝える (例: Neovim なら `:e`)。再度 review コマンドを実行したり、エディタを閉じるよう促してはならない
- exit code 3: ターミナルエミュレータが起動できなかった (macOS スリープ中などで 10s 内に起動失敗)。ロックファイルは残らないので、ユーザーにターミナルが利用可能になってから再実行を依頼する。自動でリトライしてはならない (スリープ状態が解消されない限り再失敗するため)

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしない。`while`/`sleep` ループや出力ファイルの繰り返し読み取りで進捗確認してはならない。これは `a ai pr-draft review` だけでなく `a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通。

## 4. ユーザーの指示に応じた対応

{{- if $agy }}

`a ai pr-draft review` の exit code だけで判断する。frontmatter や本文を Claude が直接読む必要はない。

exit code 1 (未承認) の場合、以下を実行して agy に直させ、再度 Step 3 の `a ai pr-draft review` を実行する。ユーザーのコメントへの対応と、承認後の翻訳 (`steps.ready-for-translation: true` になった場合{{ if not $public }}。このリポジトリでは翻訳は発生しない{{ end }}) のどちらが必要かはスクリプトが frontmatter を見て自動判定する。

```bash
~/.claude/skills/create-pr/scripts/agy-advance-draft
```

{{- else }}

`a ai pr-draft review` の stdout (frontmatter と本文中のユーザーコメントを含む) を踏まえて以下に振り分ける。

### 修正指示の場合

修正のみ行い**翻訳は行わない**。ユーザーが本文に書き込んだコメント行は対応後に削除する。修正後は再度 `a ai pr-draft review` をバックグラウンドで実行。
{{- if $public }}

### ドラフト承認後の翻訳 (`steps.ready-for-translation: true` かつ日本語含む)

public repo では翻訳必須。`steps.ready-for-translation: true` になったら title と body を英語に翻訳し、`steps.submit: false` に変更して保存。`a ai pr-draft review` をバックグラウンドで実行。すでに英語に翻訳済みなら再翻訳しない。

翻訳ルール:

{{ file.Read (print (env.Getenv "HOME") "/.claude/contexts/skill/create-pr/translate-rules.md") }}
{{- else }}

### Submit への進め方

翻訳不要。ユーザーが `steps.submit: true` にしたら submit に進む。
{{- end }}
{{- end }}

## 5. Submit

```bash
a ai pr-draft submit [--base main]
```

既存 PR がある場合は title と body を更新する。submit はユーザー承認済みの場合のみ成功する。
{{- if $public }}
title と body に日本語が含まれていないこと。
{{- end }}

## {{ if $repo_specs }}2{{ else }}6{{ end }}. CI 実行を監視

`gh pr checks --watch` で CI を監視。失敗したら調査・修正して再 push。
{{ if not $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}7{{ end }}. レビューコメントを確認して対応する

**CI や bot のチェックが `pass` でもレビューコメントは付く。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin 等の自動レビューと人間のコメントを確認して対応する。

`check-pr-review` skill の中断・省略は禁止。
{{ end }}
