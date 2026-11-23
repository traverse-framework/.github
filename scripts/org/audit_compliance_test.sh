#!/usr/bin/env bash
# Tests for scripts/org/audit_compliance.sh (.github#59). `gh` is a stub that
# serves repo files from a fixture tree, so nothing touches GitHub.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
audit="${here}/audit_compliance.sh"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
mkdir -p "${work}/bin"

cat > "${work}/bin/gh" <<'STUB'
#!/usr/bin/env bash
# Fixture layout: $FAKE_ROOT/repos (name<TAB>archived), $FAKE_ROOT/tags,
# $FAKE_ROOT/<repo>/<path> for file contents. A path containing $FAKE_FAIL
# answers HTTP 500; a missing path answers HTTP 404, as gh does.
jq_expr=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [[ "${args[i]}" == "--jq" ]] && jq_expr="${args[i + 1]}"
done
case "$1 $2" in
  "repo list")
    while IFS=$'\t' read -r name archived; do
      printf '{"name":"%s","isArchived":%s}\n' "$name" "$archived"
    done < "${FAKE_ROOT}/repos" | jq -s . | jq -r "${jq_expr}"
    exit 0 ;;
  "label list") printf 'needs-review\n'; exit 0 ;;
  "search issues") exit 0 ;;
esac
[[ "$1" == "api" ]] || { echo "unexpected gh call: $*" >&2; exit 99; }
path=""
for a in "${args[@]:1}"; do [[ "$a" == repos/* ]] && path="$a"; done
if [[ -n "${FAKE_FAIL:-}" && "$path" == *"${FAKE_FAIL}"* ]]; then
  echo "gh: Server Error (HTTP 500)" >&2; exit 1
fi
case "$path" in
  */rulesets) printf 'traverse-governance-baseline\n' ;;
  */tags) cat "${FAKE_ROOT}/tags" ;;
  */contents/*)
    repo="${path#repos/*/}"; repo="${repo%%/contents/*}"
    file="${FAKE_ROOT}/${repo}/${path#*/contents/}"
    if [[ -d "$file" ]]; then ls "$file"
    elif [[ ! -f "$file" ]]; then echo "gh: Not Found (HTTP 404)" >&2; exit 1
    elif [[ -n "$jq_expr" ]]; then echo "${path#*/contents/}"
    else cat "$file"; fi ;;
  *) echo "unexpected gh api path: $path" >&2; exit 99 ;;
esac
STUB
chmod +x "${work}/bin/gh"

failures=0
ok() { echo "ok - $1"; }
bad() { echo "not ok - $1" >&2; failures=$((failures + 1)); }
export PATH="${work}/bin:${PATH}" FAKE_ROOT="${work}/fx" AUDIT_ORG="example" AUDIT_EXEMPT_FILE="${work}/exempt.txt"

compliant_repo() { # compliant_repo <name>
  local d="${FAKE_ROOT}/$1"
  mkdir -p "$d/.github/workflows" "$d/.specify/memory"
  printf 'v1.6.0\n' > "$d/.governance-version"
  : > "$d/.github/dependabot.yml"; : > "$d/.github/workflows/cla.yml"; : > "$d/.github/workflows/governance.yml"
  printf '# Repo\n\nGovernance: see `.governance-version`. Uses Traverse v0.10.0 and Rust 1.95.\n' > "$d/CLAUDE.md"
  printf '# Agents\n\nRead CLAUDE.md. Claim with scripts/agent/claim.sh.\n' > "$d/AGENTS.md"
  printf '# Constitution Pointer\n\nSee traverse-framework/.github.\n' > "$d/.specify/memory/constitution.md"
}
fresh() {
  unset FAKE_FAIL
  rm -rf "${FAKE_ROOT}" && mkdir -p "${FAKE_ROOT}/.github"
  printf 'v1.4.0\nv1.6.0\nv1.10.0-rc1\nv1.5.0\n' > "${FAKE_ROOT}/tags"
  printf '# Constitution\n\n### I. Alpha\n### II. Beta\n### III. Gamma\n' > "${FAKE_ROOT}/.github/constitution.md"
  printf 'app\tfalse\nold\ttrue\n' > "${FAKE_ROOT}/repos"
  compliant_repo app
  : > "${AUDIT_EXEMPT_FILE}"
}
run() { got=0; bash "${audit}" > "${work}/out" 2>&1 || got=$?; }
row() { grep -E "^\| $1 \|" "${work}/out" || true; }
# cell <repo> <column-number> -> that cell of the repo's row (1 = repo name)
cell() { row "$1" | awk -F' \\| ' -v c="$2" '{ gsub(/^\| | \|$/, ""); print $c }'; }
expect() { # expect <name> <want-exit> <repo> <col> <cell>
  run
  local c; c="$(cell "$3" "$4")"
  if [[ "${got}" -ne "$2" ]]; then bad "$1: exit ${got}, want $2: $(cat "${work}/out")"
  elif [[ "$c" != "$5" ]]; then bad "$1: column $4 is '$c', want '$5': $(row "$3")"
  else ok "$1"; fi
}

fresh
expect "compliant repo passes; product versions in prose are allowed" 0 app 3 "✅"
grep -q "latest governance release v1.6.0" "${work}/out" && ok "latest is the highest stable tag (sort -V, rc ignored)" || bad "latest tag: $(head -4 "${work}/out")"
[[ -z "$(row old)" ]] && ok "archived repos are skipped" || bad "archived repos are skipped"

