# Claude Code 固有

- search: コードの構造 (定義の場所、呼び出し元/呼び出し先、影響範囲) を知りたいときは先に codebase-memory MCP (`search_graph` / `trace_path` / `get_code_snippet`) を使う
- `rtk`: a PreToolUse hook auto-rewrites commands to `rtk <cmd>` to save tokens. Use `rtk proxy <cmd>` only when truncation hurts.
