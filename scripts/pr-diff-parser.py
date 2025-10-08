#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse Git-style diffs embedded in PR reference XML files.

The utility extracts the <full_diff> section from a PR reference XML document
and provides two primary capabilities:

* Summaries – aggregate file level metadata rendered as a table or JSON.
* Paging – return raw diff hunks by index so large diffs can be reviewed in
  chunks (e.g. --hunk-range 1-100).

Exit Codes:
    0 - Success
    1 - Validation error (missing file, malformed diff)
    2 - Unexpected runtime error
"""

from __future__ import annotations

import argparse
import json
import logging
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Optional, Tuple


@dataclass
class HunkRange:
    """Capture metadata and content for a single diff hunk."""

    old_start: int
    old_lines: int
    new_start: int
    new_lines: int
    lines: List[str]


@dataclass
class DiffEntry:
    """Represents diff metadata for a single file."""

    old_path: Optional[str]
    new_path: Optional[str]
    change_type: str
    additions: int
    deletions: int
    hunks: List[HunkRange]


def parse_arguments() -> argparse.Namespace:
    """Configure and parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description="Parse diff metadata from a PR reference XML file."
    )
    parser.add_argument(
        "reference_file",
        type=Path,
        help="Path to the PR reference XML file (e.g. pr-reference.xml).",
    )
    parser.add_argument(
        "--format",
        choices=["table", "json"],
        default="table",
        help="Render output as a table or JSON (default: table).",
    )
    parser.add_argument(
        "--filter",
        help="Only include entries whose path contains the provided substring.",
    )
    parser.add_argument(
        "--include-hunks",
        action="store_true",
        help="Include hunk ranges in table output for detailed reviews.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit the number of entries displayed in table output.",
    )
    parser.add_argument(
        "--hunk-range",
        help="Return raw diff for the inclusive hunk range (1-indexed, e.g. 1-100).",
    )
    parser.add_argument(
        "--hunk-pages-dir",
        type=Path,
        help="Write sequential hunk files to this directory (files named hunk-XXX.txt).",
    )
    parser.add_argument(
        "--hunk-page-size",
        type=int,
        help="Soft maximum number of lines per hunk file when writing to --hunk-pages-dir.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose logging for troubleshooting.",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Suppress informational logs; only errors are shown.",
    )
    return parser.parse_args()


def configure_logging(verbose: bool, quiet: bool) -> logging.Logger:
    """Configure logging verbosity based on flags."""

    if quiet:
        level = logging.ERROR
    elif verbose:
        level = logging.DEBUG
    else:
        level = logging.INFO

    logging.basicConfig(level=level, format="%(levelname)s: %(message)s")
    return logging.getLogger(__name__)


def extract_full_diff(reference_path: Path) -> str:
    """Extract the <full_diff> section from the reference XML."""

    if not reference_path.exists():
        raise FileNotFoundError(f"Reference file not found: {reference_path}")

    xml_text = reference_path.read_text(encoding="utf-8")
    match = re.search(r"<full_diff>\s*(.*?)\s*</full_diff>", xml_text, re.DOTALL)
    if not match:
        raise ValueError("The reference file does not contain a <full_diff> section.")
    return match.group(1).strip()


def split_diff_blocks(diff_text: str) -> List[str]:
    """Split combined diff text into individual file diff blocks."""

    blocks: List[str] = []
    current: List[str] = []
    for line in diff_text.splitlines():
        if line.startswith("diff --git "):
            if current:
                blocks.append("\n".join(current))
                current = []
        current.append(line)
    if current:
        blocks.append("\n".join(current))
    return blocks


def determine_change_type(lines: List[str]) -> str:
    """Infer the change type from diff metadata lines."""

    for line in lines:
        if line.startswith("new file mode"):
            return "add"
        if line.startswith("deleted file mode"):
            return "delete"
        if line.startswith("rename from"):
            return "rename"
        if line.startswith("copy from"):
            return "copy"
    return "modify"


def parse_hunks(lines: List[str]) -> List[HunkRange]:
    """Parse hunk metadata and preserve associated diff lines."""

    hunks: List[HunkRange] = []
    pattern = re.compile(r"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")
    current_meta: Optional[Tuple[int, int, int, int]] = None
    current_lines: List[str] = []

    for line in lines:
        if line.startswith("@@ "):
            if current_meta is not None:
                old_start, old_count, new_start, new_count = current_meta
                hunks.append(
                    HunkRange(
                        old_start=old_start,
                        old_lines=old_count,
                        new_start=new_start,
                        new_lines=new_count,
                        lines=current_lines,
                    )
                )
                current_lines = []
            match = pattern.match(line)
            if not match:
                current_meta = None
                continue
            current_meta = (
                int(match.group(1)),
                int(match.group(2) or "1"),
                int(match.group(3)),
                int(match.group(4) or "1"),
            )
            current_lines = [line]
        elif current_meta is not None:
            current_lines.append(line)

    if current_meta is not None:
        old_start, old_count, new_start, new_count = current_meta
        hunks.append(
            HunkRange(
                old_start=old_start,
                old_lines=old_count,
                new_start=new_start,
                new_lines=new_count,
                lines=current_lines,
            )
        )

    return hunks


