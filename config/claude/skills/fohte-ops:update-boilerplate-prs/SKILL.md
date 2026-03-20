---
name: fohte-ops:update-boilerplate-prs
description: fohte org 下の generic-boilerplate 更新 PR (Renovate copier) を一括処理する。boilerplate 更新、copier 更新 PR のマージ、generic-boilerplate の伝搬確認などに使用する。
---

# generic-boilerplate 更新 PR の一括処理

Renovate が作成する generic-boilerplate 更新 PR を検証し、マージ可能なものはマージ、コンフリクトがあるものは `/delegate-claude` で解消する。

## 全体フロー

1. **変更内容の把握**: generic-boilerplate 自体の変更を理解する
2. **PR 一覧の取得**: fohte org 下の open な更新 PR を収集する
3. **各 PR の検証**: 差分・CI・伝搬状況を確認する
4. **マージ判定**: ユーザーに判定結果を報告し、承認を得る
5. **コンフリクト解消**: 必要な PR は `/delegate-claude` で解消する
6. **CI 確認後マージ**: CI pass を確認してからマージする

## Step 1: generic-boilerplate の変更内容を把握する

各 PR の更新元バージョンと更新先バージョンを特定し、テンプレートとしての変更差分を理解する。

```bash
# リポジトリを最新化
ghq get -u fohte/generic-boilerplate

# 変更差分を確認 (バージョンは PR から読み取る)
cd ~/ghq/github.com/fohte/generic-boilerplate
git log v<from>..v<to> --oneline
git diff v<from>..v<to> --stat
git diff v<from>..v<to>
```

把握すべきポイント:

- `.mise.toml` のツールバージョン変更
- `package.json` の依存関係変更 (Breaking Change に注意)
- CI ワークフローの変更 (action バージョン、ワークフロー構成の変更)
- 新規ファイルの追加 (`scripts/bootstrap` など)
- **テンプレートとして配布されるファイルと、generic-boilerplate リポジトリ自身のファイルを区別する** (例: `.gitattributes` はリポジトリ自身の設定であり、copier で配布されない)

## Step 2: PR 一覧の取得

```bash
gh search prs --owner=fohte --state=open "generic-boilerplate" \
  --json repository,title,number,url
```

## Step 3: 各 PR の検証

各 PR について以下を並列で確認する (サブエージェントを活用する):

### 3a. 差分の確認

```bash
gh pr diff <number> -R fohte/<repo>
```

- copier コンフリクトマーカー (`<<<<<<< before updating`, `=======`, `>>>>>>> after updating`) の有無
- Step 1 で把握した変更が正しく伝搬されているか
    - 各リポジトリのテンプレート構成 (copier-answers.yml の設定) によって適用される変更は異なる。構成に応じて「含まれるべき変更」と「対象外の変更」を判断する
    - テンプレート由来でない変更 (リポジトリ固有のカスタマイズ) が壊れていないか

### 3b. CI 状態の確認

```bash
gh pr view <number> -R fohte/<repo> \
  --json mergeable,mergeStateStatus,statusCheckRollup
```

CI が失敗している場合はログを確認して原因を特定する。

## Step 4: マージ判定とユーザー報告

各 PR について以下の基準で判定する:

- **マージ可**: コンフリクトマーカーなし + CI pass + 変更が正しく伝搬されている
- **マージ不可**: コンフリクトマーカーあり、または変更の伝搬に問題がある

判定結果をテーブル形式でユーザーに報告し、マージの承認を得る。**自分でマージ判定を最終決定しない。必ずユーザーに確認する。**

## Step 5: コンフリクト解消

コンフリクトがある PR は `/delegate-claude` スキルで解消を委任する。

委任時のプロンプトには以下を含める:

- generic-boilerplate の変更内容 (Step 1 の結果)
- コンフリクトマーカーがあるファイルとその内容
- リポジトリ固有のカスタマイズで維持すべきもの (例: リポジトリ固有の依存、ローカル設定)
- 解消方針の判断材料 (例: lefthook-config が自分自身をリモート参照するのは不適切)

委任先のゴール:

- コンフリクトマーカーの解消
- 構文チェック (JSON なら `jq .`、TOML/YAML なら適切なツール)
- commit & push (PR 作成は不要、既存 PR のブランチに push する)
- push 後、CI の完了を待ち、全 check が pass したことを確認する
- CI が失敗した場合は原因を調査し、修正して再 push する
- 最終的に CI pass した状態でユーザーに報告する (マージはしない)
