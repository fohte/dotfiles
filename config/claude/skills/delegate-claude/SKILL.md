---
name: delegate-claude
description: Delegate tasks to a separate Claude Code instance in its own git worktree. Use this skill when the user says "delegate", "/delegate-claude", asks to run a task in parallel in another worktree, wants to spawn a child Claude session, or needs to offload implementation work to an independent Claude Code instance. Also trigger when the user wants to start work on a different repository without leaving the current session, or when breaking down a large task into parallel sub-tasks each handled by separate Claude instances. Also use when a session needs to contact the session that delegated to it, or one it delegated to.
---

# 別の Claude Code インスタンスにタスクを委任する

`a cc new --worktree --prompt` を使って、別の worktree で別の Claude Code インスタンスに処理を委任する。

## 最優先ルール

- **ユーザーが明示的に delegate を指示した場合は、必ず delegate する**: タスクの規模・複雑さ・難易度に関わらず、ユーザーが `/delegate-claude` や「delegate して」と指示した場合は、自分の判断で「delegate 不要」と判断してはならない。ユーザーには delegate する意図がある。理由を推測せず、指示に従うこと
- **delegate 不要と判断して自分で作業を始めることは禁止**: このスキルが発動した時点で、タスクの実行方法は delegate に確定している。「これは簡単だから自分でやろう」「PR 不要だから delegate しなくてよい」といった判断は一切してはならない
- **委任できるのは実装作業だけ**: 何を作るか / 何をどう直すかが確定したタスクのみを委任する。設計が未決のタスク、原因が未特定のバグ、方針を決めるための調査を丸投げしてはならない。確定させるのは委任元の責任 (後述の「委任前に確定させること」)。設計や原因が未確定であることは委任を取りやめる理由にはならない。確定作業を先に済ませてから委任すること
- **1 委任 = 1 PR の原則**: 1 回の `a cc new` で委任するタスクは 1 PR 分の作業に限定すること。「複数フェーズを一括で」「複数 PR を順次作成」のような複数 PR をまとめた委任は禁止。委任先は単一の Claude Code プロセスで作業するため、複数 PR を順に作る前提では設計しない。委任先がさらに `/delegate-claude` で再委任することも想定しない。大きな計画やフェーズ分割されたタスクの場合は、委任元 (現在のセッション) が split-into-prs skill で 1 PR 単位に分割し、最初の 1 PR だけを委任する。後続の PR は前の PR が merge / 確認された後に、改めて委任元から別途委任する

## 絶対禁止事項

- **ユーザーが指定したリポジトリを勝手に変更しない**: ユーザーが委任先リポジトリを明示した場合、自分の判断で別のリポジトリに変更してはならない。ユーザーはどのリポジトリで修正すべきかを把握している。「こっちのリポジトリの方が適切では」と思っても、ユーザーの指定に従うこと
- **自分で実装作業をしない**: このスキルが発動したら、ファイル編集・コード変更を自分で行ってはならない。仕事は委任内容を確定させることと、プロンプトを構成して `a cc new` コマンドを実行すること。読み取りのみの調査 (設計・原因の確定) はこの禁止に含まれない
- **委任前にファイルを編集しない**: 「先に少し直してから委任しよう」は禁止。未コミットの変更がある状態で worktree を作ると、委任先にその変更が反映されない
- **SendMessage を進捗確認や催促に使わない**: 委任先は別プロセスだが同じマシン上の Claude Code セッションなので、ListAgents に現れ SendMessage も届く。届くからといって、状況を尋ねる、急かす、作業中に細かく口を出すといった用途に使ってはならない。委任先は対話しながら進める相手ではない。送ってよいのは次の 2 つだけで、いずれも手順は後述の「委任元から委任先に連絡する場合」に従う

    - 委任元が渡した前提が誤っていた場合の訂正
    - 委任先が委任元の管理下にあるもの (別リポジトリの修正、パッケージの publish、先行 PR の merge など) を待って止まっている場合の、解消した旨の通知

