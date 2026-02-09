## 6. Gemini Code Assist レビューを待機

CI が成功したら、`a ai review wait` コマンドを使用して Gemini Code Assist のレビュー完了を待機します（初回レビューは PR 作成時に自動でリクエストされる）。

```bash
a ai review wait
```

レビューが完了したら、`check-pr-review` skill を使用してレビュー内容を確認し、指摘事項があれば対応してください。
