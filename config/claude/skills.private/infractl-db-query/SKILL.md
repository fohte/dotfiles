---
name: infractl-db-query
description: Use this skill when the user wants to inspect or query data in a Postgres database via the `infractl db` CLI — e.g. "look up user X in the tq database", "check what's in the mastodon DB", "run a SQL query against a database". Also trigger on any mention of `infractl`.
---

# infractl db query

Postgres データベースに対して読み取り専用でクエリを実行する CLI。

## 使い方

1. target 一覧を確認: `infractl db targets`
2. クエリ実行: `infractl db query -t <target> "<SQL>"`
    - `-t` は必ず指定する (このリポジトリでは省略時のデフォルト target が定義されていないため、省略すると失敗する)
    - `--json` で構造化出力に切り替えられる

target は増減しうるので、事前に一覧を覚えるのではなく毎回 `infractl db targets` で確認する。

## 安全性

`db query` は読み取り専用が保証されているため、SQL をそのまま渡してよい。