def count_line_changes(lines: List[str]) -> tuple[int, int]:
    """Count added and removed lines for a diff block."""

    additions = 0
    deletions = 0
    for line in lines:
        if line.startswith("+++") or line.startswith("---"):
            continue
        if line.startswith("++") and not line.startswith("+++ "):
            additions += 1
        elif line.startswith("--") and not line.startswith("--- "):
            deletions += 1
        elif line.startswith("+") and not line.startswith("+++ "):
            additions += 1
        elif line.startswith("-") and not line.startswith("--- "):
            deletions += 1
    return additions, deletions


def parse_diff_block(block: str) -> DiffEntry:
    """Parse a single diff block into metadata."""

    lines = block.splitlines()
    header = lines[0]
    parts = header.split()
    old_path = parts[2][2:] if len(parts) > 2 else None
    new_path = parts[3][2:] if len(parts) > 3 else None

    change_type = determine_change_type(lines)

    for line in lines:
        if line.startswith("rename to "):
            new_path = line.split("rename to ", maxsplit=1)[1]
        if line.startswith("rename from "):
            old_path = line.split("rename from ", maxsplit=1)[1]

    hunks = parse_hunks(lines)
    additions, deletions = count_line_changes(lines)

    return DiffEntry(
        old_path=old_path,
        new_path=new_path,
        change_type=change_type,
        additions=additions,
        deletions=deletions,
        hunks=hunks,
    )


def parse_diff(diff_text: str) -> List[DiffEntry]:
    """Parse the entire diff text into structured entries."""

    entries: List[DiffEntry] = []
    for block in split_diff_blocks(diff_text):
        if not block.strip():
            continue
        try:
            entries.append(parse_diff_block(block))
        except Exception as exc:  # noqa: BLE001
            logging.getLogger(__name__).warning("Failed to parse diff block: %s", exc)
    return entries


def filter_entries(entries: List[DiffEntry], substring: Optional[str]) -> List[DiffEntry]:
    """Filter diff entries by substring match on paths."""

    if not substring:
        return entries
    substring = substring.lower()
    filtered: List[DiffEntry] = []
    for entry in entries:
        candidate = (entry.new_path or entry.old_path or "").lower()
        if substring in candidate:
            filtered.append(entry)
    return filtered


def render_table(entries: List[DiffEntry], include_hunks: bool, limit: Optional[int]) -> str:
    """Render diff entries as a simple table."""

    display_entries = entries[:limit] if limit and limit > 0 else entries
    if not display_entries:
        return "No diff entries found."

    header = f"{'Change':<10}{'Adds':>6}{'Dels':>6}  File"
    lines = [header, "-" * len(header)]
    for entry in display_entries:
        path = entry.new_path or entry.old_path or "(unknown)"
        lines.append(
            f"{entry.change_type:<10}{entry.additions:>6}{entry.deletions:>6}  {path}"
        )
        if include_hunks and entry.hunks:
            for hunk in entry.hunks:
                lines.append(
                    f"{'':<10}{'':>6}{'':>6}  @@ -{hunk.old_start},{hunk.old_lines} +{hunk.new_start},{hunk.new_lines}"
                )
    return "\n".join(lines)


def parse_hunk_range(value: str) -> Tuple[int, int]:
    """Parse CLI hunk range expression."""

    match = re.fullmatch(r"(\d+)-(\d+)", value.strip())
    if not match:
        raise ValueError("--hunk-range must follow START-END format.")
    start, end = int(match.group(1)), int(match.group(2))
    if start < 1 or end < start:
        raise ValueError("--hunk-range must have START >= 1 and END >= START.")
    return start, end


def flatten_hunks(entries: List[DiffEntry]) -> List[Tuple[int, DiffEntry, HunkRange]]:
    """Create a sequential list of hunks with global indexes."""

    flattened: List[Tuple[int, DiffEntry, HunkRange]] = []
    index = 1
    for entry in entries:
        for hunk in entry.hunks:
            flattened.append((index, entry, hunk))
            index += 1
    return flattened


