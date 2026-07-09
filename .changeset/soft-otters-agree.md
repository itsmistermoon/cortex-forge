---
"cortex-forge": patch
---

Hardened two GitHub Actions workflows (`persist-credentials: false` on checkout, explicit read-only `permissions:` on `changeset-check.yml`) and localized `cortex-recall`'s "offer to persist" line, which was hardcoded in English. All three were CodeRabbit findings from PR #5 that had gone unaddressed.
