#!/usr/bin/env python3
"""
Standalone tag-usage audit — NOT wired into any skill.

Scans wiki/{concepts,entities,sources,projects}/*.md for `tags:` frontmatter,
counts occurrences (exact tag and top-level namespace for hierarchical tags
like `cortex-forge/skills`), and prints a report to stdout by default.

wiki/meta/tags.md is a hand/agent-maintained lean registry (name + one-line
description, no counts — see wiki/meta/tags-convention.md) and is never
written by this script, since counts go stale the moment a new page is
ingested. Pass --write-snapshot to save a dated point-in-time report instead
of printing to stdout, for an occasional deep audit like the one that
produced wiki/meta/tags-convention-archive.md.

Usage: python3 bin/tags-audit.py <vault-path> [--write-snapshot]
"""
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path

TYPE_DIRS = ["concepts", "entities", "sources", "projects"]


def extract_tags(content: str) -> list[str]:
    fm_match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not fm_match:
        return []
    fm = fm_match.group(1)

    inline = re.search(r"^tags:\s*\[(.*?)\]", fm, re.MULTILINE)
    if inline:
        raw = inline.group(1)
        return [t.strip().strip('"').strip("'") for t in raw.split(",") if t.strip()]

    block = re.search(r"^tags:\s*\n((?:^\s*-\s*.+\n?)+)", fm, re.MULTILINE)
    if block:
        return [
            line.split("-", 1)[1].strip().strip('"').strip("'")
            for line in block.group(1).splitlines()
            if line.strip().startswith("-")
        ]

    return []


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tags-audit.py <vault-path>", file=sys.stderr)
        sys.exit(1)

    vault = Path(sys.argv[1]).resolve()
    tag_counts: Counter[str] = Counter()
    tag_pages: dict[str, list[str]] = {}

    page_counts: dict[str, int] = {}
    for type_dir in TYPE_DIRS:
        d = vault / "wiki" / type_dir
        if not d.exists():
            page_counts[type_dir] = 0
            continue
        count = 0
        for md in sorted(d.glob("*.md")):
            if md.stem == "_index":
                continue
            count += 1
            content = md.read_text(encoding="utf-8", errors="ignore")
            for tag in extract_tags(content):
                if not tag:
                    continue
                tag_counts[tag] += 1
                tag_pages.setdefault(tag, []).append(str(md.relative_to(vault)))
        page_counts[type_dir] = count

    namespace_counts: Counter[str] = Counter()
    for tag, count in tag_counts.items():
        if "/" in tag:
            namespace_counts[tag.split("/", 1)[0]] += count

    total_pages = sum(page_counts.values())
    total_uses = sum(tag_counts.values())

    freq_dist: Counter[int] = Counter()
    for count in tag_counts.values():
        freq_dist[count] += 1

    lines = [
        "# Tags audit",
        "",
        "[//]: # \"Generado por bin/tags-audit.py — standalone, no wired into any skill. Re-run manually.\"",
        "",
        "## Resumen",
        "",
        "| Métrica | Valor |",
        "|---|---|",
        f"| Páginas totales en la wiki | **{total_pages}** |",
        f"| — Conceptos | {page_counts.get('concepts', 0)} |",
        f"| — Entidades | {page_counts.get('entities', 0)} |",
        f"| — Fuentes | {page_counts.get('sources', 0)} |",
        f"| — Proyectos | {page_counts.get('projects', 0)} |",
        f"| Tags únicos | **{len(tag_counts)}** |",
        f"| Usos totales de tags | {total_uses} |",
        f"| Ratio tags/páginas | {len(tag_counts)/total_pages:.2f} |" if total_pages else "| Ratio tags/páginas | N/A |",
        "",
        "## Distribución por frecuencia de uso",
        "",
        "| Usos | Cantidad de tags | % del total |",
        "|---|---|---|",
    ]
    for c in sorted(freq_dist.keys(), reverse=True):
        pct = freq_dist[c] / len(tag_counts) * 100 if tag_counts else 0
        lines.append(f"| {c} | {freq_dist[c]} | {pct:.1f}% |")

    lines += [
        "",
        "## Por conteo (desc)",
        "",
        "| Tag | Usos | Páginas |",
        "|---|---|---|",
    ]
    for tag, count in tag_counts.most_common():
        pages_preview = ", ".join(f"`{p}`" for p in tag_pages[tag][:3])
        if len(tag_pages[tag]) > 3:
            pages_preview += f", +{len(tag_pages[tag]) - 3} más"
        lines.append(f"| `{tag}` | {count} | {pages_preview} |")

    if namespace_counts:
        lines += ["", "## Namespaces jerárquicos (`grupo/subtag`)", "", "| Namespace | Usos totales |", "|---|---|"]
        for ns, count in namespace_counts.most_common():
            lines.append(f"| `{ns}/*` | {count} |")

    report = "\n".join(lines) + "\n"

    if "--write-snapshot" in sys.argv:
        out_path = vault / "wiki" / "meta" / f"tags-audit-{date.today().isoformat()}.md"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(report, encoding="utf-8")
        print(f"Written (point-in-time snapshot, not auto-maintained): {out_path.relative_to(vault)}")
    else:
        print(report)

    print(f"{len(tag_counts)} unique tags, {sum(tag_counts.values())} total uses", file=sys.stderr)


if __name__ == "__main__":
    main()
