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
5. **ユーザーへの報告と承認** (承認された PR への approve コメント投稿と auto-merge の armed までを含む)
6. **着地の確認** (マージの完了確認 or 委任)

`gh pr review` / `gh pr merge` / `gh pr close` を自分で叩いてはならない (runok が deny する)。GitHub への書き込みは Step 5 の `crit-triage` だけが行う。

## Step 1: PR 一覧の取得

PR の検知には author ではなく branch name を使う。author は GitHub App 版なら `renovate[bot]` だが、self-hosted 版では別の bot アカウントやユーザー自身のアカウントになり得るため決め打ちできない。branch name は `branchPrefix` config (デフォルト `renovate/`) を変えない限り一定なので、こちらを使う。

```bash
# branchPrefix は renovate.json5 等の設定ファイルで確認する (未設定ならデフォルト "renovate/")
branch_prefix=$(rg -oP 'branchPrefix"?:\s*"([^"]+)"' -r '$1' renovate.json5 renovate.json .github/renovate.json5 .github/renovate.json 2>/dev/null | head -1)
branch_prefix="${branch_prefix:-renovate/}"

gh pr list --json number,title,headRefName,url,author \
  --jq --arg p "$branch_prefix" '.[] | select(.headRefName | startswith($p)) | "\(.number)\t\(.title)\t\(.headRefName)\t\(.author.login)"'
```

0 件の場合、`branchPrefix` がカスタム設定されていて検出に失敗している可能性がある。**即座に「対応すべき PR はない」と結論せず**、renovate.json5 等の設定ファイルを直接開いて `branchPrefix` を確認してから判断する。

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

「影響なさそう」「可能性が低い」と根拠なく判断するのは禁止。
リリースノートやコードを実際に確認した上で判断する。
ただし報告には確認した release note の URL や grep コマンド・実行結果そのものは含めない (Step 5 の `changes[].impact` にはそれらの根拠ではなく、確認した具体的事実を書く)。
ファイルパス、設定キー、実際の値など、検証可能な具体性を持たせた上で結論だけ書く。
「影響なし」「問題なし」のような根拠の見えない結論のみで済ませるのは禁止。
chart の場合も同様に、確認した values.yaml/template の具体的な差分内容 (どの key がどう変わったか) を書く。

## Step 4: PR 間の依存関係分析

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

**順序依存と判定した PR は、同じラウンドの `merge` にまとめて入れない。** Step 5 で承認された `merge` PR は全て同時に auto-merge が armed され、着地順は各 PR の CI 完了順に委ねられる。先行 PR が Step 6 で `MERGED` になったのを確認してから、後続 PR を次のラウンドで triage する。

この判定結果は Step 5 で後続 PR の `gates.order` に反映する。

## Step 5: マージ判定とユーザー報告

報告は `crit-triage` で HTML にして crit で開く。**チャットにテーブルを書かない。** 項目数が多く、ターミナルのテーブルでは読めない。

`crit-triage` は報告の表示だけでなく、`verdict` が `merge` の PR をユーザーが承認した時点で、approve コメントの投稿と auto-merge の armed まで行う。ユーザーが crit 上で見た内容がそのまま実行されるよう、表示と実行は同じプロセスの同じ値から行われる。

Write ツールで JSON を書き、次を **`run_in_background: true`** で実行する (crit はユーザーが approve するまで終了しない)。起動ログに出た URL の文字列をそのままユーザーに案内する。

```bash
# <data.json> は Write ツールで書いた /tmp/renovate-triage.<採番>.json
~/.claude/skills/fohte-ops:triage-renovate-prs/scripts/crit-triage <data.json>
```

**JSON を書く前にスクリプト冒頭の docstring を読む。** スキーマと各フィールドの意味はそこにある。

PR は判定 (`verdict`) ごとにグルーピングする。ユーザーは「委任するもの一覧」「automerge に回すもの一覧」という単位で見る:

| verdict    | 意味                                            |
| ---------- | ----------------------------------------------- |
| `merge`    | 直接マージ                                      |
| `auto`     | automerge に委ねる (今回ルールを新設・拡張する) |
| `delegate` | 委任                                            |
| `hold`     | 保留                                            |

### 各 PR に書く項目

各 PR カードの一行 verdict (「そのままマージしてよい」/「今はマージできない — ...」) は手で書かない。
`gates` と `changes` から `crit-triage` が導出する。
**すべての gate が `ok` かつすべての `changes[].impact.level` が `ok` (または changes が空) のときだけ「そのままマージしてよい」になる。**
それ以外は理由付きで「今はマージできない」になる。
導出ロジックの詳細は docstring を読む。

**`merge` group に入れてよい PR は、この導出結果が「そのままマージしてよい」になる PR だけ。**
そうならない PR (コード修正が要る、CI 調査中、他 PR 待ち) を `merge` group に入れるとスクリプトが `SystemExit` で拒否する。
コード修正や CI 調査が必要な PR は `delegate` か `hold` に置く。