def render_hunk_page(flattened: List[Tuple[int, DiffEntry, HunkRange]], start: int, end: int) -> str:
    """Render hunks within the inclusive range."""

    selection = [item for item in flattened if start <= item[0] <= end]
    if not selection:
        return "No hunks in requested range."

    return render_hunk_collection(selection)


def render_hunk_collection(items: List[Tuple[int, DiffEntry, HunkRange]]) -> str:
    """Render a collection of hunks to text."""

    if not items:
        return ""

    output: List[str] = []
    for index, entry, hunk in items:
        path = entry.new_path or entry.old_path or "(unknown)"
        header = f"# Hunk {index}: {entry.change_type} {path}"
        output.append(header)
        output.append("\n".join(hunk.lines))
        output.append("")
    return "\n".join(output).rstrip()


def write_hunk_pages(
    flattened: List[Tuple[int, DiffEntry, HunkRange]],
    output_dir: Path,
    max_lines: int,
) -> int:
    """Write hunks to files constrained by a soft line limit and return file count."""

    if max_lines <= 0:
        raise ValueError("--hunk-page-size must be a positive line count.")

    output_dir.mkdir(parents=True, exist_ok=True)

    page_count = 0
    current_items: List[Tuple[int, DiffEntry, HunkRange]] = []
    current_line_count = 0

    for item in flattened:
        hunk_line_count = len(render_hunk_collection([item]).splitlines())

        if not current_items:
            current_items.append(item)
            current_line_count = hunk_line_count
            continue

        candidate_lines = current_line_count + 1 + hunk_line_count

        if candidate_lines > max_lines:
            page_count += 1
            page_path = output_dir / f"hunk-{page_count:03d}.txt"
            page_content = render_hunk_collection(current_items)
            page_path.write_text(page_content + "\n", encoding="utf-8")
            current_items = [item]
            current_line_count = hunk_line_count
            continue

        current_items.append(item)
        current_line_count = candidate_lines

    if current_items:
        page_count += 1
        page_path = output_dir / f"hunk-{page_count:03d}.txt"
        page_content = render_hunk_collection(current_items)
        page_path.write_text(page_content + "\n", encoding="utf-8")

    return page_count


def main() -> int:
    """Program entry point."""

    args = parse_arguments()
    logger = configure_logging(args.verbose, args.quiet)

    try:
        diff_text = extract_full_diff(args.reference_file)
    except FileNotFoundError as exc:
        logger.error("%s", exc)
        return 1
    except ValueError as exc:
        logger.error("%s", exc)
        return 1
    except Exception as exc:  # noqa: BLE001
        logger.exception("Unexpected error while reading reference file: %s", exc)
        return 2

    entries = parse_diff(diff_text)
    entries = filter_entries(entries, args.filter)

    if not entries:
        logger.warning("No diff entries matched the provided criteria.")
        return 0

    requires_flattened = any(
        [
            args.hunk_range is not None,
            args.hunk_pages_dir is not None,
            args.hunk_page_size is not None,
        ]
    )

    flattened: Optional[List[Tuple[int, DiffEntry, HunkRange]]] = None
    if requires_flattened:
        flattened = flatten_hunks(entries)
        if not flattened:
            logger.warning("No diff hunks available after filtering.")

    if args.hunk_pages_dir is not None or args.hunk_page_size is not None:
        if args.hunk_pages_dir is None or args.hunk_page_size is None:
            logger.error("--hunk-pages-dir and --hunk-page-size must be provided together.")
            return 1
        if args.hunk_page_size <= 0:
            logger.error("--hunk-page-size must be a positive line count.")
            return 1
        if flattened:
            try:
                page_total = write_hunk_pages(flattened, args.hunk_pages_dir, args.hunk_page_size)
            except ValueError as exc:
                logger.error("%s", exc)
                return 1
            logger.info(
                "Wrote %d hunk file(s) (%d hunks total) to %s",
                page_total,
                len(flattened),
                args.hunk_pages_dir.resolve(),
            )
        else:
            logger.warning("Skipping hunk page export because no hunks were found.")

    if args.hunk_range:
        try:
            start, end = parse_hunk_range(args.hunk_range)
        except ValueError as exc:
            logger.error("%s", exc)
            return 1
        assert flattened is not None
        logger.info("Total hunks available: %d", len(flattened))
        page = render_hunk_page(flattened, start, end)
        print(page)
        return 0

    if args.format == "json":
        payload = [asdict(entry) for entry in entries]
        print(json.dumps(payload, indent=2))
    else:
        table = render_table(entries, args.include_hunks, args.limit)
        print(table)
        logger.info("Parsed %d diff entries", len(entries))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
