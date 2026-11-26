# Stacked PR

GitHub native の stacked PR の仕組み。merge 順や手順を書く前に、対象の PR が stack に属するかを確かめ、属するならこのファイルの挙動を前提にする。

出典:

- [about]: https://docs.github.com/en/pull-requests/get-started/about-stacked-prs
- [ref]: https://docs.github.com/en/pull-requests/reference/stacked-pull-requests
- [merging]: https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-stacked-pull-requests
- [cli]: https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands
- [rest]: https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request-asynchronously

## stack の判定

- stack は同じ repo の 2 つ以上の PR からなる。最下段は trunk (stack の base。通常は default branch) を、上段はそれぞれ 1 つ下の PR の branch を base にする。fork をまたぐ stack は作れない ([about])
- base が別 PR の branch になっているだけの PR は stack ではない。この場合は通常の PR として merge され、上段 PR を先に merge するとその変更は trunk ではなく下段の branch に入る
- 判定は `gh api repos/<owner>/<repo>/pulls/<number> --jq .stack` で行う。`null` なら stack ではない。値があれば `number` が stack 番号、`size` が PR の数で、`position` と `size` が等しい PR が最上段

## 作成

- PR の作成は create-pr skill に従う
- 依存される側を下段に置く。ある層のコードが別の層に依存するなら、依存先は同じ branch か下の branch に入れる ([about])

## base の取り込み

- merge するには stack 全体が linear history である必要がある。下段 branch への push や trunk の前進で崩れる ([ref])
- GitHub が用意する取り込み手段は cascading rebase (merge box の **Rebase stack**、または `gh stack rebase` と `gh stack push`) だけで、merge で取り込む方法はない ([ref], [gh-stack#553](https://github.com/github/gh-stack/issues/553))
- agent は stack の PR に base を取り込まない。rebase は禁止されていて (`gh stack` の rebase / sync / modify も内部で rebase するため runok が拒否する)、merge で取り込むと stack が linear でなくなる。人に rebase を頼んで代わりにやってもらうこともしない
- 下段 PR の merge 後は、GitHub が残りの PR を自動で rebase し、次の PR の base を trunk に付け替える。手動で base を付け替える手順は要らない ([merging])

## merge のふるまい

- merge は下から上の順に進む。途中の PR を単独で merge することはできず、選んだ PR より下にある未 merge の PR がすべて一緒に merge される。最上段を merge すれば stack 全体が入る ([merging])
- まとめて merge される PR は 1 回の atomic な操作で trunk に入り、history 上は下から順に並ぶ。1 つでも merge できなければどれも merge されない ([ref], [cli])
- 選んだ PR だけでなく、その下の PR もそれぞれ trunk の branch protection (必須 review、必須 status check、CODEOWNERS など) を満たす必要がある。各 PR は直接の base ではなく trunk を base とみなして評価され、trunk 向けの `pull_request` workflow も全段で動く ([ref])
- bypass 権限で merge できるのは最下段の PR だけで、stack 全体を bypass で merge することはできない ([ref])
- merge queue を使う repo では、stack の PR は順番どおりに queue に入る。ある PR が queue から外れると、その上の PR もすべて外れる ([ref])
- merge 後の上段 PR は open のまま残り、trunk を base にして次の最下段になる。stack の全 PR が merge されると、その stack には追加できない ([merging])

## merge の手段

- CLI: `gh stack merge [<stack-number> | <pr-number>]` は指定した PR までをまとめて merge する。merge 前に確かめるのは open で draft でないことだけで、branch protection は merge 実行時に GitHub が評価する。必須 check が実行中だと即座に失敗し、何も merge されない ([cli], [gh-stack#591](https://github.com/github/gh-stack/issues/591))
- API: 非同期 merge endpoint (`PUT /repos/{owner}/{repo}/pulls/{number}/merge-async`) を使う。stacked PR では下の open PR も含めて merge される。同期 endpoint (`PUT .../pulls/{number}/merge`) は stacked PR に対応しておらず、403 を返す ([rest], [atlantis#6729](https://github.com/runatlantis/atlantis/issues/6729))
- `a gh pr-merge` は下に未 merge の PR がある stacked PR を拒否するので、最下段から 1 つずつ merge する ([armyknife](https://github.com/fohte/armyknife/blob/master/src/commands/gh/pr_merge/merge_flow.rs))
- auto-merge: GitHub は stack の PR を merge 条件が満たされた時点でまとめて自動 merge する機能を提供している ([changelog](https://github.blog/changelog/2026-10-06-stacked-pull-requests-generally-available/))。一方 `gh pr merge --auto` (GraphQL の `enablePullRequestAutoMerge`) は stacked PR では拒否され、`gh stack merge` にも auto-merge の option はない ([gh-stack#591](https://github.com/github/gh-stack/issues/591))

## repo 独自の merge 手段との衝突

ChatOps コメントや bot が同期 endpoint で PR を 1 件ずつ merge する repo では、その手段が stack では動かない。必須 status check が「PR ごとに特定の操作 (コメントなど) がされているか」を見る場合は、stack の merge にも下の全 PR がその条件を満たしている必要がある。

stack を作る前、または stack に属する PR の merge 手順を書く前に、repo の merge 手段 (CONTRIBUTING、必須 status check、merge 用の bot) を確かめる。PR 単体の merge が前提の repo では stack を使わない。
