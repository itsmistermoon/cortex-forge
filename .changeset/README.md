# Changesets

This repo uses [Changesets](https://changesets.dev/) for changelog and version bumps only — there's no `npm publish` step, since Antu distributes via `npx skills add itsmistermoon/cortex-forge`, not the npm registry.

## Adding a changeset

After a change worth mentioning in `CHANGELOG.md` (a new capability, a real bug fix, a behavior change — not internal refactors or wording tweaks):

```bash
npx changeset
```

Pick a bump type (patch/minor/major), write a one-paragraph summary from the user's perspective. Commit the generated `.changeset/{slug}.md` file alongside the change itself.

## Cutting a release

```bash
npx changeset version   # consolidates all pending changesets into CHANGELOG.md, bumps package.json
git add -A && git commit -m "chore: release vX.Y.Z"
git tag vX.Y.Z && git push && git push --tags
gh release create vX.Y.Z --notes-from-tag   # or write release notes manually
```

`changeset version` deletes the consumed `.changeset/*.md` files automatically — nothing to clean up by hand.
