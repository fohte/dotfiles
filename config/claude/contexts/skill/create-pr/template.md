{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $repo_specs := eq $v.repo.name "specs" -}}
{{- $release_please := eq (conv.ToString $v.has_release_please) "true" -}}
{{- $has_pr_template := ne (conv.ToString $v.pr_template) "" -}}
{{- $has_design_decisions := and $has_pr_template (strings.Contains "Design decisions" (conv.ToString $v.pr_template)) -}}

# Create PR

以下の手順で PR を作成する。

**重要:** diff の確認には必ず `origin/master` と比較すること (`git diff origin/master...HEAD`)。ローカルの `master` は古い可能性がある。

ワークフロー詳細 (Frontmatter、エスケープ、exit code 等) は `~/.claude/skills/create-pr/workflow.md` を参照。

## 0. push 前レビュー (必須)

`git push` の前に、push に含まれる全コミットの差分を `reviewer` subagent (Task ツール) でレビューする (`commit` skill の必須ステップ)。

```bash
git diff @{u}..HEAD
# upstream 未設定なら
git diff origin/master..HEAD
```

- 🔴 Critical: push せず追加コミットで修正 → 再レビュー
- 🟡 Warning: 修正するか無視するか判断
- コミット単位レビュー済みでも push 前レビューは必須 (複数コミット間の整合性は単一コミットでは見えない)

## 1. PR body のドラフトを作成する

ドラフトは **常に日本語で書くこと**。
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

### 大原則

- **本質だけ短く書く**: 「これ以上削るとレビュアーが判断できなくなる」極限を狙う。「念のため」「補足」「参考までに」と思ったら削る
- **コード要素はバッククォート**: ファイル名、関数名、変数名、コマンド名

### ルール一覧

ドラフトはこの 12 ルールに従って書き、Step 2 のセルフレビューで全ルール照合する。

#### Rule 1. 客観的な変更要約 (タイトル)

50 文字以内、現在形の動詞、日本語で書く。客観的な変更要約のみ。「〜が成功するようにする」のような未確証の結果断定は不可。description は動詞形、type/scope と description の二重表現 (`fix(api): エラーハンドリングを修正`) は不可。
{{- if $release_please }}

このリポジトリは release-please を使用しているため Conventional Commits 形式 (`<type>(<scope>): <description>`) を使う。type 判定は「エンドユーザーに影響するか?」: YES なら新機能 = `feat` / バグ修正 = `fix`、NO なら変更対象で `docs`/`test`/`refactor`/`perf`/`build`/`ci`/`chore`/`style` から選ぶ。
{{- else }}

このリポジトリは release-please 未使用なので `<scope>: <description>` (例: `auth: ログイン機能を実装する`) を使う。
{{- end }}

#### Rule 2. バグは症状、新規は目的・動機 (Why)

バグ修正は「何が問題か」(症状/影響) を最初の箇条書きで述べる。新規追加は「何を実現したいか」(目的/動機) を述べる。エラーメッセージ・観測された状態 (status, health, 件数等) は症状の具体化なので残す。

**Why は「ユーザーが困っている状態」だけ書く**。以下はすべて Why ではない (What の子要素へ送るか、そもそも書かない):

- 技術的原因 (「〜が〜していたため」「内部で〜が起きているため」)
- 既存仕組みの欠陥説明 (「既存の X は Y にしか対応していない」「Z は A を抱えるため B に到達しない」)
- 状況・統計の細分化 (「環境 X の割合が N%」「原因のうち M% が Y 起因」など)
- 関連コンポーネントの挙動説明

判定の目安: その文を読んだレビュアーが「で、ユーザーは何に困ってるの?」と聞き返したくなるなら Why ではない。Why は「困りごと」「実現したい状態」だけ書く。

新規追加で機能/リソースの一行説明だけで終わらせない (「で、なんで今これが必要なの?」が残るなら動機が抜けている)。「〜がない」「〜が存在しない」と書かない (新しいものを作るのだから「ない」のは当然 → 実現したいことを書く)。委任タスクや issue の「背景」「目的」「直前の経緯」セクションは動機そのもの。Purpose に必ず反映する。

