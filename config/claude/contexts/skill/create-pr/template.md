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

`git push` を実行する前に、push に含まれる全コミットの差分を `reviewer` subagent (Task ツール) でレビューする。これは `commit` skill の「レビューのタイミング」セクションで定義された必須ステップ。

```bash
git diff @{u}..HEAD
# upstream が未設定の場合
git diff origin/master..HEAD
```

この差分を `reviewer` subagent に渡し、結果を確認する:

- 🔴 Critical: push せず、追加コミットで修正してから再レビュー
- 🟡 Warning: 内容を判断して修正するか無視するか決める
- コミット単位レビュー済みでも、push 前レビューは必ず実行する。複数コミットをまたぐ整合性 (ある commit で追加した API の呼び出し漏れが別 commit にある等) は単一コミットでは見えない

レビューが通ったら `git push` を実行する。レビュー後に修正コミットを追加した場合は、再 push 前に追加分を再度レビューする。

## 1. PR body のドラフトを作成する

ドラフトは **常に日本語で書くこと**。
{{- if $repo_specs }}

`gh pr create` で PR を直接作成する。body は雑でよい。完璧さより速度を優先。

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
- **diff で見えるものは書かない**: ファイル名・件数・設定キー名・変更前後の行など
- **タスク指示文を転記しない**: 委任タスクや issue は実装者向け、PR description はレビュアー向け。実装者向けの注意 (「〇〇は残す」「△△は変更しない」、SHA/pin 値、手順の理由) はレビュアーに不要
- **コード要素はバッククォート**: ファイル名、関数名、変数名、コマンド名

### タイトル

- 50 文字以内、現在形の動詞 (「Add ...」「Fix ...」)、日本語で書く
- **客観的な変更の要約**: 「〜が成功するようにする」のような未確証の結果断定は不可
- ❌ `ghcr.io への Docker イメージ push が成功するようにする`
- ✅ `build-push-action の provenance attestation を無効化する`
  {{- if $release_please }}

このリポジトリは **release-please を使用している** ため、Conventional Commits 形式 (`<type>(<scope>): <description>`) を使用する。

- `feat` (minor bump): 新機能追加 (ユーザーに新しい価値を提供)
- `fix` (patch bump): バグ修正 (ユーザーが遭遇する問題を解決)
- `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` (bump なし): ユーザーに影響しない変更

判定: エンドユーザーに影響するか? YES なら `feat` or `fix`、NO なら何を変更したかで type を選ぶ。

よくある間違い:

- ❌ テスト「修正」を `fix` → テストはユーザーに影響しないので `test`
- ❌ CI を「直した」から `fix` → CI/ビルドは `chore` or `ci`
- ❌ リファクタリングで「バグを防いだ」から `fix` → 実バグが発生していなければ `refactor`

description ルール:

- 動詞形で書く (「〜する」「〜できるようにする」)
- type との二重表現を避ける: `fix(api): エラーハンドリングを修正` ❌ (fix + 修正 = 二重)
- 例: `feat(auth): ログイン機能を実装する`、`fix(api): エラーレスポンスが正しく返るようにする`
  {{- else }}

このリポジトリは release-please を使用していないため、`<scope>: <description>` 形式を使用する (例: `auth: ログイン機能を実装する`、`api: エラーレスポンスが正しく返るようにする`)。
{{- end }}

### Why / Purpose

#### 種類で書き分ける

- **バグ修正・改善**: 何が問題か (症状/影響) を最初の箇条書きで述べる
- **新規追加**: 何を実現したいか (目的/動機) を最初の箇条書きで述べる
    - 機能/リソースの一行説明だけで終わらせない。「で、なんでこれが今必要なの?」が残るなら動機が抜けている
    - 「〜がない」「〜が存在しない」と書かない。新しいものを作るのだから「ない」のは当然 → 実現したいことを書く
    - 委任タスクや issue の「背景」「目的・モチベーション」「直前の経緯」セクションは動機そのもの。Purpose に必ず反映する

#### 症状/影響だけ書き、技術的原因は書かない

技術的原因は What の子要素に書く。Why には書かない。

- ❌ `正規表現が v プレフィックスのみを考慮しており、semver 範囲指定子を抽出できなかった` (技術的原因)
- ✅ `CI の sync ワークフローが変更を検出できず「Already in sync」と誤判定していた` (症状)

ただしエラーメッセージ・再現条件・観測された状態 (status, health, 件数など) は症状の具体化なので残す。子要素で `last_error: "..."` のように引用してよい。

#### 「〜とき」「〜ので」で文を始めない

主語と結論を先に。`When ...` `If ...` で始めない。

- ❌ `When running multiple sessions, notifications cannot be distinguished`
- ✅ `Multiple parallel sessions cannot be distinguished from their notifications`

#### Why に解決策を混ぜない

「〇〇が問題。△△なら動くことが確認済み」のように、問題に続けて解決策の示唆を書かない。Why は問題/制約の事実だけ。解決策は What に。

#### 起点リンク (`from:`) と関連リンク