fresh; printf 'v1.5.0\n' > "${FAKE_ROOT}/app/.governance-version"
expect "a stale .governance-version is reported" 1 app 3 "❌"

fresh; rm "${FAKE_ROOT}/app/.governance-version"
expect "a missing pin fails both pin columns" 1 app 2 "❌"

fresh; rm "${FAKE_ROOT}/app/AGENTS.md"
expect "a missing AGENTS.md fails the pointer column" 1 app 8 "❌"

fresh; printf '# Agents\n\nClaim first.\n' > "${FAKE_ROOT}/app/AGENTS.md"
expect "an AGENTS.md that does not point at CLAUDE.md fails" 1 app 8 "❌"

fresh; rm "${FAKE_ROOT}/app/CLAUDE.md"
expect "an AGENTS.md pointing at a missing CLAUDE.md fails" 1 app 8 "❌"

fresh; head -c 6145 /dev/zero | tr '\0' 'x' > "${FAKE_ROOT}/app/CLAUDE.md"
expect "a CLAUDE.md over 6 KB fails" 1 app 9 "❌"
fresh; head -c 6144 /dev/zero | tr '\0' 'x' > "${FAKE_ROOT}/app/CLAUDE.md"
expect "a CLAUDE.md of exactly 6 KB passes" 0 app 9 "✅"

fresh; printf '# Repo\n\nAdopts governance version 1.6.0.\n' > "${FAKE_ROOT}/app/CLAUDE.md"
expect "a governance version in CLAUDE.md prose fails" 1 app 10 "❌"
fresh; printf 'Read CLAUDE.md. Scripts vendored from\n`traverse-framework/.github` v1.4.0.\n' > "${FAKE_ROOT}/app/AGENTS.md"
expect "a .github version in AGENTS.md prose fails" 1 app 10 "❌"
fresh; printf '# Pointer\n\nThis repo adopted governance version 1.0.0.\n' > "${FAKE_ROOT}/app/.specify/memory/constitution.md"
expect "a governance version in the constitution pointer fails" 1 app 10 "❌"
fresh; printf '# Repo\n\nServe on 127.0.0.1:8787 (see traverse-framework/.github#57).\n' > "${FAKE_ROOT}/app/CLAUDE.md"
expect "IP addresses and issue refs are not prose versions" 0 app 10 "✅"

fresh; printf '# Repo\n\nPinned at v1.3.0 of governance.\n' > "${FAKE_ROOT}/app/CLAUDE.md"
expect "a version before the word governance fails" 1 app 10 "❌"
fresh; printf '# Org-wide CLA gate — see traverse-framework/.github (governance v1.0.1).\nname: cla\n' > "${FAKE_ROOT}/app/.github/workflows/cla.yml"
expect "a governance version in a workflow comment fails" 1 app 10 "❌"
fresh; printf '# Rust 1.95.0 toolchain; pinned action versions below.\nname: ci\njobs:\n  x:\n    uses: traverse-framework/.github/.github/workflows/reusable-governance.yml@v1.6.0\n    steps:\n      - uses: actions/checkout@v4.2.0\n' > "${FAKE_ROOT}/app/.github/workflows/ci.yml"
expect "workflow code lines and unrelated comment versions are not prose versions" 0 app 10 "✅"

fresh; printf '# Local\n\n### I. Alpha\n### II. Beta\n' > "${FAKE_ROOT}/app/.specify/memory/constitution.md"
expect "a constitution sharing two org principles is a copy" 1 app 11 "❌"
fresh; printf '# Local\n\n### I. Alpha\n### Repo rule\n' > "${FAKE_ROOT}/app/.specify/memory/constitution.md"
expect "a repo constitution sharing one heading is not a copy" 0 app 11 "✅"
fresh; rm "${FAKE_ROOT}/app/.specify/memory/constitution.md"
expect "no constitution file passes" 0 app 11 "✅"

fresh; printf 'app\tfalse\ndemo\tfalse\n' > "${FAKE_ROOT}/repos"
printf 'demo # sample repo\n' > "${AUDIT_EXEMPT_FILE}"
run
[[ "${got}" -eq 0 && -z "$(row demo)" ]] && grep -qF -- '- `demo`: sample repo' "${work}/out" &&
  ok "exempt repos are listed with their reason and not audited" || bad "exempt: exit ${got} $(cat "${work}/out")"

for target in CLAUDE.md AGENTS.md .governance-version dependabot.yml constitution.md .github/workflows /tags; do
  fresh; export FAKE_FAIL="$target"
  run
  [[ "${got}" -eq 2 ]] && grep -q "audit incomplete: GitHub API error" "${work}/out" &&
    ok "an HTTP 500 on ${target} stops the audit (exit 2), not a pass" || bad "500 on ${target}: exit ${got} $(cat "${work}/out")"
done

fresh; : > "${FAKE_ROOT}/tags"
run
[[ "${got}" -eq 2 ]] && grep -q "cannot determine the latest" "${work}/out" &&
  ok "no release tag is an error, not a pass" || bad "no tags: exit ${got} $(cat "${work}/out")"

if [[ "${failures}" -gt 0 ]]; then
  echo "${failures} audit test(s) failed" >&2
  exit 1
fi
echo "audit tests passed"
