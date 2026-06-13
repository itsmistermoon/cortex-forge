# graphify — ARCHITECTURE.md

**URL:** https://github.com/safishamsi/graphify/blob/v8/ARCHITECTURE.md
**Fetched:** 2026-06-12

## Pipeline

detect() → extract() → build_graph() → cluster() → analyze() → report() → export()

Each stage is a single function in its own module. They communicate through plain Python dicts and NetworkX graphs.

## Module responsibilities

detect.py: collect_files(root) → directory → [Path] filtered list
extract.py: extract(path) → file path → {nodes, edges} dict
build.py: build_graph(extractions) → list of extraction dicts → nx.Graph
cluster.py: cluster(G) → graph with community attr on each node
analyze.py: analyze(G) → analysis dict (god nodes, surprises, questions)
report.py: render_report(G, analysis) → GRAPH_REPORT.md string
export.py: export(G, out_dir, ...) → Obsidian vault, graph.json, graph.html, graph.svg
callflow_html.py: write_callflow_html(...) → Mermaid architecture/call-flow HTML
ingest.py: ingest(url, ...) → URL → file saved to corpus dir
cache.py: check_semantic_cache / save_semantic_cache → (cached, uncached) split
security.py: validation helpers → URL / path / label → validated or raises
validate.py: validate_extraction(data) → extraction dict → raises on schema errors
serve.py: start_server(graph_path) → graph file path → MCP stdio server
watch.py: watch(root, flag_path) → directory → writes flag file on change
benchmark.py: run_benchmark(graph_path) → graph file → corpus vs subgraph token comparison

## Extraction output schema

Every extractor returns {nodes: [{id, label, source_file, source_location}], edges: [{source, target, relation, confidence}]}

## Confidence labels
EXTRACTED: explicitly stated in source
INFERRED: reasonable deduction
AMBIGUOUS: uncertain, flagged for human review

## Adding a new language extractor
1. Add extract_<lang>() function in extract.py
2. Register suffix in extract() dispatch and collect_files()
3. Add to CODE_EXTENSIONS + _WATCHED_EXTENSIONS
4. Add tree-sitter package to pyproject.toml
5. Add fixture + tests

## Security
All external input passes through security.py: validate_url, safe_fetch, validate_graph_path, sanitize_label.
