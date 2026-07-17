{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}

# Renovate PR のトリアージ

Renovate が作成した依存関係更新 PR を、影響範囲を調査した上でトリアージし、マージまたは委任する。

no-look merge は避け、各 PR の breaking changes と影響範囲を把握してから判断する。

## 全体フロー

1. **PR 一覧の取得と概要把握**
2. **各 PR の CI 状態の確認**
3. **各 PR の breaking changes 調査** (最重要・**sub-agent 並列実行必須**)
4. **PR 間の依存関係分析とグルーピング**
5. **ユーザーへの報告と承認**
6. **Approve コメント**
7. **対応の実行** (直接マージ or 委任)

## Step 1: PR 一覧の取得

```bash
gh pr list --author 'renovate[bot]' --json number,title,headRefName,url \
  --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"'
```

各 PR の diff から、変更されたファイルとバージョン変更の詳細を取得する:

```bash
gh pr diff <number> --name-only
gh pr diff <number> | grep -A2 -B2 '<package-name>'
```

## Step 2: CI 状態の確認

**breaking changes 調査の前にこの確認を必ず先行させる**。CI が落ちている / 想定外の結果が出ている PR を「直接マージ可」と先入観で扱わないため、最初に状態を把握する。「breaking changes はない」と「CI が green」は別問題で、両方が揃わない限り「直接マージ」は提案できない。

各 PR について以下を確認する:

1. **CI 全 check の状態**

    ```bash
    gh pr checks <number>
    ```

    fail / pending / skipping を全て把握する。**skipping を「無視してよい」扱いしない**: 本来動くはずの check が skipping なら、それ自体が問題の可能性がある。同形式の他 PR と比較して、付くべき check が抜けていないか確認する

2. **bot コメントの本文を最後まで読む**

    ```bash
    gh pr view <number> --comments
    ```

    結果コメントを精読する。本文を読まないと検知できないもの (warning、想定外の副作用、部分スキップなど) があるため、SUCCESS だけを根拠に「OK」としない

3. **fail / 想定外結果の根本原因を必ず一段掘る**: 「rerun すれば直りそう」「無関係だから無視」と即断しない。最近マージされた同種 PR や base ブランチで同じ事象が起きているかを比較し、新規発生なのか既存問題なのか切り分けてから判断する

## Step 3: Breaking changes の調査 (sub-agent 並列実行)

**このステップは必ず PR ごとに sub-agent (Agent ツール) を起動して並列調査する。** 親セッションで一括して PR body のリリースノート抜粋だけ眺めて判断するのは禁止。表面的な調査は必ず重大な見落としを生む。

### sub-agent 起動ルール

- PR が複数ある場合、**1 メッセージで複数の Agent 呼び出しをまとめて並列起動**する
- 各 sub-agent は 1 つの PR の調査に専念する
- subagent_type は `general-purpose` (または対象に応じて `Explore` 等) を使う
- 各 sub-agent には以下を必ず prompt に含める:
    - PR 番号、対象パッケージ、バージョン変更
    - このリポジトリで該当パッケージがどう使われているか (使用箇所の調査も sub-agent に委譲する)
    - 後述「調査必須項目」を全て確認させる
    - 報告フォーマット (簡潔な breaking change サマリ + リポジトリへの影響評価 + 根拠 URL/ファイル)

### 調査必須項目 (sub-agent に渡す)

1. **PR body のリリースノート抜粋を読むだけで終わらせない**。Renovate body は中間バージョンの release note を全て収録していないこともある (release page が空の場合は特に)。一次情報に当たる:
    - GitHub Releases の各タグ本文 (`gh release view <tag> -R <owner>/<repo> --json body --jq .body`)
    - CHANGELOG.md / Changelog の git tag 間 diff
    - リポジトリの compare URL での実コミット
2. **メジャーバージョンアップはもちろん、0.x 系のジャンプも breaking changes がある前提で調査する**
3. **このリポジトリのコードを実際に grep する**。breaking change があってもこのリポジトリが該当 API を使っていなければ影響なし、を**コードで確認**する
4. **patch リリースでもチェック**: 「patch だから安全」は禁句。実際に内容を見て判断する

### パッケージ種別ごとの追加注意

#### Helm chart (helmfile / helm release)

Helm chart の更新は **chart 自体の差分** と **appVersion 経由のアプリケーション本体差分** の 2 系統を分けて調査する。混同すると重大な見落としにつながる:

1. **chart 自体の差分** (`helm pull` または `git diff <tag-old>..<tag-new> -- <chart-path>/`):
    - `Chart.yaml` の version/appVersion
    - `values.yaml` の構造変更 (key 削除・rename・default 値変更)
    - `values.schema.json` の必須フィールド追加・型変更
    - `templates/` の生成 manifest 構造の変更 (kind 追加・removal、必須フィールド変更)
    - このリポジトリの values ファイルで使っている key が新 chart で**全て同じ階層に存在するか**を実際に開いて確認する