- **用が無いのに停止中のセッションを起こさない**: `a cc peer wake` は、送る用件が既に確定していて、連絡先のセッションが停止している場合にだけ使う。状況を見るため、念のため、といった理由で起こしてはならない。`a cc sweep` はアイドルなセッションを意図的に停止しており、それを覆すことになる
- **委任後に完了をポーリングしない**: `a cc new` に完了通知の仕組みはないが、それを自作のポーリングで代替してはならない。委任が始まったことをユーザーに報告したら完了とする。委任は委任元セッションを解放するための手段であり、張り付いて見守る対象ではない。ユーザーに訊かれて `ListAgents` で状態を答えるのは構わないが、訊かれてもいないのに状態を確認して報告するのは、それ自体がポーリングにあたる

## 委任前に確定させること

委任先は独立プロセスで、判断に迷っても委任元と対話しながら詰められない。設計や原因の特定を委任すると、委任元が知らない前提のまま実装が進み、方針からやり直しになる。委任は決まったことを並列で進める手段であり、考える作業自体を外に出す手段ではない。

以下は委任元 (現在のセッション) が先に済ませる:

- **設計判断**: どの仕組みで実現するか。未決なら design skill で案を出し、ユーザーが選んだ案を確定案とする (design skill は決定を下さず選択を求めて終わる)
- **バグの原因**: どこが原因でどう直すか。未特定なら debug-flow skill で root cause を特定する。特定できた時点で委任に戻り、修正フェーズには進ませない (debug-flow は原因特定後に自動で修正へ移行し、main で直接作業するリポジトリでは委任せず実装してしまう)
- **方針を決めるための調査**: 選択肢の比較や実現可能性の確認。research skill で調べる

確定した内容は根拠付きで `investigated` に、達成状態は `goal` に書く。

委任先が実装中に細部を調べるのは当然で、禁止しているのは「何をするかを決める調査」を委任することだけ。

## 使い方

```bash
dir=$(mktemp -d /tmp/delegate.XXXXXX)
# Write ツールで $dir/task.yaml を作成 (スキーマは後述の「プロンプト構造 (必須)」参照)
prompt=$("$HOME/.claude/skills/delegate-claude/scripts/render-task" "$dir/task.yaml")
DELEGATE_TASK_PURPOSE="$(yq -r .purpose "$dir/task.yaml")" \
  DELEGATE_TQ_TASK_ID="<この委任作業が属する tq タスクの ID。無ければ変数ごと省略>" \
  a cc new --worktree=<branch-name> --agent --label "<title>" --prompt "$prompt"
```

- `branch-name`: 新しい環境用に作成するブランチ名
- `--agent`: **必須**. 委任元 Claude Code セッションからの呼び出しであることを示す。プロンプトを `<delegated-task>` XML でラップし、ブランチ名・base ブランチ・ディレクトリ情報を自動注入する
- `--label`: **必須**. セッションのタイトル。`cc watch` の TUI でセッション一覧に表示され、コンテキストスイッチ時に「このセッションで何をやっていたか」を素早く思い出すためのもの。以下のルールで生成すること:
    - 日本語 2-5 語
    - 具体的な識別子 (PR 番号、ファイル名、機能名、エラー名など) を必ず含める
    - 末尾に句読点を付けない
    - 良い例: "PR #40 CI 修正", "セッション一覧 TUI 実装", "Renovate 設定デバッグ", "ラベル生成プロンプト改善"
    - 悪い例: "バグ修正", "機能実装" (何の? がわからない)
