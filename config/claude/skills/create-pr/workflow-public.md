### ドラフト承認後の翻訳（`steps.ready-for-translation: true` かつ日本語含む）

**重要:** public repo では翻訳は**必須**である。`steps.ready-for-translation` は「翻訳するかしないか」の選択ではなく、「ドラフトの内容が承認され、翻訳の準備ができたか」を示すフラグ。

ユーザーがドラフトの内容を承認し、`steps.ready-for-translation: true` に変更した場合:

1. title と body を英語に翻訳する
2. `steps.submit: false` に変更する（翻訳によりハッシュが無効になるため）
3. ファイルを上書き保存する
4. 再度 `a ai pr-draft review` を実行して、ユーザーに翻訳内容を確認してもらう
5. ユーザーがレビューを完了して明示的に指示するまで待機する

翻訳時の注意事項は ~/.claude/skills/create-pr/public-repo-guide.md の「翻訳時の注意」セクションに従うこと。

**注意:** すでに英語に翻訳済み（日本語が含まれていない）の場合は、再翻訳しない。
