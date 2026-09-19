# specs リポジトリの PR 作成

SKILL.md の Step 1 の中身。このリポジトリでは Step 2-5 は存在しない。Step 1 の次は Step 6 に進む。

## 1. ドラフトを作成する

`gh pr create` で直接作成。body は雑でよい。完璧さより速度を優先。

```bash
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## Why

- ...

## What

- ...
EOF
)"
```