2. **appVersion 経由のアプリ本体差分**:
    - chart の appVersion (= デフォルトイメージ tag) が上がっている場合、本体アプリのリリースノートも調査
    - **ただしこのリポジトリが image を digest pin / 別 image (fork 等) で上書きしている場合、appVersion 追従は発生しないので本体差分は対象外**。values ファイルの `image.repository` / `image.tag` を必ず確認してから判定する

#### Terraform module / provider

- module の `required_providers` (provider バージョン制約) が変わっていないか確認。新制約が現在の lockfile / 他モジュールの制約と矛盾すると plan が落ちる
- module の input 変数の rename / 削除 / 型変更
- output の rename / 削除 (他リソース・他 tfstate からの参照に影響)

#### npm / yarn / pnpm パッケージ

- peer dependency の要求変更
- engines (Node.js 最低バージョン) の引き上げ
- export map の変更 (subpath import の破壊)
- ESM/CJS 切り替え

### 「影響なし」判定の根拠

「影響なさそう」「可能性が低い」と根拠なく判断するのは禁止。リリースノートやコードを実際に確認した上で判断する。報告には以下を必ず含める:

- 確認した release note / changelog の URL
- 該当 API を使っていないことを確認した grep コマンドと結果
- chart の場合: 確認した values.yaml/template の差分 URL またはコマンド

## Step 3: PR 間の依存関係分析

同一エコシステム内のパッケージ更新は、一緒に対応すべきかどうかを判断する。

グルーピングすべきケースの例:

- vite と @vitejs/plugin-react: plugin が特定の vite バージョンを前提とする
- eslint とその plugin 群: plugin が eslint の特定バージョンの API に依存する
- TypeScript と @types/\* パッケージ: 型定義が TS バージョンに依存する
- Terraform module と provider: module の `required_providers` が現状の provider 制約と矛盾する場合、provider 更新を先に入れる必要がある

判断基準:

- パッケージ間に peer dependency / required_providers の関係があるか
- 片方を先に入れると壊れる可能性があるか
- 一緒に入れないと意味がない (新機能を使うために両方必要) か

## Step 4: マージ判定とユーザー報告

各 PR について以下をテーブル形式で報告する:

| 項目                     | 内容                                                                                                                                                                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| PR 番号・タイトル        | 基本情報                                                                                                                                                                                                                                               |
| バージョン変更           | 例: 6.4.1 → 8.0.0                                                                                                                                                                                                                                      |
| CI 状態                  | Step 2 の結果。green / fail / 想定外結果あり、と原因要約                                                                                                                                                                                               |
| breaking changes         | 調査結果の要約。根拠 (リリースノート URL など) を添える                                                                                                                                                                                                |
| このリポジトリへの影響   | 影響あり/なしと理由 (grep 結果や values 比較などの根拠)                                                                                                                                                                                                |
| グルーピング             | 他の PR とまとめるべきか                                                                                                                                                                                                                               |
| 対応方針の提案           | 直接マージ / 委任 / 保留                                                                                                                                                                                                                               |
| release-please bump 判定 | release-please 利用リポジトリのみ。**actual bump level (patch / minor / major / none) と根拠** (どの `changelog-sections` エントリで visible/hidden か) をセルに明示する。「整合」「問題なし」だけの記述は禁止。後述「release-please bump の判定」参照 |

### release-please bump の判定

リポジトリが release-please を使っている場合のみ実施する。使っていなければこの項目はスキップしてよい。

#### 利用判定

以下のいずれかが存在すれば release-please 利用とみなす:

- `release-please-config.json` / `.release-please-manifest.json`
- `.github/workflows/` 配下に `googleapis/release-please-action` / `google-github-actions/release-please-action` を使う workflow

利用ありの場合は `release-please-config.json` の `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` / `changelog-sections` / `packages` (monorepo) を確認してから判定に入る。

**`changelog-sections` は判定に入る前にすべての type について visible/hidden を書き出す**。デフォルトの conventional commits 知識に頼って暗記で判定するのは禁止。リポジトリごとに `deps` を visible 化しているなど、デフォルトと挙動が変わるケースが頻出する。書き出した表だけを根拠に判定する。

#### 判定対象

PR タイトルの conventional commits (type / scope / `!`) が、更新内容に対して release-please が出す bump レベル (major/minor/patch/none) と整合しているかを判定する。Renovate のデフォルトでは依存更新は `chore(deps):` なので `none` (リリースなし) になるのが正しい場合も多い。`!` の有無だけでなく type/scope のズレも検出する。