委任タスクや issue から Why を拾うときは、提示された統計・技術的説明・既存仕組みの欠陥を**そのままコピペしない**。コピペすると Why の抽象度が技術原因まで下がる。困りごとに翻訳して書く。

#### Rule 3. 主語と結論を先に書く (Why)

「〜とき」「〜ので」で文を始めない。`When` `If` `Since` `Because` `Without` でも始めない。

#### Rule 4. 解決策を Why に混ぜない (Why)

Why は問題/制約の事実だけ。「△△なら動くことが確認済み」のような解決策の方向性は What に書く。

#### Rule 5. 起点・関連リンクは引用 + 文脈つきで埋め込む (Why)

- **起点リンク**: PR/issue があれば Why の最初の行に `- from: <URL>` (複数はカンマ区切り)。委任タスクで「先行 PR」「参考 PR」「直前の経緯」として提示された URL は原則として起点
- **関連リンク**: 本文中、言及する箇所に文脈ごと埋め込む。`参考: <URL>` のような裸リンクは不可
- **外部 org の cross-reference 防止**: PR を出すリポジトリと異なる org の URL は `redirect.github.com` 経由 (`github.com` → `redirect.github.com` に置換)。同 org 内 (別リポジトリ含む) は通常通り
- **根拠は引用 + リンクをセット** (原文ママ、要約・省略禁止):
    ```markdown
    > 引用文
    > [ドキュメント名](URL)
    ```
- **判断理由**: なぜこのタイミング/方法かの理由は子要素として補足。リンクだけの羅列は不可

#### Rule 6. Why の回答になっている (What)

What の各項目は Why で述べた問題・目的への回答になっている。Why との繋がりが見えないコマンド・機能の羅列は不可。**変更の効果・影響 (= ユーザー視点で何が変わるか / 困りごとがどう解決されるか) を書く**。diff から読み取れるもの (ファイルパス・行番号・具体的なコード変更・件数・設定キー名など) は書かない。

**実装手段は What ではない**。以下はコード差分・コメント・コミットメッセージの責務であって What に書かない (Rule 7 の「内訳」と区別: 内訳でなくとも手段なら書かない):

- アルゴリズム / 通信方式 / 検知方式の選択 (どう実現するかの方法論)
- 内部処理順序・タイミング (起動時/終了時/定期実行などの実行タイミングや並行制御)
- 内部識別子・パラメータ名 (内部で使う変数名・フィールド名・定数名・属性キー名)
- 内部状態管理の仕組み (重複防止・排他制御・リソース解放のための実装上の工夫)

判定の目安: その文を消した時にユーザーから見た振る舞いが変わるなら効果、変わらないなら手段。手段は書かない。

技術的原因は What の子要素として補足する (バグ修正の場合):

```markdown
- 範囲指定子を含むバージョンを正しく抽出・比較できるようにする
    - 正規表現が `v` プレフィックスのみを考慮しており...
```

子要素は現状の仕組みの説明だけ。「どういう経緯で今の状態になったか」は書かない。

#### Rule 7. 実装の内訳・内部用語を並べない (What)

diff で見える内訳をコロン区切り・括弧書き・サブバレット・diff/patch 形式で付けない。1 つの変更を構成要素に分解した列挙は全て内訳 (ファイル名、UI パーツ、テストカテゴリ、設定キー、件数、`+`/`-` 行など)。

- ❌ `プロジェクトの雛形を作成する: app.gemspec, Gemfile, Rakefile`
- ✅ `プロジェクトの雛形を作成する`

内部タスク管理用語 (Phase 名、フェーズ番号、タスク ID 等) もレビュアーに伝わらないので書かない。

#### Rule 8. 具体例で前後を示す (What)