- `task.yaml`: Write ツールで `$dir` 配下に書く構造化データ。委任先へのプロンプトの元データであり、スキーマは後述の「プロンプト構造 (必須)」を参照。**必ず `mktemp -d` で作った一意なディレクトリ配下に置く** (固定パスは並行セッションと衝突する)
- `render-task`: `task.yaml` を `--prompt` 用の markdown に変換するスクリプト。`purpose`/`goal` が空だとエラーで停止する
- `--prompt`: `render-task` の出力をそのまま渡す
- `DELEGATE_TASK_PURPOSE`: `task.yaml` の `purpose` をそのまま渡す環境変数。委任先 worktree の post-worktree-create hook がこれを読み `branch.<name>.x-purpose` に書き込み、`create-pr` skill が PR の Why セクション生成時に参照する
- `DELEGATE_TQ_TASK_ID`: この委任作業が属する tq タスクの ID を渡す環境変数。同じ hook が `branch.<name>.x-tq-task-id` に書き込み、委任先の `track-in-tq` skill がタスク作成時の `--parent-id` に使う。渡さないと委任先は委任元のセッションにリンクされたタスク一覧から親を推測する羽目になり、一覧が複数件のときに親無しのタスクができる。**委任元が tq タスクを持っているなら必ず渡す**

### オプション

- `--from <ref>`: ベースとなる ref を指定 (デフォルト: main ブランチ)
    - 例: `a cc new --worktree=feature-x --agent --label "..." --from origin/develop --prompt "..."`
    - Renovate の PR をテストする場合: `a cc new --worktree=test-upgrade --agent --label "..." --from origin/renovate/some-branch --prompt "..."`
- `-R <path>` / `--repo <path>`: 対象リポジトリのパスを指定。指定するとカレントディレクトリに関係なく、そのリポジトリ上で worktree を作成する
    - 例: `a cc new --worktree=fix-api-timeout -R ~/ghq/github.com/fohte/other-repo --agent --label "..." --prompt "..."`
- `--skip-hooks`: post-worktree-create hook をスキップする。hook 自体が壊れていて worktree 内で直す必要がある場合に使う

#### post-worktree-create hook 失敗時のリトライ

`a cc new` が `Error: hook '...post-worktree-create' exited with status 1` で失敗した場合、worktree とブランチは自動でロールバックされる (新規作成ブランチは削除、既存ブランチを `--force` で上書きしたケースは元の tip に復元)。hook 内のツール (例: チェックアウトしたブランチの設定ファイルがパースエラーで処理できない) が失敗原因で、委任タスク自体とは無関係なことが多い。

リトライは同じコマンドに `--skip-hooks` を付けて再実行するだけでよい。委任先で conflict 解決などにより設定ファイルが正常化すれば、hook が参照するツールも再び使えるようになる。プロンプトにはこの背景 (`--skip-hooks` で作成したこと、設定ファイルが一時的に壊れている理由) を一言添えておくとよい。

worktree 削除自体が失敗した警告が出た場合のみ手動復旧が必要で、`a wm delete <name>` で残骸を削除してからリトライする。

### 複数タスクの一括委任

複数のタスクをまとめて委任する場合、Bash ツールを委任数だけ呼び分けず、**1 回の bash 呼び出し内で `for` ループを使う**こと。委任先ごとに Bash ツール呼び出しを分けるとツール許可プロンプトが委任数だけ発生し、途中 1 件の拒否で以降が止まる。1 つの bash にまとめれば許可は 1 回で済む。for ループは dispatch の手段であり、各イテレーションは依然として独立した 1 委任 = 1 PR なので「1 委任 = 1 PR の原則」とは衝突しない。

各委任先で task.yaml の内容が異なる場合は、共通する field (`investigated`/`links`/`additionalContext` など) を `common.yaml` に、差分のある field (`purpose`/`goal` など) を per-task の `<repo>.yaml` に分けて Write し、`yq` でマージしてから `render-task` に渡す。task.yaml を Bash 引数に直接埋め込まず、必ず Write ツールでファイルに書いてから渡すこと。

**task.yaml は必ず `mktemp -d` で作った一意なディレクトリ配下に置く。** `/tmp/delegate-1.yaml` のような固定名は、過去セッションや並行セッションと衝突して別タスクの内容を上書き / 読み込みする事故につながる。事前に 1 回だけ `dir=$(mktemp -d /tmp/delegate.XXXXXX)` を実行し、以降の Write・マージ結果はすべてその `$dir` 配下のパスを使う。

