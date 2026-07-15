#!/usr/bin/env python3
"""
antu-index: Incremental wiki indexer with semantic embeddings.
Usage: python {vault}/.cortex/db/antu-index.py [vault_path]
"""
import hashlib
import json
import os
import re
import sqlite3
import sys
from pathlib import Path


def _resolve_embeddings_dir() -> Path:
    """Find the directory containing embeddings.py — always a sibling of this
    script (co-located with the skill, or copied alongside it into a vault's
    .cortex/db/ or ~/.cortex-forge/bin/ — either way, always a sibling)."""
    here = Path(__file__).parent
    if (here / "embeddings.py").exists():
        return here
    print("ERROR: Cannot locate embeddings.py (expected as a sibling of this script).", file=sys.stderr)
    sys.exit(1)


sys.path.insert(0, str(_resolve_embeddings_dir()))
import embeddings as emb

CHUNK_WORD_LIMIT = 500
CHUNK_OVERLAP_WORDS = 100


def get_vault(argv: list[str]) -> Path:
    if len(argv) > 1:
        return Path(argv[1]).resolve()
    # CWD heuristic: walk up looking for wiki/
    p = Path.cwd()
    for candidate in [p, *p.parents]:
        if (candidate / "wiki").is_dir():
            return candidate
    print("ERROR: Could not locate vault. Pass vault path as argument.", file=sys.stderr)
    sys.exit(1)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def split_words(text: str) -> list[str]:
    return text.split()


def chunk_by_headings(content: str) -> list[tuple[str | None, str]]:
    """Returns list of (heading, text) tuples. First chunk heading may be None (intro)."""
    heading_re = re.compile(r'^#{1,6}\s+(.+)$', re.MULTILINE)
    matches = list(heading_re.finditer(content))

    if not matches:
        return [(None, content.strip())]

    chunks: list[tuple[str | None, str]] = []

    intro = content[:matches[0].start()].strip()
    if intro:
        chunks.append((None, intro))

    for i, m in enumerate(matches):
        heading = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        body = content[start:end].strip()
        if body or heading:
            chunks.append((heading, body))

    return chunks


def sub_chunk(heading: str | None, text: str) -> list[tuple[str | None, str]]:
    """Split oversized chunks using sliding window over words."""
    words = split_words(text)
    if len(words) <= CHUNK_WORD_LIMIT:
        return [(heading, text)]

    result = []
    start = 0
    while start < len(words):
        window = words[start:start + CHUNK_WORD_LIMIT]
        result.append((heading, " ".join(window)))
        start += CHUNK_WORD_LIMIT - CHUNK_OVERLAP_WORDS

    return result


def get_chunks(content: str) -> list[tuple[int, str | None, str]]:
    """Returns (chunk_index, heading, text) for all chunks of a file."""
    raw = chunk_by_headings(content)
    final: list[tuple[str | None, str]] = []
    for heading, text in raw:
        final.extend(sub_chunk(heading, text))

    return [(i, h, t) for i, (h, t) in enumerate(final)]


def init_db(db_path: Path) -> sqlite3.Connection:
    sqlite_vec_path = None
    search_paths = [
        Path.home() / ".local/lib",
        Path("/usr/local/lib"),
        Path("/opt/homebrew/lib"),
    ]
    for sp in search_paths:
        candidates = list(sp.glob("**/vec0*")) + list(sp.glob("**/sqlite_vec*"))
        if candidates:
            sqlite_vec_path = str(candidates[0])
            break

    conn = sqlite3.connect(str(db_path))
    conn.enable_load_extension(True)
    loaded = False
    if sqlite_vec_path:
        try:
            conn.load_extension(sqlite_vec_path)
            loaded = True
        except sqlite3.OperationalError:
            pass
    if not loaded:
        try:
            import sqlite_vec
            sqlite_vec.load(conn)
        except ImportError:
            print("ERROR: sqlite-vec not found. Install with: pip install sqlite-vec", file=sys.stderr)
            sys.exit(1)
    conn.enable_load_extension(False)

    conn.executescript(f"""
        CREATE TABLE IF NOT EXISTS documents (
            rowid INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            heading TEXT,
            chunk_index INTEGER NOT NULL,
            content TEXT NOT NULL,
            file_hash TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS vec_documents USING vec0(
            rowid INTEGER PRIMARY KEY,
            embedding float[{emb.DIMENSIONS}] distance_metric=cosine
        );
        CREATE INDEX IF NOT EXISTS idx_documents_path
            ON documents(path);
        CREATE INDEX IF NOT EXISTS idx_documents_path_chunk
            ON documents(path, chunk_index);
    """)
    conn.commit()
    return conn


def get_indexed_hashes(conn: sqlite3.Connection) -> dict[str, str]:
    rows = conn.execute("SELECT DISTINCT path, file_hash FROM documents").fetchall()
    return {r[0]: r[1] for r in rows}


def get_indexed_paths(conn: sqlite3.Connection) -> set[str]:
    rows = conn.execute("SELECT DISTINCT path FROM documents").fetchall()
    return {r[0] for r in rows}


def delete_file(conn: sqlite3.Connection, rel_path: str) -> None:
    conn.execute("""
        DELETE FROM vec_documents WHERE rowid IN (
            SELECT rowid FROM documents WHERE path = ?
        )
    """, (rel_path,))
    conn.execute("DELETE FROM documents WHERE path = ?", (rel_path,))