- **起点**: PR/issue があれば Why の最初の行に `- from: <URL>` で記載 (複数はカンマ区切り)。委任タスクや issue で「先行 PR」「参考 PR」「直前の経緯」として提示された URL は原則として起点
- **関連リンク**: 本文中、言及する箇所にリンクを埋め込む。リンクだけ貼らず、文脈の中に置く
    - ❌ `- 参考: https://github.com/foo/bar/pull/456`
    - ✅ `- 別リポジトリではこの問題が修正済み (https://github.com/foo/bar/pull/3)`
- **外部 org の cross-reference 防止**: PR を出すリポジトリと**異なる org** の URL は `redirect.github.com` 経由にする (`github.com` → `redirect.github.com` に置換)。同 org 内 (別リポジトリ含む) は通常通り
- **根拠は引用 + リンクをセットで** (原文をそのままコピー、要約・省略禁止):
    ```markdown
    > 引用文
    > [ドキュメント名](URL)
    ```
- **判断理由**: なぜこのタイミング/方法かの理由は子要素として補足。リンク先を開かなくても理解できるように書く

### What / Approach

#### Why の回答になるように書く

Why で述べた問題・目的に対し、この PR がどう解決/実現するかを述べる。Why との繋がりが見えないコマンド・機能の羅列は不可。

技術的原因は What の子要素に書く。バグ修正なら What の 1 行目に解決策、子要素として原因を補足。

```markdown
- 範囲指定子を含むバージョンを正しく抽出・比較できるようにする
    - 正規表現が `v` プレフィックスのみを考慮しており...
```

子要素は**現状の仕組み**の説明だけ書く。「どういう経緯で今の状態になったか」は実装方針と無関係なので書かない。

#### What を書く、How は書かない

- **What**: 変更の効果、ユーザー/システムへの影響
- **How (書かない)**: ファイルパス、行番号、具体的なコード変更
- ❌ `getUsers 関数の戻り値に nextCursor フィールドを追加`
- ✅ `API レスポンスにページネーションを追加`

#### 実装の内訳を並べない

diff で見える内訳をコロン区切り・括弧書き・サブバレット・diff/patch 形式で付けない。1 つの変更を構成要素に分解した列挙は全て内訳 (ファイル名、UI パーツ、テストカテゴリ、設定キー、件数、`+`/`-` 行など)。

- ❌ `プロジェクトの雛形を作成する: app.gemspec, Gemfile, Rakefile`
- ❌ `E2E テストを 38 件追加する` (件数)
- ✅ `プロジェクトの雛形を作成する`

既存パターンを踏襲しただけの注入経路 (例: SSM → helmfile → Secret) も diff で見えるので不要。内部タスク管理用語 (Phase 名、フェーズ番号、タスク ID) もレビュアーに伝わらないので書かない。

#### 変更の前後がわかる具体例を示す

設定例、コマンド実行例、出力例をコードブロックで示す。新機能なら「どう書くか・どう使うか」、バグ修正なら「修正前→修正後」。これは実装の内訳とは別物。

#### 無理に箇条書きにしない

説明が連続する場合や具体例を流れで読ませたい場合は段落形式の方が読みやすい。
{{- if $has_design_decisions }}

### Design decisions

実際に検討した案だけ書く。テーブルを埋めるための後付けは禁止:

- 最初から禁止されていた anti-pattern を「却下案」にしない
- 採用案を引き立てるためにでっち上げた比較対象を並べない
- **判断軸**自体も後付けで作らない。対立する代替案が自然に出てこない決定 (見せ方・命名・コメントスタイル等の「センスの問題」) は判断軸ではなく単なる採用案の説明 → Approach に 1 行書くか何も書かない

書ける却下案がない判断軸は、テーブルにせず採用案を箇条書きで述べるか、判断軸ごと削る。
{{- end }}

### フォーマット

#### 補足は括弧書きで流さずサブバレットに

- ❌ `入力をブロック単位で評価する (構文上の特殊ケースは引き続き 1 ブロック扱いのまま保持する)`
- ✅
    ```markdown
    - 入力をブロック単位で評価する
        - 構文上の特殊ケースは引き続き 1 ブロック扱いのまま保持する
    ```

短い言い換え・単位・略称展開 (例: `30 秒 (= 30000 ms)`) は括弧書きで構わない。

#### 箇条書きの 1 項目内に空行を入れない

空行を入れると Markdown レンダリング時に "loose list" になり `<p>` で囲まれて間隔が広がる。子要素 (引用・コード・サブバレット) は親項目の直後に空行なしでインデントして置く。「同じ項目内で段落を分けたい」と感じたら別項目に切り出す合図。

### セルフレビュー (ドラフト投入前に必ず行う)

`a ai pr-draft new` でドラフトを投入する前に、書いた本文に対して以下を行う:

1. **本ファイルを上から読み直す**。頭の中の要約で代替しない。事前に読んだルールは執筆中に頭から抜ける
2. ドラフトの各行を、上の各ルールの ❌/✅ パターンに 1 行ずつ照合
3. **減算チェック (独立工程)**: ドラフトの各行・サブバレット・テーブルセルを 1 つずつ取り上げ、「この行を消したらレビュアーが判断できなくなるか?」を自問。「あった方が親切」「念のため」「補足として」は全て削除対象。書いた本人は加算的に書きがちなので、ルール照合だけでは検出されない
4. 違反・冗長があれば修正してから次の「ドラフト投入コマンド」に進む

