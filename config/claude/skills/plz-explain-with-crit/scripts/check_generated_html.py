#!/usr/bin/env python3
"""Run yomiyasu lint on approved text extracted from a generated HTML file."""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


PROSE_TAGS = {"p", "h1", "h2", "h3", "h4", "h5", "h6", "figcaption", "caption"}
SVG_LABEL_TAGS = {"text"}
SVG_NONDISPLAY_TAGS = {"clippath", "defs", "marker", "mask", "metadata", "pattern", "symbol"}
EXCLUDED_TAGS = {"code", "pre", "kbd", "samp", "script", "style", "template"}
VOID_TAGS = {
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
    "param", "source", "track", "wbr",
}
STRUCTURE_RULES = {"excess_bold", "excess_list"}


class TextBlock:
    def __init__(self, tag: str) -> None:
        self.tag = tag
        self._characters: dict[int, list[str]] = {}

    def add(self, value: str, line: int, *, advance_lines: bool = True) -> None:
        current_line = line
        for char in value:
            if char == "\r":
                continue
            if char == "\n":
                self._characters.setdefault(current_line, []).append(" ")
                if advance_lines:
                    current_line += 1
                continue
            self._characters.setdefault(current_line, []).append(char)

    def source_lines(self) -> list[tuple[int, str]]:
        lines = []
        for line, characters in sorted(self._characters.items()):
            text = re.sub(r"[\t\n\f\r ]+", " ", "".join(characters)).strip()
            if text:
                lines.append((line, text))
        return lines


class GeneratedHTMLParser(HTMLParser):
    def __init__(self, source: str) -> None:
        super().__init__(convert_charrefs=False)
        self.source_lines = source.split("\n")
        self.stack: list[str] = []
        self.prose_blocks: list[TextBlock] = []
        self.svg_labels: list[TextBlock] = []
        self.hidden_depths: list[int] = []
        self.prose_block: TextBlock | None = None
        self.svg_label: TextBlock | None = None

    def _inside_svg(self) -> bool:
        return "svg" in self.stack

    def _inside_excluded(self) -> bool:
        return any(tag in EXCLUDED_TAGS for tag in self.stack)

    def _inside_nondisplay_svg(self) -> bool:
        return self._inside_hidden() or any(tag in SVG_NONDISPLAY_TAGS for tag in self.stack)

    def _inside_hidden(self) -> bool:
        return bool(self.hidden_depths)

    def _source_at_position(self) -> str:
        line, column = self.getpos()
        if line < 1 or line > len(self.source_lines):
            return ""
        return self.source_lines[line - 1][column:]

    @staticmethod
    def _is_hidden(attrs: list[tuple[str, str | None]]) -> bool:
        values = {name.lower(): value or "" for name, value in attrs}
        style_hides_content = re.search(
            r"(?:^|;)\s*(?:display\s*:\s*none|visibility\s*:\s*(?:hidden|collapse))"
            r"(?:\s*!important)?\s*(?:;|$)",
            values.get("style", ""),
            re.IGNORECASE,
        )
        return (
            "hidden" in values
            or values.get("display", "").strip().lower() == "none"
            or values.get("visibility", "").strip().lower() in {"hidden", "collapse"}
            or style_hides_content is not None
        )

    def _active_block(self) -> TextBlock | None:
        if (
            self.svg_label is not None
            and not self._inside_excluded()
            and not self._inside_nondisplay_svg()
        ):
            return self.svg_label
        if (
            self.prose_block is not None
            and not self._inside_svg()
            and not self._inside_excluded()
            and not self._inside_hidden()
        ):
            return self.prose_block
        return None

    def _emit(self, value: str, line: int, *, advance_lines: bool = True) -> None:
        block = self._active_block()
        if block is not None:
            block.add(value, line, advance_lines=advance_lines)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        line, _ = self.getpos()
        was_excluded = self._inside_excluded()
        if self._is_hidden(attrs) and tag not in VOID_TAGS:
            self.hidden_depths.append(len(self.stack) + 1)
        if tag in EXCLUDED_TAGS and not was_excluded:
            active_block = self._active_block()
            if active_block is not None:
                active_block.add(" ", line, advance_lines=False)

        if (
            self._inside_svg()
            and not self._inside_nondisplay_svg()
            and tag in SVG_LABEL_TAGS
            and self.svg_label is None
            and not was_excluded
            and not self._is_hidden(attrs)
        ):
            self.svg_label = TextBlock(tag)
            self.svg_labels.append(self.svg_label)
        elif (
            not self._inside_svg()
            and not self._inside_hidden()
            and self.prose_block is None
            and tag in PROSE_TAGS
            and not was_excluded
        ):
            self.prose_block = TextBlock(tag)
            self.prose_blocks.append(self.prose_block)

        if tag == "br":
            self._emit(" ", line, advance_lines=False)

        if tag not in VOID_TAGS:
            self.stack.append(tag)

    def handle_endtag(self, tag: str) -> None:
        line, _ = self.getpos()
        if self.svg_label is not None and tag == self.svg_label.tag:
            self.svg_label = None
        if self.prose_block is not None and tag == self.prose_block.tag:
            self.prose_block = None

        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index] == tag:
                del self.stack[index:]
                break
        self.hidden_depths = [depth for depth in self.hidden_depths if depth <= len(self.stack)]

        if tag in EXCLUDED_TAGS and not self._inside_excluded():
            active_block = self._active_block()
            if active_block is not None:
                active_block.add(" ", line, advance_lines=False)

    def handle_data(self, data: str) -> None:
        line, _ = self.getpos()
        self._emit(data, line)

    def handle_entityref(self, name: str) -> None:
        line, _ = self.getpos()
        raw_reference = re.match(r"&[a-zA-Z][a-zA-Z0-9]*;?", self._source_at_position())
        value = raw_reference.group() if raw_reference else f"&{name};"
        self._emit(html.unescape(value), line, advance_lines=False)

    def handle_charref(self, name: str) -> None:
        line, _ = self.getpos()
        raw_reference = re.match(r"&#(?:[xX][0-9a-fA-F]+|[0-9]+);?", self._source_at_position())
        value = raw_reference.group() if raw_reference else f"&#{name};"
        self._emit(html.unescape(value), line, advance_lines=False)


