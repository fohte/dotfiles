---
name: codebase-memory
description: Use the codebase knowledge graph for structural code queries. Triggers on: explore the codebase, understand the architecture, what functions exist, show me the structure, who calls this function, what does X call, trace the call chain, find callers of, show dependencies, impact analysis, dead code, unused functions, high fan-out, refactor candidates, code quality audit, graph query syntax, Cypher query examples, edge types, how to use search_graph.
---

# Codebase Memory — Knowledge Graph Tools

Graph tools return precise structural results in ~500 tokens vs ~80K for grep.

## Quick Decision Matrix

| Question                | Tool call                                               |
| ----------------------- | ------------------------------------------------------- |
| Who calls X?            | `trace_path(direction="inbound")`                       |
| What does X call?       | `trace_path(direction="outbound")`                      |
| Full call context       | `trace_path(direction="both")`                          |
| Find by name pattern    | `search_graph(name_pattern="...")`                      |
| Dead code               | `search_graph(max_degree=0, exclude_entry_points=true)` |
| Cross-service edges     | `query_graph` with Cypher                               |
| Impact of local changes | `detect_changes()`                                      |
| Risk-classified trace   | `trace_path(risk_labels=true)`                          |
| Text search             | `search_code` or Grep                                   |

Every tool except `list_projects` requires a `project` argument — get the name
from `list_projects`.

## Exploration Workflow

1. `list_projects` — check if project is indexed
2. `get_graph_schema` — understand node/edge types
3. `search_graph(label="Function", name_pattern=".*Pattern.*")` — find code
4. `get_code_snippet(qualified_name="project.path.FuncName")` — read source

## Tracing Workflow

1. `search_graph(name_pattern=".*FuncName.*")` — discover exact name
2. `trace_path(function_name="FuncName", direction="both", depth=3)` — trace
3. `detect_changes()` — map git diff to affected symbols

## Quality Analysis

- Dead code: `search_graph(max_degree=0, exclude_entry_points=true)`
- High fan-out: `search_graph(min_degree=10, relationship="CALLS", direction="outbound")`
- High fan-in: `search_graph(min_degree=10, relationship="CALLS", direction="inbound")`

## 15 MCP Tools

`index_repository`, `index_status`, `check_index_coverage`, `list_projects`,
`delete_project`, `search_graph`, `search_code`, `trace_path`,
`detect_changes`, `query_graph`, `get_graph_schema`, `get_code_snippet`,
`get_architecture`, `manage_adr`, `ingest_traces`

## Edge Types

Node labels and edge types vary by language and release — read them from
`get_graph_schema(project)` rather than assuming a fixed set. `CALLS` means an
invocation only; a callable passed as a value is `CALL_REFERENCE`.

## Cypher Examples (for query_graph)

```
MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20
MATCH (f:Function) WHERE f.name =~ '.*Handler.*' RETURN f.name, f.file_path
MATCH (a)-[r:CALLS]->(b) WHERE a.name = 'main' RETURN b.name
```

## Gotchas

1. `search_graph(relationship="HTTP_CALLS")` filters nodes by degree — use `query_graph` with Cypher to see actual edges.
2. `query_graph` has no offset — use `search_graph` for paginated browsing.
3. `trace_path` needs exact names — use `search_graph(name_pattern=...)` first.
4. `direction="outbound"` misses cross-service callers — use `direction="both"`.
5. Results default to 10 per page — check `has_more` and use `offset`.