```bash
# 事前準備: 一意な作業ディレクトリを作り、その下に common.yaml と <repo>.yaml を Write する
#   dir=$(mktemp -d /tmp/delegate.XXXXXX); echo "$dir"
#   → 例: /tmp/delegate.AbC123
#   その後 Write tool で $dir/common.yaml (共通 field), $dir/repo-a.yaml (差分 field) ... を作成

dir=/tmp/delegate.AbC123  # 上で作成したパスをそのまま使う
for entry in "repo-a 123" "repo-b 456" "repo-c 789"; do
  read repo num <<< "$entry"
  task="$dir/$repo.task.yaml"
  yq eval-all '. as $item ireduce ({}; . * $item)' "$dir/common.yaml" "$dir/$repo.yaml" > "$task"
  prompt=$("$HOME/.claude/skills/delegate-claude/scripts/render-task" "$task")
  DELEGATE_TASK_PURPOSE="$(yq -r .purpose "$task")" \
    a cc new --worktree=<branch> -R ~/ghq/github.com/<org>/$repo \
      --agent --label "<title> $repo#$num" --prompt "$prompt" \
      && echo "OK $repo#$num" || echo "FAIL $repo#$num" &
done
wait
```

末尾の `&` + `wait` で worktree 作成と Claude Code 起動を並列化する (委任数が多いほど効果が大きい)。`wait` の終了コードは最後に待ったジョブのものしか反映しないため、失敗特定のために各イテレーションで `OK`/`FAIL` のマーカーを必ず出力し、終了後に `grep FAIL` で再実行対象を抽出する。

### 例

```bash
# 現在のリポジトリ
dir=$(mktemp -d /tmp/delegate.XXXXXX)
# Write ツールで $dir/task.yaml を作成 (purpose: メール認証ログインが必要な理由, goal: ログイン機能が動くこと, など)
prompt=$("$HOME/.claude/skills/delegate-claude/scripts/render-task" "$dir/task.yaml")
DELEGATE_TASK_PURPOSE="$(yq -r .purpose "$dir/task.yaml")" \
  a cc new --worktree=feature-login --agent --label "メール認証ログイン実装" --prompt "$prompt"

# 別のリポジトリ (-R オプション)
dir=$(mktemp -d /tmp/delegate.XXXXXX)
# Write ツールで $dir/task.yaml を作成 (purpose: API タイムアウトで困っている内容, goal: タイムアウト設定の期待値, など)
prompt=$("$HOME/.claude/skills/delegate-claude/scripts/render-task" "$dir/task.yaml")
DELEGATE_TASK_PURPOSE="$(yq -r .purpose "$dir/task.yaml")" \
  a cc new --worktree=fix-api-timeout -R ~/ghq/github.com/fohte/other-repo --agent --label "API タイムアウト修正" --prompt "$prompt"
```

実行すると:

1. 指定したブランチで新しい git worktree を作成
2. Neovim と Claude Code を含む新しい tmux ウィンドウを開く
3. Claude Code にプロンプトを自動送信

## 委任時の注意事項

- **既存ブランチで作業する場合**: 既存のリモートブランチ (例: follow-up PR のブランチ) にそのまま commit したい場合は、ブランチ名をそのまま `<branch-name>` に指定する
    - 例: `a cc new --worktree=follow-up-123-terraform/foo --agent --label "..." --prompt "..."`
- **ブランチ名**: 新規ブランチを作る場合、ブランチ名に `/` を含めないこと。代わりにハイフンを使う (例: `fix/login-bug` ではなく `fix-login-bug`)。ブランチには `fohte/` がプレフィックスとして付くため、`fix/...` だと `fohte/fix/...` になり冗長
- 新しいインスタンスは独立した worktree で作業するため、現在の作業と競合しない

### `--from` の判断ルール (重要)

**`--from` はデフォルトで使わない。** 以下の判断フローに従うこと:

1. 委任するタスクは、現在のブランチの変更がないと作業できないか?
    - **いいえ** → `--from` を指定しない (main ブランチベース)
    - **はい** → `--from <現在のブランチ>` を指定する

