# タイトルは客観的な変更の要約

- **簡潔に**: 50 文字以内で変更内容を要約
- **現在形の命令形**: 「Add ...」「Fix ...」「Update ...」など
- **日本語で生成**: body と同様に日本語で書く (public repo の場合、翻訳はユーザーが `steps.ready-for-translation: true` にした後に行う)
- **変更の要約を書く**: 変更内容を客観的に要約する。「〜するようにする」「〜が成功するようにする」のような未確証の結果を断定しない

- ❌ `ghcr.io への Docker イメージ push が成功するようにする` (結果を断定している)
- ❌ `minimumReleaseAge チェックをスキップする` (実装詳細すぎる)
- ✅ `build-push-action の provenance attestation を無効化する` (何をどう変えたかが客観的にわかる)
- ✅ `lockFileMaintenance の minimumReleaseAge チェックを無効化する` (設定変更の要約)