設定例・コマンド実行例・出力例をコードブロックで示す。バグ修正は「修正前→修正後」。これは Rule 7 の内訳とは別物 (読み手が変更を理解するための具体例)。流れで読ませたい時は無理に箇条書きにせず段落形式を使う。
{{- if $has_design_decisions }}

#### Rule 9. 検討した案・判断軸だけ書く (Design decisions)

実際に迷って比較した案だけ書く。テーブルを埋めるための後付けは全て禁止:

- 最初から禁止されていた anti-pattern を「却下案」にしない
- 採用案を引き立てるためにでっち上げた比較対象を並べない
- 判断軸自体も後付けで作らない。対立する代替案が自然に出てこない決定 (見せ方・命名・コメントスタイル等の「センスの問題」) は判断軸ではなく単なる採用案の説明 → Approach に 1 行書くか何も書かない
- 却下案を 1 つでも書ける軸は採用案だけ Approach に書かず Design decisions に切り出す
  {{- end }}

#### Rule 10. 補足は括弧書きでなくサブバレット (Format)

親項目の文末に `(...)` で補足を詰めない。サブバレットに切り出す。短い言い換え・単位・略称展開は括弧書きで構わない。

```markdown
- 入力をブロック単位で評価する
    - 構文上の特殊ケースは引き続き 1 ブロック扱いのまま保持する
```

#### Rule 11. 箇条書き項目内に空行を入れない (Format)

空行を入れると "loose list" 化して `<p>` に囲まれ間隔が広がる。子要素 (引用・コード・サブバレット) は親項目の直後に空行なしでインデント。「同じ項目内で段落を分けたい」と感じたら別項目に切り出す合図。

#### Rule 12. タスク指示文を転記しない (全般)

委任タスクや issue は実装者向け。実装者向けの注意はレビュアーには不要なので書かない:

- 「〇〇は残す」「△△は変更しない」のような現状維持・スコープ外への言及 (diff で見えないものは存在自体が見えない)
- action/image の SHA、バージョン番号、具体的な pin 値
- 「〇〇を入れるため △△ が必要」のような既存パターン踏襲・実装上の手順理由

### ドラフト投入

{{- if $has_pr_template }}

**以下の PR template のセクション構造に従うこと。**

```markdown
{{ $v.pr_template }}
```

- template の見出し構造をそのまま踏襲し、各セクションを埋める
- コメント指示 (`<!-- ... -->`) はドラフトから削除
- 上記の書き方ルールは template の全セクションに適用する。Why/What の見出し固定など構造ルールは template の構造に置き換わる

```bash
cat <<'EOF' | a ai pr-draft new --title "PRタイトル"
<template の構造に従ったドラフト本文>
EOF
```

{{- else }}

```bash
echo "## Why

- <修正系: 症状/影響のみ / 新規追加: 目的>

## What

- <変更の効果を簡潔に>
    - <技術的原因があれば子要素として補足>" | a ai pr-draft new --title "PRタイトル"
```

{{- end }}

ドラフトは `/tmp/pr-body-draft/<owner>/<repo>/<branch>.md` に作成される。以降のコマンドではパス指定不要。

**投入したら必ず Step 2 に進むこと。** Step 2 を飛ばして Step 3 (`a ai pr-draft review`) に進むのは禁止。

## 2. セルフレビュー (必須・スキップ禁止)

ドラフト投入後、`a ai pr-draft review` でユーザーに見せる前に必ず実行する。スキップすると「ながすぎ」「内訳多い」等の差し戻しを受ける。

### 手順

1. 投入されたファイル (`/tmp/pr-body-draft/<owner>/<repo>/<branch>.md`) を Read する
2. **Step 1 で示した全ルールを順に**、各ルールについて以下の形式でユーザーに発話する{{ if $has_design_decisions }} (Rule 1〜12){{ else }} (Rule 1〜8, 10〜12。Rule 9 は省略){{ end }}:

    ```
    Rule N. <名前>: <ドラフトの該当箇所と判定理由> → ✅ または ❌
    ```

    - ドラフト全体を一括で「OK」と判定するのは禁止。各ルールごとに必ず 1 行発話する
    - 該当箇所がないルール (例: バグ修正でない PR の Rule 2 後半、リンクがない PR の Rule 5) は `→ N/A (該当なし)` と書く
    - ❌ の場合は引用とともに具体的な該当行を示し、修正方針を 1 行添える
    - 「許容範囲」「軽微なので OK」のような曖昧な ✅ 判定は禁止。違反していれば ❌

