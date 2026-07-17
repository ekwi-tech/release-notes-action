#!/usr/bin/env bash
#
# Deterministic, OFFLINE test of the cliff.toml rendering rules — the non-obvious local logic a phantom mention
# or a doubled PR number would break in silence. It runs git-cliff WITHOUT --github-repo, so no GitHub API is
# touched: only the message preprocessors and the template's no-enrichment branches are exercised, which is
# exactly the logic that must hold regardless of the network.
#
# The enriched format ("by @author in (#PR - commit)") needs the API and is covered by the self-test job.
#
# Usage: GIT_CLIFF=/path/to/git-cliff test/rules.sh   (falls back to `git-cliff` on PATH)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
gc="${GIT_CLIFF:-git-cliff}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"
git init -q
git config user.email t@example.com
git config user.name tester
git commit -q --allow-empty -m "chore: root"
git tag v0.0.0
# A squash-merge subject as GitHub writes it: a code annotation (@readonly) mid-message AND a trailing (#5).
git commit -q --allow-empty -m "fix: guard @readonly access on init (#5)"

out="$("$gc" --config "$root/cliff.toml" --unreleased --tag v0.0.1 --strip all)"
printf '%s\n' "----- rendered -----" "$out" "--------------------"

fail=0
# `if` (not `&&`/`||`) so the function's own exit status is always 0 — otherwise `set -e` would kill the
# script on the very case a lack-assertion is testing for (grep not matching returns non-zero).
assert_has()   { if ! grep -qF -- "$1" <<<"$out"; then echo "::error::expected to find: $1";     fail=1; fi; }
assert_lacks() { if   grep -qF -- "$1" <<<"$out"; then echo "::error::expected NOT to find: $1"; fail=1; fi; }

# 1. The @-annotation is code-spanned, so GitHub never linkifies it into a phantom "Contributor".
assert_has  '`@readonly`'
# 2. The squash-appended " (#5)" is stripped from the message (it would otherwise double the PR number).
assert_lacks '(#5)'
# 3. With no PR resolved (offline), the line carries just "(commit)" — no orphan " in (" before it.
assert_lacks ' in ('

if [ "$fail" -ne 0 ]; then echo "rules: FAIL"; exit 1; fi
echo "rules: OK"