**`--from` を使ってよいケース** (現在のブランチの変更が前提として必要):

- 現在の PR に対する follow-up 修正
- 現在のブランチで追加したファイル/設定を前提とする追加作業

**`--from` を使ってはいけないケース** (独立した変更):

- CI の汎用的な修正 (trivy の無効化、linter 設定の変更など)
- 別の機能の追加・修正
- リポジトリ全体に影響する設定変更
- main にも存在するファイル (ドキュメント、設定ファイルなど) の修正で、修正内容が現在のブランチの新規コードに依存しない場合
- 自動生成された PR (依存関係更新など) で問題が発見されたが、修正内容自体が main 上でも適用できる場合

**よくある誤判断**:

- 「現在のブランチで同じファイルを編集した」という理由だけで `--from` が必要だと判断してはいけない。判断基準は「そのファイルを編集したかどうか」ではなく、「委任先が main ブランチ上で同じ修正を適用できるかどうか」。main にあるファイルに対する独立した修正であれば、たとえ現在のブランチでも同じファイルを触っていても `--from` は不要
- 「ある PR で問題が見つかった」という理由だけで `--from` にその PR のブランチを指定してはいけない。PR は問題の発見契機にすぎない。修正がその PR の変更内容に依存しない限り main ベースで行う
- **merge 済みの PR/ブランチに対して `--from` を指定してはいけない**。merge 済みということは変更が既に main に取り込まれているため、main ベースで作業すればその変更は含まれている。merge 済みかどうかが不明な場合は、`gh pr view` や `git log` で確認してから判断すること
- **commit 先 (branch-name) と base ref (`--from`) を混同しない**。既存ブランチに直接 commit したいだけなら `a cc new --worktree=<既存ブランチ名>` で足りる。`--from origin/<同名ブランチ>` の指定は冗長で判断ミスのシグナル

間違えて `--from` で現在のブランチを指定すると、関係のない変更が混入して別々の PR にできなくなる。

## プロンプト構造 (必須)

委任先の Claude Code インスタンスは**現在の会話の事前知識を持っていない**。十分なコンテキストを持たせるため、`--prompt` に渡す markdown を直接書くのではなく、構造化した `task.yaml` を書く。`render-task` がこれを決定的に markdown へ変換する。

**最重要: `purpose`/`investigated`/`links` に最も力を入れて書く。** この 3 field が委任先にとっての「背景」を構成する。委任先が自律的に適切な判断を下せるかどうかは、ここの質で決まる。

| field               | 必須 | `--prompt` への反映                     | git config への反映                           |
| ------------------- | ---- | --------------------------------------- | --------------------------------------------- |
| `purpose`           | 必須 | 背景 > 目的・モチベーション             | あり (`branch.<name>.x-purpose` の値そのもの) |
| `investigated`      | 任意 | 背景 > 調査済みの内容                   | なし                                          |
| `links`             | 任意 | 背景 > 参考リンク (URL ごとに 1 bullet) | なし                                          |
| `goal`              | 必須 | ゴール                                  | なし                                          |
| `additionalContext` | 任意 | 現状                                    | なし                                          |

```yaml
purpose: | # 必須。1-2 行: 動機・why
    レポート共有を毎回手作業でやっていて数が増えると回らない。
    1 コマンドで共有 URL まで出したい。

investigated: | # 任意: すでに調査済み・判明している内容
    `report export` はローカルパスしか返さない (src/export.rs:88)。
    アップロード API は既にある。

links: # 任意: 関連する issue/PR/doc の URL 一覧
    - https://github.com/example/reporter/issues/210

goal: | # 必須: 完了状態の定義
    `report export --share` で共有 URL が標準出力に出る。

additionalContext: | # 任意: 上記に当てはまらない文脈の catch-all
    hook が壊れているので --skip-hooks で worktree を作った。
```

### 書き方のルール

