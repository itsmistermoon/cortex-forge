#!/usr/bin/env python3
"""
cortex-search: Semantic search over the vault index.
Usage: python {vault}/.cortex/db/cortex-search.py "query" [--top-k N] [--vault PATH]
Installed to {vault}/.cortex/db/ by cortex-forge-setup. Source lives in bin/.
"""
import argparse
import json
import sqlite3
import sys
from pathlib import Path


def _resolve_forge_bin() -> Path:
    """Find cortex-forge bin/ containing embeddings.py.

    Search order:
    1. bin/ sibling of this script (canonical: script lives in <forge>/bin/)
    2. forge path registered in ~/.cortex-forge/config.yml under 'cortex-forge:' or 'forge:'
    """
    here = Path(__file__).parent
    if (here / "embeddings.py").exists():
        return here
    config = Path.home() / ".cortex-forge" / "config.yml"
    if config.exists():
        for line in config.read_text().splitlines():
            line = line.strip()
            if line.startswith("cortex-forge:") or line.startswith("forge:"):
                candidate = Path(line.split(":", 1)[1].strip()) / "bin"
                if (candidate / "embeddings.py").exists():
                    return candidate
    print("ERROR: Cannot locate cortex-forge bin/embeddings.py. Check ~/.cortex-forge/config.yml.", file=sys.stderr)
    sys.exit(1)


sys.path.insert(0, str(_resolve_forge_bin()))
import embeddings as emb

DEFAULT_TOP_K = 5
DEFAULT_THRESHOLD = 0.5


def find_vault(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        # Canonical path (post-migration): .cortex/db/vault.db
        if (candidate / ".cortex" / "db" / "vault.db").exists():
            return candidate
        # Legacy path (pre-migration): .cortex/vault.db
        if (candidate / ".cortex" / "vault.db").exists():
            return candidate
    print("ERROR: vault.db not found. Run cortex-index first.", file=sys.stderr)
    sys.exit(1)


def load_threshold(cortex_dir: Path) -> float:
    config_path = cortex_dir / "config.json"
    if config_path.exists():
        cfg = json.loads(config_path.read_text())
        return cfg.get("distance_threshold", DEFAULT_THRESHOLD)
    return DEFAULT_THRESHOLD


def open_db(db_path: Path) -> sqlite3.Connection:
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
    if sqlite_vec_path:
        conn.load_extension(sqlite_vec_path)
    else:
        try:
            import sqlite_vec
            sqlite_vec.load(conn)
        except ImportError:
            print("ERROR: sqlite-vec not found.", file=sys.stderr)
            sys.exit(1)
    conn.enable_load_extension(False)
    return conn


def search(conn: sqlite3.Connection, query_vec_bytes: bytes, top_k: int, threshold: float) -> list[dict]:
    inner_limit = top_k * 3
    # sqlite-vec requires MATCH to run without JOINs; fetch rowids first
    knn_rows = conn.execute(f"""
        SELECT rowid, distance FROM vec_documents
        WHERE embedding MATCH ? AND k = {inner_limit}
        ORDER BY distance ASC
    """, (query_vec_bytes,)).fetchall()

    results = []
    for rowid, distance in knn_rows:
        if distance >= threshold:
            continue
        doc = conn.execute(
            "SELECT path, heading, chunk_index, content FROM documents WHERE rowid = ?",
            (rowid,)
        ).fetchone()
        if doc:
            results.append({
                "path": doc[0], "heading": doc[1],
                "chunk_index": doc[2], "content": doc[3],
                "distance": round(distance, 4)
            })

    return results[:top_k]


def main():
    parser = argparse.ArgumentParser(description="Semantic search over cortex vault")
    parser.add_argument("query", help="Search query")
    parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K)
    parser.add_argument("--vault", type=str, default=None)
    parser.add_argument("--json", action="store_true", help="Output JSON")
    parser.add_argument("--threshold", type=float, default=None,
                        help="Distance threshold override (default: from config.json)")
    args = parser.parse_args()

    vault = Path(args.vault).resolve() if args.vault else find_vault(Path.cwd())
    cortex_dir = vault / ".cortex"
    # Canonical path; fall back to legacy .cortex/vault.db for older vaults
    db_path = (cortex_dir / "db" / "vault.db") if (cortex_dir / "db" / "vault.db").exists() else (cortex_dir / "vault.db")
    threshold = args.threshold if args.threshold is not None else load_threshold(cortex_dir / "db" if (cortex_dir / "db").exists() else cortex_dir)

    emb.load_embedding_model()
    query_vec = emb.embed_query(args.query)
    query_bytes = emb.vec_to_bytes(query_vec)

    conn = open_db(db_path)
    results = search(conn, query_bytes, args.top_k, threshold)
    conn.close()

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return

    if not results:
        print(f"No results above similarity threshold ({threshold}).")
        return

    for r in results:
        loc = f"{r['path']}"
        if r["heading"]:
            loc += f" § {r['heading']}"
        sim = round(1.0 - r["distance"], 3)
        print(f"[{sim:.3f}] {loc}")
        snippet = r["content"][:200].replace("\n", " ")
        print(f"  {snippet}...")
        print()


if __name__ == "__main__":
    main()
