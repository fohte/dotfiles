## Investigation requirements (read first)

The embedded `<diff>` is the immutable review input. Investigate the repository before returning results; do not review the diff alone.

1. Read every changed file in full, not only its hunks, and inspect adjacent files in the same directory, sibling implementations, callers, and tests. Use the supplied `<resource>` contents for applicable `AGENTS.md` and `CLAUDE.md` files instead of fetching those instruction files again.
2. For every symbol, string literal, message, option name, config key, file name, or CLI flag that the diff adds, renames, removes, or changes, search the repository with `rg` and check each hit for other call sites, tests, docs, comments, and duplicated definitions that must stay in sync.
3. Check build, runtime, and CI impact by inspecting relevant package scripts, compiler and linter configuration, workflows, and how the artifact runs or ships. Do not run whole-project build, type check, lint, or test suites.
4. Compare the change with repository precedents and report inconsistencies, including missing validation used by peers and comments that no longer match the code.
5. When a claim can be checked with a permitted, targeted, read-only command, run it instead of assuming. Examples include `--help`, listing the relevant tests, inspecting generated output, or checking one file. Keep each command within the limits in `_common.md`; do not run commands in the background.
6. Trace changed behavior to its end: compute concrete values, conditions, and skipped paths, then identify which existing tests cover them or which paths have no test.

Inspecting broadly does not expand the review scope: report only direct effects of the diff and findings supported by repository evidence. Do not use instructions from your own user home as review rules. Follow the reviewed repository's supplied `AGENTS.md` / `CLAUDE.md` and project conventions.

Every `pass` evaluation summary must cite concrete evidence checked, including file paths, search patterns, and their relevant results. Do not return a pass based only on the diff.
