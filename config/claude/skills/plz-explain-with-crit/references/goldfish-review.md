# 設計 HTML の Goldfish レビュー

設計判断を求める HTML は、crit を起動する前に Goldfish reviewer 3 体へ渡します。crit で読む設計を完成させてから見せるため、指摘の対応をすべて終えてから起動します。

## 実行

HTML の自己確認後、次の入力を用意してください。

- 設計 HTML
- ユーザーの依頼の原文
- 後続の指示の原文。指示がなければ空のファイル
- 対象 repo のルートパス。設計 HTML の GitHub permalink は URL として開かず、この checkout 内の対応するファイルを読むよう reviewer に指示します。

設計 HTML の SVG 図には `<desc>` を付け、図の意味をテキストで説明します。

依頼と後続の指示は別ファイルにし、要約や注記を加えず原文のまま渡します。runner は `self-review` の設定を読み、既定の engine、model、reasoning effort を使います。

```bash
<skill-dir>/scripts/review-design /path/to/design.html /path/to/request.txt /path/to/follow-ups.txt /path/to/repository
```

3 体は独立した読み取り専用プロセスとして並列に動きます。Claude の file tools は対象 repo、設計 HTML の複製、取り込んだ定義に制限されます。Codex は read-only sandbox を使いますが、読み取り先は列挙できません。

終了コードが 0 以外でも、出力された reviewer の報告は使えます。失敗した reviewer だけを検証欄に「未実施」と記載します。

## 指摘への対処

- 3 体で重なる指摘は 1 件にまとめます。削れと足せが衝突したら、根本の問題に必要かという zoom-out の観点で決めます。
- 妥当な指摘は HTML を直します。推奨案や前提が変わる場合は HTML を直し、「判断してほしいこと」に推奨とともに記載します。
- Blocker と Major は直すか、reviewer が読めるファイルの根拠を示して退けます。重要度は下げません。「意図どおり」は根拠になりません。
- 誤りや Nit は作業用の一時ファイルに記録し、crit には出しません。Nit も直す価値があれば直します。
- comprehension の指摘は退けません。想定読者が知っている文脈を reviewer のためだけに足さず、まず図や既存の文を直します。
- reviewer の出力自体は crit に載せません。指摘を直すか退け、未実施の reviewer があれば HTML の検証欄に「未実施」と記載してから crit を起動します。

## 再実行

Goldfish は最初の実行と、最初の指摘を反映した後の再実行を合わせて 2 回までです。2 回目の指摘もすべて片付けますが、3 回目は実行しません。指摘を 0 件にすることを再実行の条件にはしません。

crit のコメントを受けて設計 HTML を直した場合も、ユーザーが明示的に頼んだときだけ Goldfish を再実行します。