「ルールを読んだ = 違反していない」ではない。「違反していない = 簡潔」でもない。書いた後に開き直して照合し、減算チェックで本質に絞らない限り、違反・冗長を残したまま提出してユーザーから差し戻しを受ける。

### ドラフト投入コマンド

{{- if $has_pr_template }}

**以下の PR template のセクション構造に従うこと。**

```markdown
{{ $v.pr_template }}
```

- template の見出し構造をそのまま踏襲し、各セクションを埋める
- コメント指示 (`<!-- ... -->`) はドラフトから削除する
- 上記のセクション内部の書き方ルールは template の全セクションに適用する。Why/What の見出し固定など、セクション構造に関するルールは template の構造に置き換わる

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
{{- end }}

## 2. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断 (詳細は `workflow.md`)。

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしないこと。`while` ループ・`sleep` ループ・出力ファイルの繰り返し読み取りで進捗を確認してはならない。通知が届いてから出力ファイルを 1 回だけ読む。これは `a ai pr-draft review` だけでなく、`a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通するルール。

## 3. ユーザーの指示に応じた対応

`a ai pr-draft review` が exit code 0 以外で完了したら、**まず draft ファイルを最初から最後まで全行読むこと**。理由:

- ユーザーはエディタで任意の位置に自由形式のコメント行 (例: 「ここながすぎ」「この例まちがってる」) を書き足してから閉じることがある
- `steps.ready-for-translation` や `steps.submit` が変わっていなくても、本文中にユーザーの差し戻しコメントが残っている場合がある
- frontmatter の `steps` だけ見て「変更なし」と判断して次の review を再起動すると、ユーザーは同じ指摘を繰り返し書かされることになる

次に frontmatter と本文の両方を踏まえて、以下のいずれかに振り分ける。

### 修正指示の場合

{{- if not $repo_specs }}

**本ファイル (Step 1 のルール) を再読してから修正に入る。** 差し戻しは事前に違反に気づけなかったルールに起因している可能性が高く、指摘対象と思い込んだルールだけ確認すると別の違反を見逃す。
{{- end }}

修正のみ行い、**翻訳は行わない**。ユーザーが本文に書き込んだコメント行は、対応後に削除してから保存する。修正後は再度 `a ai pr-draft review` をバックグラウンドで実行し、完了を待つ。
{{- if $public }}

### ドラフト承認後の翻訳 (`steps.ready-for-translation: true` かつ日本語含む)

public repo では翻訳は**必須**。`steps.ready-for-translation: true` になったら title と body を英語に翻訳し、`steps.submit: false` に変更して保存。`a ai pr-draft review` をバックグラウンドで実行し、完了を待つ。すでに英語に翻訳済みの場合は再翻訳しない。

翻訳ルール:

- 直訳ではなく意図を汲んだ自然な英語にする
- type との二重表現を英語でも避ける (`fix: fix ...` 不可)
- `fix` type の description: 解決策を述べる (事実列挙ではなく)
    - `support` は新機能のニュアンスが強いので `fix` で使わない
- `feat` type の description: 「〜できるようにする」は `support` / `allow` (`enable` は「有効化」のニュアンスが強い)
- 文を `When` / `If` / `Since` / `Because` / `Without` で始めない
- 直訳避け、自然な構造に: `Fix existing violations and add annotations` → `Fix existing violations by adding annotations`
- 冗長表現避ける: `in order to` → `to`、`make sure to` → `ensure` または命令形
- `etc.` の代わりに `or similar tools` / `and related features` を使う
  {{- else }}

### Submit への進め方

翻訳は不要。ユーザーが `steps.submit: true` にしたら submit に進む。
{{- end }}

## 4. Submit

```bash
a ai pr-draft submit [--base main]
```

既存 PR がある場合は title と body を更新する。submit はユーザーが承認済みの場合のみ成功する。
{{- if $public }}
title と body に日本語が含まれていないこと。
{{- end }}

## {{ if $repo_specs }}2{{ else }}5{{ end }}. CI 実行を監視

`gh pr checks --watch` で CI を監視。失敗した場合は調査・修正して再 push。
{{ if $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}6{{ end }}. Gemini Code Assist レビューを待機

`a ai review wait` でレビュー完了を待機する。
{{ end }}

## {{ if $repo_specs }}{{ if $owner_fohte }}4{{ else }}3{{ end }}{{ else }}{{ if $owner_fohte }}7{{ else }}6{{ end }}{{ end }}. レビューコメントを確認して対応する

**CI や bot のチェックが `pass` でも、レビューコメントが付いていることがある。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin / Gemini Code Assist 等の自動レビュー、および人間のレビュアーからのコメントを確認して対応すること。

`check-pr-review` skill の中断・省略は禁止。「指摘がなさそうだから」「CI が通ったから」といった判断で skip してはならない。