def index_file(conn: sqlite3.Connection, vault: Path, md_path: Path) -> None:
    rel_path = str(md_path.relative_to(vault))
    content = md_path.read_text(encoding="utf-8")
    chunks = get_chunks(content)
    file_hash = sha256(md_path)
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()

    with conn:
        delete_file(conn, rel_path)
        for chunk_index, heading, text in chunks:
            if not text.strip():
                continue
            vec = emb.embed_document(text)
            cur = conn.execute(
                "INSERT INTO documents (path, heading, chunk_index, content, file_hash, updated_at) VALUES (?,?,?,?,?,?)",
                (rel_path, heading, chunk_index, text, file_hash, now)
            )
            rowid = cur.lastrowid
            conn.execute(
                "INSERT INTO vec_documents (rowid, embedding) VALUES (?, ?)",
                (rowid, emb.vec_to_bytes(vec))
            )


def calibrate(conn: sqlite3.Connection, vault: Path, config_path: Path) -> None:
    """
    Sample intra-file pairs (similar) and inter-file pairs (dissimilar).
    Re-embeds text directly to avoid sqlite-vec blob format issues.
    Sets threshold at p75 of dissimilar distances, saves to .cortex/db/config.json.
    """
    import random

    rows = conn.execute("""
        SELECT path, content FROM documents ORDER BY RANDOM() LIMIT 100
    """).fetchall()

    if len(rows) < 10:
        return

    def cosine_dist(a: list[float], b: list[float]) -> float:
        dot = sum(x * y for x, y in zip(a, b))
        na = sum(x * x for x in a) ** 0.5
        nb = sum(x * x for x in b) ** 0.5
        if na == 0 or nb == 0:
            return 1.0
        return 1.0 - dot / (na * nb)

    by_path: dict[str, list[str]] = {}
    for path, content in rows:
        by_path.setdefault(path, []).append(content)

    # Embed a representative sample (cap at 40 chunks to avoid slow runs)
    sampled: list[tuple[str, list[float]]] = []
    for path, chunks in list(by_path.items())[:40]:
        chunk = chunks[0][:300]
        vec = emb.embed_document(chunk)
        sampled.append((path, vec))

    intra_dists: list[float] = []
    inter_dists: list[float] = []

    for i in range(len(sampled)):
        for j in range(i + 1, len(sampled)):
            d = cosine_dist(sampled[i][1], sampled[j][1])
            if sampled[i][0] == sampled[j][0]:
                intra_dists.append(d)
            else:
                inter_dists.append(d)

    if not inter_dists:
        return

    inter_dists.sort()
    p75_idx = int(len(inter_dists) * 0.75)
    threshold = round(inter_dists[p75_idx], 4)

    config = {}
    if config_path.exists():
        config = json.loads(config_path.read_text())

    config["distance_threshold"] = threshold
    config["calibration_sample"] = {
        "chunks_embedded": len(sampled),
        "intra_pairs": len(intra_dists),
        "inter_pairs": len(inter_dists),
        "inter_p25": round(inter_dists[int(len(inter_dists) * 0.25)], 4),
        "inter_p50": round(inter_dists[len(inter_dists) // 2], 4),
        "inter_p75": threshold,
    }
    config_path.write_text(json.dumps(config, indent=2))
    print(f"  calibrated threshold: {threshold} (inter-file p75, n={len(inter_dists)} pairs)")


def main():
    vault = get_vault(sys.argv)
    wiki_dir = vault / "wiki"
    cortex_dir = vault / ".cortex" / "db"
    cortex_dir.mkdir(parents=True, exist_ok=True)
    db_path = cortex_dir / "vault.db"
    config_path = cortex_dir / "config.json"

    emb.load_embedding_model()
    conn = init_db(db_path)

    indexed_hashes = get_indexed_hashes(conn)
    indexed_paths = get_indexed_paths(conn)

    md_files = list(wiki_dir.rglob("*.md"))
    current_paths = {str(f.relative_to(vault)) for f in md_files}

    deleted = indexed_paths - current_paths
    if deleted:
        print(f"Removing {len(deleted)} deleted file(s)...")
        with conn:
            for p in deleted:
                delete_file(conn, p)

    updated = skipped = failed = 0
    failed_files: list[str] = []
    for md_path in md_files:
        rel = str(md_path.relative_to(vault))
        current_hash = sha256(md_path)
        if indexed_hashes.get(rel) == current_hash:
            skipped += 1
            continue
        print(f"  indexing {rel}")
        try:
            index_file(conn, vault, md_path)
            updated += 1
        except emb.EmbeddingBackendError as e:
            print(f"  FAILED: {rel} — {e}", file=sys.stderr)
            failed += 1
            failed_files.append(rel)

    print(f"Done: {updated} indexed, {skipped} skipped, {len(deleted)} removed.")
    if failed:
        print(
            f"FAILED: {failed} file(s) could not be embedded — already-indexed files are "
            f"unaffected; re-run this command to retry only the failures: {', '.join(failed_files)}"
        )

    if updated > 0 or len(deleted) > 0:
        print("Calibrating distance threshold...")
        try:
            calibrate(conn, vault, config_path)
        except emb.EmbeddingBackendError as e:
            print(f"  Calibration skipped — {e}", file=sys.stderr)

    conn.close()

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