- **`purpose`/`investigated`/`links` を最も厚く書く**: task.yaml の中でこの 3 field に最も分量を割く。委任先が「なぜこの作業をするのか」を深く理解できるようにする
- **`goal` はゴールだけ伝え、手順は指示しない**: 「何を達成してほしいか」を書き、「どうやるか」は委任先に任せる。具体的な実装ステップや中間手順を書かない
- **`goal` に調査・設計を含めない**: 「原因を調査して直す」「方法を検討して実装する」は委任できる状態に達していないサイン (前述の「委任前に確定させること」)
- **成果物の中身まで指示しない**: 特に commit message や PR description に何を書くかを `goal` に書かないこと。委任先は `/commit` や `/create-pr` skill に従って書き方を判断する。「PR description に〇〇を書くこと」「△△を注記すること」と書くと、委任先は skill のルールより委任元の指示を優先してしまい、skill で禁止されている内容 (検討経緯、動作確認手順など) が PR description に混入する。伝えるべきはタスクの `goal` だけであり、「ゴールに付随する情報をどう記録するか」は委任先の skill に任せる
- **commit/PR 作成の完了条件は task.yaml に書かない**: 「`/commit` skill で commit し、`/create-pr` skill で PR を作成するところまで完了させること。」は `render-task` が markdown の末尾に常に付与する固定文であり、task.yaml 側に書く・省略する・変更するという判断は発生しない。「commit 不要」「PR 不要」のような独自判断を `goal` に書き加えることも禁止
- **根拠を含める**: `investigated` に書く調査結果や判断には、その根拠 (ログ、コード箇所、エラーメッセージ、ドキュメント URL など) を添える
- **伝聞を検証済みの事実として書かない**: `investigated` に書いてよいのは自分で確かめた事実に限る。コード中のコメント、Issue や PR の本文、過去の調査メモなど既存の記述を根拠に使う場合は、裏を取ってから書くか、取れていないなら「〜と書かれているが未検証」と出所と検証状況を明示する。委任先はそこに書かれたことを前提として実装し、誤った前提はコード中のコメントや PR description として成果物に定着してしまう。既存の記述が誤診であることは珍しくなく、特に「直せない」「〜が原因」と断定している記述ほど検証する価値が高い
- **`links` に URL を貼る**: Issue / PR / ドキュメントなど、参考にしたものは URL を `links` に列挙する。特に親 Issue や関連 PR は必須
- **パスは実在を確認する**: task.yaml にファイルパスやディレクトリパスを含める場合、そのパスが委任先から実際にアクセスできることを事前に確認する。特に worktree 内で作業している場合、本体リポジトリのパスと worktree のパスは異なるため注意する。テンプレートやスキルの指示にあるパスをそのまま使わず、実際の cwd やファイルの所在を確認すること

### 良い例

```yaml
# $dir/task.yaml (Write ツールで作成)
purpose: |
    セッションタイムアウトが短すぎてユーザーが頻繁に再ログインを強いられている。
    本来 30 分のはずが 5 分で切れる。ログイン後 5 分待つと 401 が返る。
investigated: |
    src/auth/session.ts の SessionManager クラスで TTL を設定しているが、
    config/auth.json の timeout 値 (1800秒) が反映されていない。
    Redis の TTL を確認したところ実際に 300 秒で設定されている
    (根拠: redis-cli TTL session:xxx の結果)。
    最近の JWT からセッション認証への移行 (PR #142) でデフォルト値のフォールバックが
    追加され、config の値を上書きしている可能性が高い。
links:
    - https://github.com/example/repo/issues/210
    - https://github.com/example/repo/pull/142
goal: |
    セッションタイムアウトが config/auth.json の設定値 (30 分) どおりに動作する。
additionalContext: |
    認証は src/auth/session.ts の SessionManager クラスで処理。
    セッション設定は config/auth.json に定義。Redis をセッションストレージとして使用。
```

