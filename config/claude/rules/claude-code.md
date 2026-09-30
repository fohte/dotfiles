# Claude Code 固有

- search: コードの構造 (定義の場所、呼び出し元/呼び出し先、影響範囲) を知りたいときは先に codebase-memory MCP (`search_graph` / `trace_path` / `get_code_snippet`) を使う
- background Bash: `crit` など人の操作を待つ常駐プロセスを `run_in_background: true` で起動するときは `timeout: 2147483647` を指定する (省略すると 30 分で停止される)
- `rtk`: a PreToolUse hook auto-rewrites commands to `rtk <cmd>` to save tokens. Use `rtk proxy <cmd>` only when truncation hurts.