判定の観点:

- **type が妥当か**: release-please のデフォルトでは `feat:` → minor、`fix:` → patch、`chore:` / `build:` / `ci:` / `docs:` 等 → リリースなし。**ただしリポジトリの `changelog-sections` がこのデフォルトを上書きしていることが多い** (例: `deps` を visible にして patch bump 対象にする、`docs` を visible にするなど)。**前段で書き出した visible/hidden 表だけを根拠に判定する** — 暗記で `chore` も `deps` もまとめて「リリースなし」と扱うのは典型的な誤判定。依存更新で `feat:` になっていれば過剰、本体機能追加を含む更新で `chore:` なら過小
- **`!` の有無が妥当か**: `!` 付きは major bump。Step 3 の breaking changes 調査結果と突き合わせて、実体があるか確認する
- **scope が release-please の設定と整合するか**: `changelog-sections` で hidden になっている type/scope は changelog にも bump にも反映されない。`packages` (monorepo) 設定下では scope に対応するパッケージのみが bump 対象
- **pre-1.0 挙動**: `bump-minor-pre-major: true` で `!` → minor、`feat:` → patch にダウングレードされる。`bump-patch-for-minor-pre-major: true` も併せて確認

#### 不整合時の対応提案

Renovate 側を修正するのが基本:

- type のズレ → `packageRules` の `semanticCommitType` を調整
- scope のズレ → `semanticCommitScope` を調整
- `!` を付けたい / 外したい → `commitMessagePrefix` を上書き

release-please 側の `changelog-sections` / `release-as` を直すべきケースもある。どちらに寄せるかはユーザーに判断を仰ぐ。

対応方針の判断基準:

- **直接マージ**: breaking changes がない (または影響がないことが確認済み) **かつ** CI が green で想定外の結果が含まれていない
- **委任**: breaking changes によるコード修正が必要、CI fail の原因解消が必要、または複数 PR を統合する必要がある
- **保留**: 調査で判断がつかない、またはユーザーの判断が必要

直接マージの場合も、ビルド・テストの確認は必要。影響範囲が明確で確認項目が少ない PR はこのセッション内で直接確認してマージする。わざわざ `/delegate-claude` で委任するほどではない場合が多い。

**自分でマージ判定を最終決定しない。必ずユーザーに確認する。**

## Step 5: Approve コメント

ユーザーの承認後、マージ前に各 PR に approve review コメントを付ける。

**対象が複数 PR の場合、すべての `gh pr review --approve` を 1 つの bash 呼び出し (Bash tool 1 回の実行) にまとめる。** PR ごとに Bash tool 呼び出しを分けると、実行のたびに人間の承認 (permission prompt) が必要になり、PR 数だけ承認を求めることになるため避ける。まとめて実行した場合、bash の exit code は最後のコマンドの結果しか反映しないため、各コマンドに `|| echo "FAILED: ..."` を付けて失敗を出力に明示し、実行後は出力に `FAILED:` がないか確認すること。

### コメントのルール

{{ if $public -}}

- **言語**: 英語で書く
  {{- else -}}
- **言語**: 日本語で書く (敬語不要、簡潔な口調)
  {{- end }}
- `📝` で開始する
- バージョン番号の変更 (vX → vY) は PR body から明らかなので書かない
- **本文の構造**: このバージョンの変更点を箇条書きでリストし、各変更点の直下にこのリポジトリへの影響有無をネスト箇条書きで添える。1 変更 = 1 親 bullet + 子 bullet (影響)
- **breaking changes は親 bullet の冒頭に `**[BREAKING CHANGES]**` を付ける**。レビュアーが一目で識別できるようにするため
- **upstream (依存先) リポジトリの issue/PR にリンクしない**: `owner/repo#1234` 形式や URL は GitHub 上でクロスリファレンスとして解釈され、無関係な第三者リポジトリの issue/PR タイムラインに残ってしまう。upstream の変更点は番号やリンクを付けず説明のみ書く
- 変更点が無い (または影響しうる変更がない) 場合は短く「No breaking changes.」/「破壊的変更なし。」だけで済ませる
- テンプレートリポジトリの場合、影響範囲は「このリポジトリの使い方」ではなく「下流リポジトリへの伝播」を考慮する。ただし下流の詳細な影響調査は下流側の責任なので、ここでは breaking changes の有無と概要を述べれば十分

例:

```bash
{{ if $public -}}
gh pr review <number1> --approve --body "$(cat <<'EOF'
📝

- **[BREAKING CHANGES]** Removed `-foo` option; use `-bar` instead.
    - No impact: this repo does not invoke `-foo`.
- Added `-baz` flag for offline validation.
    - No impact: not used here.
EOF
)" || echo "FAILED: gh pr review <number1>"

gh pr review <number2> --approve --body "$(cat <<'EOF'
📝

- Bumped internal build tooling.
    - No impact: build-only change; no API changes.
EOF
)" || echo "FAILED: gh pr review <number2>"
{{- else -}}
gh pr review <number1> --approve --body "$(cat <<'EOF'
📝

- **[BREAKING CHANGES]** `-foo` オプションが削除された。代わりに `-bar` を使う
    - 影響なし: このリポジトリでは `-foo` を使っていない
- オフライン検証用の `-baz` フラグが追加された
    - 影響なし: 未使用
EOF
)" || echo "FAILED: gh pr review <number1>"

gh pr review <number2> --approve --body "$(cat <<'EOF'
📝

- 内部ビルドツールをバージョンアップした
    - 影響なし: ビルドのみの変更で API は変わらない
EOF
)" || echo "FAILED: gh pr review <number2>"
{{- end }}
```

## Step 6: 対応の実行

### 直接マージの場合

マージ前に `gh pr checks --watch --fail-fast` で CI が全て通るのを待つ。CI が通っていない PR は絶対にマージしない。

```bash
gh pr checks <number> --watch --fail-fast
```

CI が通っていれば squash merge する。fohte org のリポジトリでは branch protection により `--auto` が必須なので、最初から `--auto` を付けて実行すること。`--auto` なしで `gh pr merge` を呼ぶと "the base branch policy prohibits the merge" で失敗する。

```bash
gh pr merge <number> --squash --auto
```

`--auto` を指定すると、必要な checks が満たされた瞬間に自動でマージされる。直前に `gh pr checks --watch` で待機しているので即座にマージが完了するはず。マージ後は `gh pr view <number> --json state,mergedAt` で `MERGED` を確認する。

複数 PR をマージする場合は 1 つずつ順番にマージする (前の PR のマージで conflict が発生する可能性があるため)。

マージ後、**main ブランチの CI が全て通ることを確認**してから次の PR のマージに進む。

```bash
# main の最新 Test ワークフローを取得して watch
gh run list --branch main --limit 3 --workflow Test --json databaseId,status,conclusion \
  --jq '.[] | "\(.databaseId)\t\(.status)\t\(.conclusion // "-")"'
gh run watch <run-id> --exit-status --interval 10
```

#### Renovate のリベース待ち (重要)

base ブランチが進むと、その PR が触っているファイル (例: `pnpm-lock.yaml`, `Cargo.lock`) と競合して `gh pr view --json mergeable,mergeStateStatus` が `CONFLICTING` / `DIRTY` を返すことがある。

**この時点で慌てて手動操作してはならない。** Renovate は base 更新を webhook で検知し、通常 1-2 分以内に自動的にリベースして新しい commit を push する。以下の手順で待つこと:

1. mergeable 状態を一度確認する: `gh pr view <number> --json mergeable,mergeStateStatus`
2. `CONFLICTING` / `DIRTY` だった場合は、何もせず 60-120 秒待ってからもう一度確認する
3. `MERGEABLE` / `CLEAN` になったら次の手順 (`gh pr checks --watch --fail-fast`) に進む
4. リベース後は新しい commit に対して CI が走り直すので、改めて `--watch` で完了を待つ

**禁止事項** (やりがちな雑な対応):

- `@renovatebot rebase` メンションコメントを付ける (Renovate が反応する保証がない上、自動リベースが既に進行中なら無駄)
- PR body の `<!-- rebase-check -->` チェックボックスを手動でチェックする
- `git rebase` してローカルから force push する (Renovate との関連が壊れる)
- `--admin` フラグでマージを強行する

`gh pr view` は GitHub の mergeability チェックがまだ走っていないと `UNKNOWN` を返すことがある。その場合は数秒待ってもう一度呼ぶこと。

### 委任の場合 (コード修正が必要 / 複数 PR の統合)

`/delegate-claude` スキルで委任する。Renovate のブランチ名をそのまま使う。

複数 PR を統合する場合は、メインとなる PR のブランチで作業し、他の PR の変更も取り込む。完了後、統合された PR にはコメントで「PR #X に統合した」旨を記載して close する。

### 注意事項

- **Renovate ブランチで直接作業する**: 新しいブランチを作ると Renovate PR との関連が切れる
- **CI 確認を必ず行う**: push 後に CI が通ることを確認してから merge する
- **PR 間の依存関係を考慮した順序で処理する**: 例えば、ベースライブラリを先に merge してから plugin を merge する
- **conflict を見ても手動操作しない**: 上の「Renovate のリベース待ち」セクションを参照。Renovate に任せて待つ