```bash
dir=$(mktemp -d /tmp/delegate.XXXXXX)
# 上記の内容で $dir/task.yaml を Write
prompt=$("$HOME/.claude/skills/delegate-claude/scripts/render-task" "$dir/task.yaml")
DELEGATE_TASK_PURPOSE="$(yq -r .purpose "$dir/task.yaml")" \
  a cc new --worktree=fix-auth-timeout --agent --label "セッション TTL 設定反映修正" --prompt "$prompt"
```

### 悪い例

```yaml
# NG: コンテキスト不足 - purpose が漠然としていて、新しいインスタンスには「そのバグ」が何か分からない
purpose: |
    さっき話したバグを直して
goal: |
    バグが直っている
```

```yaml
# NG: 原因未特定のまま調査を丸投げしている - 委任元が root cause を特定してから委任する
purpose: |
    セッションが 5 分で切れてしまう
goal: |
    原因を調査して修正されている
```

```yaml
# NG: 設計が未決のまま委任している - どの方式にするかを決めるのは委任元の仕事
purpose: |
    セッション管理が古い実装のままで保守しづらい
goal: |
    最適なセッション管理方式を検討して移行されている
```

```yaml
# NG: goal に手順を指示しすぎ - 委任先の自律性を奪う
purpose: |
    セッションが 5 分で切れてしまう
goal: |
    1. src/auth/session.ts を開く
    2. 42 行目の TTL を 300 から 1800 に変更する
    3. テストを追加する
    4. commit はしないこと
```

## 委任元から委任先に連絡する場合

1. `a cc peer children` で対象セッションを特定する。`label` と `cwd` でどの委任か判別し、`name` をそのまま `SendMessage` の `to` に渡す
2. `name` が `null` なら `a cc peer wake <session_id>` を実行し、出力される名前を `to` に使う。停止していれば再開し、停止していなければ現在の名前を返す
3. `SendMessage` で送る
4. 対象が `a cc peer children` に無い、または `wake` が名前を返さない場合にだけ、委任先が失われたとみなす。PR が作成済みならその PR にコメントを残し、まだ無ければユーザーに報告する

`ListAgents` の一覧から探してはならない。停止中のセッションは `ListAgents` に現れないため、生きている委任先を終了したと誤認して、同じタスクを新規に委任し直すことになる。

### メッセージに含める内容

- **委任元からの連絡であること**: 委任先は無関係な第三者からの割り込みと区別できないため、最初に明示する
- **委任先が次に何をすればよいか**: 作業を再開してよいのか、やり直すのか、何も変わらないのかを明言する。これがないと委任先は手を動かしてよいか判断できない

訂正の場合はこれに加えて、プロンプトのどの記述が誤りかを引用して特定し、正しい事実の根拠 (ファイルパス、行番号、出典) を添える。委任先が自分で再検証できる状態にすること。訂正のついでにスコープが膨らむのを防ぐため、範囲外のままにするものも書く。

解消の通知の場合はこれに加えて、委任先が何を待っていて、それがどう解消したのかを特定する。

## 委任先から委任元に連絡する場合

委任先が委任元に訂正や確認を返すときは、`a cc peer parent | jq -r '.[0].name // empty'` で委任元の名前を取り、`SendMessage` の `to` に渡す。

`ListAgents` の一覧から探してはならない。そこに出る名前は cwd 由来の slug + 乱数サフィックスなので、委任元がリポジトリのルートで動いていると同じ prefix の行が並び、どれが委任元か判別できない。

出力が空なら `a cc peer parent | jq -r '.[0].session_id // empty'` を見る。値が返れば委任元は停止しているだけなので、`a cc peer wake <その値>` で再開すると、出力される名前がそのまま `to` に使える。これも空なら委任元自体が記録されていないので、wake は試さない。

それでも名前が取れない場合は、候補を当てにいかずユーザーに報告する。

## 委任後に前提の誤りが判明した場合

委任元が渡した前提そのものが誤っていたと判明したら、気付いた側が訂正を送る責任を持つ。放置すると委任先は誤った前提のまま実装し、その前提がコード中のコメントや PR description に書き込まれて成果物として残る。委任元の誤りを委任先に押し付ける形になる。