3. **減算チェック (独立工程)**: ルール照合後、各行・サブバレット・テーブルセルを 1 つずつ取り上げ、以下 2 つの問いを順に当てる:
    - Q1. この行を消したらレビュアーが判断できなくなるか?
    - Q2. その情報は起点 issue / コード差分 / コミットメッセージ / 運用ダッシュボード等で確認できるか?

    どちらかでも「いいえ」(Q1) または「はい」(Q2) なら削る。「あった方が親切」「念のため」「補足として」は全て削除対象。これも以下の形式で発話する:

    ```
    減算: <該当行> → 残す (理由) または 削る
    ```

    **警戒シグナル**: 減算チェックで「削る」判定が一個も出なかった場合は基準が「あった方が親切」に緩んでいる兆候。Why/What がそれぞれ 2 項目以上ある場合、通常 1 つは削れる。再度 Q1/Q2 を厳しめに当て直す。

4. ❌ と「削る」判定があればファイルを直接編集して修正。修正後、もう一度 Step 2 を最初からやり直す (1 回の修正で複数ルール違反が連鎖して発生することがあるため)
   {{- end }}

## 3. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断 (詳細は `workflow.md`)。

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしない。`while`/`sleep` ループや出力ファイルの繰り返し読み取りで進捗確認してはならない。これは `a ai pr-draft review` だけでなく `a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通。

## 4. ユーザーの指示に応じた対応

`a ai pr-draft review` の stdout (frontmatter と本文中のユーザーコメントを含む) を踏まえて以下に振り分ける。

### 修正指示の場合

修正のみ行い**翻訳は行わない**。ユーザーが本文に書き込んだコメント行は対応後に削除する。修正後は再度 `a ai pr-draft review` をバックグラウンドで実行。
{{- if $public }}

### ドラフト承認後の翻訳 (`steps.ready-for-translation: true` かつ日本語含む)

public repo では翻訳必須。`steps.ready-for-translation: true` になったら title と body を英語に翻訳し、`steps.submit: false` に変更して保存。`a ai pr-draft review` をバックグラウンドで実行。すでに英語に翻訳済みなら再翻訳しない。

翻訳ルール:

- 直訳ではなく意図を汲んだ自然な英語に
- type との二重表現を英語でも避ける (`fix: fix ...` 不可)
- `fix` type: 解決策を述べる (`support` は新機能ニュアンスなので `fix` で使わない)
- `feat` type: 「〜できるようにする」は `support`/`allow` (`enable` は「有効化」ニュアンス)
- 文を `When`/`If`/`Since`/`Because`/`Without` で始めない
- 自然な構造に: `Fix existing violations and add annotations` → `Fix existing violations by adding annotations`
- 冗長表現を避ける: `in order to` → `to`、`make sure to` → `ensure` or 命令形
- `etc.` ではなく `or similar tools` / `and related features`
  {{- else }}

### Submit への進め方

翻訳不要。ユーザーが `steps.submit: true` にしたら submit に進む。
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
{{ if $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}7{{ end }}. Gemini Code Assist レビューを待機

`a ai review wait` でレビュー完了を待機。
{{ end }}

## {{ if $repo_specs }}{{ if $owner_fohte }}4{{ else }}3{{ end }}{{ else }}{{ if $owner_fohte }}8{{ else }}7{{ end }}{{ end }}. レビューコメントを確認して対応する

**CI や bot のチェックが `pass` でもレビューコメントは付く。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin / Gemini Code Assist 等の自動レビューと人間のコメントを確認して対応する。

`check-pr-review` skill の中断・省略は禁止。