| label           | 内容                                                                                                                                                                                                                                                                                           |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gates.ci`      | CI の状態。fail や想定外の結果があれば `warn` + 原因                                                                                                                                                                                                                                           |
| `gates.release` | release-please 利用リポジトリのみ。判定結果を 60 文字以内で結論だけ書く (例: `"patch bump (意図通り)"` `"hidden、bump なし (意図通り)"`)。調査の深さは変えず、報告の粒度だけ圧縮する。後述「release-please bump の判定」参照                                                                   |
| `gates.order`   | 他 PR の着地待ちのときだけ設定する。`text` はこの PR のカードに出るだけでなく、verdict の「今はマージできない — 」に続く理由としてそのまま使われるので、その文脈で自然に読める文にする (例: `"#118 のマージ待ち"`。`"#118 が先"` のような言い切りは避ける)。依存関係が無ければキーごと省略する |
| `changes`       | upstream の変更点のみ。1 変更 = 1 エントリ。`impact.text` に確認済みの具体的事実を書く (詳細は Step 3 の「影響なし」判定の根拠を参照)。`impact.level` が `warn` なら `action` (具体的な修正手順) が必須。書けないなら調査が終わっていない証拠なので、曖昧な「要修正」で済ませない              |
| `scope`         | このリポジトリに明確に別コンポーネントがある場合のみ設定する (release-please の `packages`、monorepo workspace 設定、PR が触るファイルなどから判定)。1 件も設定しなければ scope 列自体が出ない。単一コンポーネントのリポジトリで無理に付けない                                                 |
| `versions`      | 短いプレーンテキスト (例: `"foo-lib 4.2.0 → 5.0.0"`)                                                                                                                                                                                                                                           |

### 投稿されるレビューコメント (`review_body`)

approve コメント本文は手動で記述しない。
**`merge` group の PR について、`changes` から `crit-triage` が自動生成する。**
JSON に `review_body` を書くとスクリプトが拒否する (`delegate` / `hold` / automerge に委ねる PR にはそもそも生成されない)。
**`gh pr review` を自分で叩かない。**

{{ if $public -}}
このリポジトリは public なので、生成されるコメントには `changes[].text_en` / `impact.text_en` が使われる。
全ての `changes` / `impact` に `text_en` を書く。
{{- else -}}
このリポジトリは非公開なので、生成されるコメントには `changes[].text` / `impact.text` が使われる。
{{- end }}

生成されるのは Markdown テーブル (「なにがおきるか」「影響」「内容」列、breaking な変更には自動で `**[BREAKING]**` が付く) で、`changes` が空なら「破壊的変更なし。」の 1 行になる。

**`changes[].text` / `impact.text` に upstream (依存先) リポジトリの issue/PR 番号 (`owner/repo#1234` 形式) や URL を書かない。**
GitHub 上でクロスリファレンスとして解釈され、無関係な第三者リポジトリの issue/PR タイムラインに残ってしまうため、生成後のコメントにそれらが残っているとスクリプトが拒否する。
upstream の変更点は番号やリンクを付けず説明のみ書く。

### 承認結果の読み方

ユーザーが各 PR / proposal を approve / deny (既定は deny) して crit を approve するとコマンドが終了し、stdout の末尾に state と実行結果が出る:

```
--- state ---
{"pr-812": "approve", "pr-813": "deny", "prop-1": "approve"}
--- done ---
ok #812 review
ok #812 merge
```

- `verdict` が `merge` の PR は、approve された時点で `crit-triage` が approve コメント投稿と auto-merge の armed まで済ませている。Step 6 で改めてマージ操作をしない
- `prop-<n>` (`proposals` の 1-based index) は `crit-triage` 自身では何もしない。`--- done ---` にも出てこない。approve された `prop-<n>` は、このセッションが state を確認したあと Claude 自身が実行する (共有 config リポジトリなら `/delegate-claude` で委任、このリポジトリの renovate.json5 ならこのセッションで直接編集)
- `FAILED #<number> <verb>: ...` が出た PR はその操作が実行されていない。原因を潰してから対応する。`review` が失敗した PR は `merge` も armed されない (approve が要るリポジトリでどのみちマージできないため)
- ユーザーが report を見終えずに crit を終えた場合は `crit ended before the review was finished` で exit 1 する。この場合は state が出ず、何も投稿されない。起動し直す
- `deny` の理由は crit のコメントに書かれている。調査して crit に返信し、crit を再開して届ける (このループの作法は `plz-explain-with-crit` skill と同じ)。同じ JSON パスで再実行すれば、前ラウンドで処理済みの PR は `skip` される
- 未操作の PR / proposal も `deny` として出る。**欠損や deny を approve と読み替えない**

### automerge 化 / Renovate 設定変更の検討