def lint_script_default() -> Path:
    skills_dir = Path(__file__).resolve().parents[2]
    return skills_dir / "yomiyasu" / "scripts" / "yomiyasu_lint.py"


def lint_text(lint_script: Path, lines: list[tuple[str, int | None]]) -> tuple[dict[str, Any], dict[int, int]]:
    markdown_lines: list[str] = []
    line_map: dict[int, int] = {}
    for text, source_line in lines:
        markdown_lines.append(text)
        if source_line is not None:
            line_map[len(markdown_lines)] = source_line
    source = "\n".join(markdown_lines) + "\n"
    result = subprocess.run(
        [sys.executable, str(lint_script), "--json", "--strict", "-"],
        input=source,
        capture_output=True,
        check=False,
        encoding="utf-8",
    )
    if result.returncode not in (0, 1):
        detail = result.stderr.strip() or f"yomiyasu_lint.py exited with status {result.returncode}"
        raise RuntimeError(detail)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"yomiyasu_lint.py returned invalid JSON: {error}") from error
    return payload, line_map


def projected_lines(blocks: list[TextBlock]) -> list[tuple[str, int | None]]:
    projected: list[tuple[str, int | None]] = []
    for block in blocks:
        block_lines = block.source_lines()
        if not block_lines:
            continue
        if projected:
            projected.append(("", None))
        projected.extend((text, source_line) for source_line, text in block_lines)
    return projected


def text_char_count(blocks: list[TextBlock]) -> int:
    return sum(len(re.sub(r"\s+", "", text)) for block in blocks for _, text in block.source_lines())


def remap_findings(
    payload: dict[str, Any],
    line_map: dict[int, int],
    *,
    area: str,
    svg_vocabulary_only: bool = False,
) -> list[dict[str, Any]]:
    findings = []
    for finding in payload.get("findings", []):
        rule = finding.get("rule")
        if svg_vocabulary_only and rule != "slop_vocabulary":
            continue
        if not svg_vocabulary_only and rule in STRUCTURE_RULES:
            continue
        source_line = line_map.get(finding.get("line"))
        if source_line is None:
            continue
        findings.append(
            {
                "area": area,
                "line": source_line,
                "rule": rule,
                "severity": finding.get("severity"),
                "message": finding.get("message"),
                "snippet": finding.get("snippet"),
            }
        )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint visible prose in generated HTML with yomiyasu.")
    parser.add_argument("html_file", type=Path, help="Completed HTML file to inspect")
    parser.add_argument(
        "--lint-script",
        type=Path,
        default=lint_script_default(),
        help="Path to yomiyasu_lint.py; defaults to the sibling yomiyasu skill",
    )
    args = parser.parse_args()

    try:
        source = args.html_file.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        parser.error(f"cannot read HTML file: {error}")
    if not args.lint_script.is_file():
        parser.error(f"yomiyasu_lint.py not found: {args.lint_script}")

    html_parser = GeneratedHTMLParser(source)
    html_parser.feed(source)
    html_parser.close()
    prose_lines = projected_lines(html_parser.prose_blocks)
    svg_lines = projected_lines(html_parser.svg_labels)
    if not prose_lines and not svg_lines:
        parser.error("no approved prose blocks or SVG text labels were found")

    try:
        prose_payload, prose_line_map = lint_text(args.lint_script, prose_lines) if prose_lines else ({}, {})
        svg_payload, svg_line_map = lint_text(args.lint_script, svg_lines) if svg_lines else ({}, {})
    except (OSError, RuntimeError) as error:
        parser.error(str(error))

    prose_findings = remap_findings(prose_payload, prose_line_map, area="prose")
    svg_findings = remap_findings(svg_payload, svg_line_map, area="svg_label", svg_vocabulary_only=True)
    findings = sorted(prose_findings + svg_findings, key=lambda item: (item["line"], item["area"], item["rule"] or ""))
    report = {
        "source": str(args.html_file),
        "prose_block_count": sum(bool(block.source_lines()) for block in html_parser.prose_blocks),
        "prose_char_count": text_char_count(html_parser.prose_blocks),
        "svg_label_count": sum(bool(block.source_lines()) for block in html_parser.svg_labels),
        "svg_label_char_count": text_char_count(html_parser.svg_labels),
        "prose_candidate_count": len(prose_findings),
        "svg_label_vocabulary_candidate_count": len(svg_findings),
        "candidate_count": len(findings),
        "omitted_structure_checks": ["bold frequency", "list ratio"],
        "findings": findings,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if any(item["severity"] in ("warn", "error") for item in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
