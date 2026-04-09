---
name: fohte-ops:triage-renovate-prs
description: Renovate が作成した依存関係更新 PR を一括トリアージ・マージする。Renovate PR の処理、依存関係の更新 PR のマージ、dependency update のトリアージなどに使用する。「Renovate PR を片付けたい」「依存関係の更新をまとめて処理したい」といったリクエストで発動する。
---

# Renovate PR のトリアージ

Renovate が作成した依存関係更新 PR を、影響範囲を調査した上でトリアージし、マージまたは委任する。

no-look merge は避け、各 PR の breaking changes と影響範囲を把握してから判断する。

## 全体フロー

1. **PR 一覧の取得と概要把握**
2. **各 PR の breaking changes 調査** (最重要)
3. **PR 間の依存関係分析とグルーピング**
4. **ユーザーへの報告と承認**
5. **Approve コメント**
6. **対応の実行** (直接マージ or 委任)

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

## Step 2: Breaking changes の調査

**このステップを省略・軽視しない。** メジャーバージョンアップはもちろん、0.x 系のジャンプ (0.32→0.38 など) も breaking changes がある前提で調査する。

調査方法:

- PR の body に Renovate が含めたリリースノートを確認する
- 必要に応じて公式ドキュメントやリリースページを Web 検索する
- このリポジトリのコードを grep して、breaking changes に該当する API を使っているか確認する

確認すべきポイント:

- API の変更 (関数シグネチャ、設定形式、CLI オプションなど)
- 削除された機能
- デフォルト値の変更
- 最低要求バージョンの変更 (Node.js、Rust edition など)
- peer dependency の要求変更
- **このリポジトリのコードが影響を受けるかどうか** (breaking change があってもこのリポジトリが該当 API を使っていなければ影響なし)

「影響なさそう」「可能性が低い」と根拠なく判断するのは禁止。リリースノートやコードを実際に確認した上で判断すること。

## Step 3: PR 間の依存関係分析

同一エコシステム内のパッケージ更新は、一緒に対応すべきかどうかを判断する。

グルーピングすべきケースの例:

- vite と @vitejs/plugin-react: plugin が特定の vite バージョンを前提とする
- eslint とその plugin 群: plugin が eslint の特定バージョンの API に依存する
- TypeScript と @types/\* パッケージ: 型定義が TS バージョンに依存する

判断基準:

- パッケージ間に peer dependency の関係があるか
- 片方を先に入れると壊れる可能性があるか
- 一緒に入れないと意味がない (新機能を使うために両方必要) か

## Step 4: マージ判定とユーザー報告

各 PR について以下をテーブル形式で報告する:

| 項目                   | 内容                                                     |
| ---------------------- | -------------------------------------------------------- |
| PR 番号・タイトル      | 基本情報                                                 |
| バージョン変更         | 例: 6.4.1 → 8.0.0                                        |
| breaking changes       | 調査結果の要約。根拠 (リリースノート URL など) を添える  |
| このリポジトリへの影響 | 影響あり/なしと理由                                      |
| グルーピング           | 他の PR とまとめるべきか                                 |
| 対応方針の提案         | 直接マージ / 委任 / 保留                                 |
| major bump 判定        | PR タイトルの `!` による release-please の bump は妥当か |

### major bump の判定

PR タイトルに `!` (例: `deps(ci)!:`) が含まれていると release-please が breaking change として扱い、バージョン bump が発生する。各 PR について「この更新でこのリポジトリの major/minor bump は妥当か」を判定する。

不要と判断した場合は Renovate の設定修正を提案する (commitMessagePrefix の変更など)。

対応方針の判断基準:

- **直接マージ**: breaking changes がない、またはあってもこのリポジトリに影響がないことが確認済み
- **委任**: breaking changes によるコード修正が必要、または複数 PR を統合する必要がある
- **保留**: 調査で判断がつかない、またはユーザーの判断が必要

直接マージの場合も、ビルド・テストの確認は必要。影響範囲が明確で確認項目が少ない PR はこのセッション内で直接確認してマージする。わざわざ `/delegate-claude` で委任するほどではない場合が多い。

**自分でマージ判定を最終決定しない。必ずユーザーに確認する。**

## Step 5: Approve コメント

ユーザーの承認後、マージ前に各 PR に approve review コメントを付ける。

### コメントのルール

- 英語で書く
- `📝` で開始する
- バージョン番号の変更 (vX → vY) は PR body から明らかなので書かない
- 影響しうる変更のみ簡潔に述べる。影響する変更がなければ「No breaking changes.」等で短く済ませる
- テンプレートリポジトリの場合、影響範囲は「このリポジトリの使い方」ではなく「下流リポジトリへの伝播」を考慮する。ただし下流の詳細な影響調査は下流側の責任なので、ここでは breaking changes の有無と概要を述べれば十分

```bash
gh pr review <number> --approve --body "$(cat <<'EOF'
📝 No breaking changes. ...
EOF
)"
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