今回の判断を都度の手作業で終わらせず、同種の更新を今後 no-look で自動化できないかを評価する。automerge 化は以後の同種 PR を無条件でマージする設定なので、**可否の判断にはリスク評価を必須とする**。「過去に無事故だった」という実績だけで済ませず、何が起きればこの automerge が事故になるかを具体的に検討すること。

- **automerge 化すべきか**: 「直接マージ」と判定した PR について、その根拠が**このパッケージ/エコシステムの一般的な性質** (後方互換を厳守する運用、型定義のみの変更、lockfile 限定の変更など) によるものか、**今回たまたま影響範囲が狭かっただけ**かを区別する。前者のみ automerge 化の候補になる。同じパッケージ/packageRule で過去にも繰り返し同じ判定をしていないか `gh pr list --state merged --search "<package>"` 等で確認すると、実益の大きさを判断しやすい
- **変更先の判断**: renovate.json5 (または `.github/renovate.json5` 等) の `extends` を確認し、共有設定リポジトリ (renovate-config など) に依存しているか確認する
    - **このリポジトリ固有の事情** (独自の digest pin、特殊な使い方) による判断 → `proposals[].target.shared` を `false` にし、このリポジトリの renovate.json5 への変更として提示する
    - **他リポジトリでも共通して安全と言える性質** → `proposals[].target.shared` を `true` にし、共有設定リポジトリへの変更として提示する。全リポジトリに影響するため、この場では変更に着手しない。承認後に `/delegate-claude` で委任する (このセッション内で直接 config repo を編集しない)
- **出力先**: 検討結果は Step 5 の報告の **`proposals[]` に 1 エントリとして追加する** (PR の行には書かない)。`target.why` (なぜその変更先か) と `risks` (最低 1 件、「これが事故になるとしたら何が起きるか」) は必須。`diff` に `packageRules` (`matchPackageNames` / `matchUpdateTypes` / `automerge` など) の具体的な差分案を書く。各 proposal は PR の判定とは独立した approve/deny toggle を持つので、マージ判定と混同しない
- **今回の対象 PR への反映**: 今回提案したルールの対象に、今トリアージしている PR 自体が含まれる場合、その PR の対応方針は「automerge に委ねる」とし、このセッションで手動マージしない

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
- **automerge に委ねる**: 上の「automerge 化 / Renovate 設定変更の検討」で今回この PR を対象に automerge ルールを新設・拡張した場合。config の変更が反映され次第 Renovate 自身がマージするので、このセッションで手動マージしない

影響範囲が明確で確認項目が少ない PR は、`/delegate-claude` で委任するほどではないことが多い。`merge` に分類してレポートに載せる。

**マージ判定を自分で最終決定しない。** `merge` に分類することは提案であって決定ではなく、実際にマージが動くのはユーザーが crit 上でその PR を approve したときだけ。

## Step 6: 着地の確認

### 直接マージの場合

**マージ操作は残っていない。** Step 5 で auto-merge が armed 済みで、必要な checks が満たされた瞬間に GitHub がマージする。`gh pr merge` を自分で叩かない (runok が deny する)。

やることは着地の確認だけ:

```bash
gh pr view <number> --json state,mergedAt,mergeable,mergeStateStatus
```

- `MERGED` になっていれば完了
- `OPEN` のままなら、まだ checks 待ちか、base が進んで `CONFLICTING` / `DIRTY` になっている。**どちらも待てばよい**。Renovate は base 更新を webhook で検知して 1-2 分でリベースし、リベース後の checks が通れば armed のままの auto-merge が発火する
- `gh pr view` は GitHub の mergeability チェックがまだ走っていないと `UNKNOWN` を返すことがある。その場合は数秒待ってもう一度呼ぶ
- checks が fail していて armed のまま止まっている場合は、原因を調べてユーザーに報告する

**禁止事項** (やりがちな雑な対応):

- `@renovatebot rebase` メンションコメントを付ける (Renovate が反応する保証がない上、自動リベースが既に進行中なら無駄)
- PR body の `<!-- rebase-check -->` チェックボックスを手動でチェックする
- `git rebase` してローカルから force push する (Renovate との関連が壊れる)
- `--admin` フラグでマージを強行する

### 委任の場合 (コード修正が必要 / 複数 PR の統合)

`/delegate-claude` スキルで委任する。Renovate のブランチ名をそのまま使う。

複数 PR を統合する場合は、メインとなる PR のブランチで作業し、他の PR の変更も取り込む。統合された側の PR を閉じるのはユーザーの判断なので、**自分で close せず**、どの PR をどこに統合したかをユーザーに報告して委ねる。

### 注意事項

- **Renovate ブランチで直接作業する**: 新しいブランチを作ると Renovate PR との関連が切れる
- **CI 確認を必ず行う**: push 後に CI が通ることを確認する
- **conflict を見ても手動操作しない**: Renovate のリベースに任せて待つ
