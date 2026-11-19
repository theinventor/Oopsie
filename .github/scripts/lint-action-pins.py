#!/usr/bin/env python3
"""Fail if a workflow or composite action uses a mutable remote action ref.

Remote `uses:` values must be a full 40-character commit SHA. Local `./`
actions are allowed. `docker://` refs must be pinned to an immutable
sha256 digest. Comments such as `# v4.2.2` are ignored.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHORT_SHA = re.compile(r"^[0-9a-f]{4,39}$")
DOCKER_DIGEST = re.compile(r"^docker://\S+@sha256:[0-9a-f]{64}$")
USES_KEY = re.compile(r"^([ \t]*)(?:-\s+)?uses:\s*(.*?)\s*$")
BLOCK_SCALAR = re.compile(r":\s*[|>][+-]?\s*(?:#.*)?$")
BLOCK_INDICATORS = {"|", ">", "|-", "|+", ">-", ">+"}
SKIP_DIRS = {".git", "node_modules", "vendor", "tmp", "log", "storage", "coverage"}


def extract_scalar(raw: str) -> str | None:
    """Return a same-line scalar, or None when the value continues below."""
    raw = raw.strip()
    if raw in BLOCK_INDICATORS or raw == "":
        return None
    if raw[0] in "\"'":
        quote = raw[0]
        end = raw.find(quote, 1)
        if end == -1:
            return raw.strip(quote).strip()
        return raw[1:end].strip()
    hash_at = raw.find("#")
    if hash_at != -1:
        raw = raw[:hash_at]
    return raw.strip()


def indent_of(line: str) -> int:
    return len(line) - len(line.lstrip(" \t"))


def check_uses(value: str) -> str | None:
    """Return an error message, or None when the ref is acceptable."""
    if value.startswith("./"):
        return None
    if value.startswith("docker://"):
        if DOCKER_DIGEST.fullmatch(value):
            return None
        return (
            f"docker:// ref '{value}' must use an immutable sha256 digest "
            "(docker://image@sha256:<64 hex chars>)"
        )
    if "@" not in value:
        return f"remote action '{value}' has no ref; pin to a full 40-character commit SHA"
    action, ref = value.rsplit("@", 1)
    if "/" not in action:
        return f"unrecognized uses value '{value}'"
    if SHA40.fullmatch(ref):
        return None
    if re.fullmatch(r"[0-9a-fA-F]{40}", ref):
        return (
            f"commit SHA in '{value}' must be 40 lowercase hex characters"
        )
    if SHORT_SHA.fullmatch(ref) or re.fullmatch(r"[0-9a-fA-F]{4,39}", ref):
        return (
            f"short SHA '{ref}' in '{value}' is not a full commit; "
            "pin to a 40-character SHA"
        )
    return (
        f"mutable remote ref '{value}' (branch or tag); "
        "pin to a full 40-character commit SHA"
    )


def iter_target_files(root: Path) -> list[Path]:
    files: set[Path] = set()
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(name for name in dirnames if name not in SKIP_DIRS)
        for filename in sorted(filenames):
            path = Path(dirpath) / filename
            relative = path.relative_to(root)
            if filename in {"action.yml", "action.yaml"}:
                files.add(path)
            elif (
                relative.parts[:2] == (".github", "workflows")
                and path.suffix in {".yml", ".yaml"}
            ):
                files.add(path)
    return sorted(files)


def lint_file(path: Path, root: Path) -> list[str]:
    findings: list[str] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeError as exc:
        return [f"{path.relative_to(root)}: cannot read file as UTF-8 ({exc})"]

    block_key_indent: int | None = None
    pending: tuple[int, int, bool] | None = None
    display = path.relative_to(root)

    def record(lineno: int, value: str) -> None:
        problem = check_uses(value)
        if problem:
            findings.append(f"{display}:{lineno}: {problem}")

    for lineno, line in enumerate(lines, 1):
        if pending is not None:
            if line.strip() == "" or line.strip().startswith("#"):
                continue
            pending_line, pending_indent, as_block = pending
            if indent_of(line) <= pending_indent:
                findings.append(
                    f"{display}:{pending_line}: uses: is missing a ref on the same or next line"
                )
                pending = None
            else:
                value = extract_scalar(line.strip())
                pending = None
                if as_block:
                    block_key_indent = pending_indent
                if value is None:
                    findings.append(
                        f"{display}:{lineno}: uses: value is empty or continues unexpectedly"
                    )
                else:
                    record(pending_line, value)
                if as_block:
                    continue

        if block_key_indent is not None:
            if line.strip() == "":
                continue
            if indent_of(line) > block_key_indent:
                continue
            block_key_indent = None

        match = USES_KEY.match(line)
        if match:
            key_indent = len(match.group(1))
            value = extract_scalar(match.group(2))
            if value is None:
                indicator = match.group(2).strip()
                pending = (lineno, key_indent, indicator in BLOCK_INDICATORS)
                continue
            record(lineno, value)
            continue

        if BLOCK_SCALAR.search(line):
            block_key_indent = indent_of(line)

    if pending is not None:
        findings.append(
            f"{display}:{pending[0]}: uses: is missing a ref on the same or next line"
        )
    return findings


def main(argv: list[str]) -> int:
    root = Path(argv[1]).resolve() if len(argv) > 1 else Path(__file__).resolve().parents[2]
    if not root.is_dir():
        print(f"action pin lint: {root} is not a directory", file=sys.stderr)
        return 2
    findings: list[str] = []
    for path in iter_target_files(root):
        findings.extend(lint_file(path, root))
    if findings:
        print("action pin lint failed:")
        for finding in findings:
            print(f"  {finding}")
        return 1
    print("action pin lint: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
