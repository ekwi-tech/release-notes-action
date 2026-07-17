# release-notes-action

Generate a release-note body from Conventional Commits — enriched with the PR author, PR number and a
first-time-contributor list — for the ekwi-tech fleet. One canonical [`cliff.toml`](./cliff.toml), one pinned
git-cliff, wrapped so a release repo carries neither.

It is the release-notes counterpart to
[`next-version-action`](https://github.com/ekwi-tech/next-version-action): version derivation lives there,
note generation lives here. Both are pinned by SHA and bumped by Dependabot.

## Usage

Replace your repo's `cliff.toml` **and** its git-cliff step with:

```yaml
    # The job must grant this — git-cliff reads each commit's associated PR:
    permissions:
      contents: write
      pull-requests: read

    steps:
      # ... derive the version (next-version-action) ...

      - name: Generate release notes
        id: notes
        uses: ekwi-tech/release-notes-action@<sha>   # pin by SHA
        with:
          version: ${{ steps.version.outputs.version }}   # X.Y.Z, no leading v
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Publish GitHub Release
        env:
          NOTES_FILE: ${{ steps.notes.outputs.notes-file }}
        run: gh release create "v${VERSION}" --notes-file "${NOTES_FILE}" ...
```

Requires `fetch-depth: 0` on the checkout (git-cliff needs the full history and tags).

## Inputs

| Input | Required | Default | Notes |
|---|---|---|---|
| `version` | yes | — | The `X.Y.Z` being released, without the leading `v`. |
| `token` | yes | — | Needs `pull-requests: read`. Usually `secrets.GITHUB_TOKEN`. |
| `git-cliff-version` | no | `v2.13.1` | git-cliff release tag (v-prefixed). **Do not lower.** 2.5.0 leaves `commit.remote.pr_number` empty and silently drops the PR from every line. |
| `config` | no | *(bundled)* | Path to a `cliff.toml` override. Leave empty to use the canonical fleet config. |

## Output

| Output | Notes |
|---|---|
| `notes-file` | Path to the generated delta, for `gh release create --notes-file`. |

## What the output looks like

```
### Bug Fixes
- Drop invalid class-level `@readonly` on ClassAttributeCollector by @ssylla in (#2 - [`8862632`](…))

### New Contributors
- @ssylla made their first contribution in #1
```

Design rationale (why the version pin, why the `(#N)` strip, why `[remote.github]` is injected rather than
configured) is recorded in the fleet ADR *"Dériver la version, et attribution des contributeurs"* (docs vault,
`integrations/ekwi-sync-adr-politique-de-version.md`, §7).
