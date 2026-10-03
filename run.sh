#!/usr/bin/env bash
# Runs `detangle check`: annotations on the pull request, a Markdown report
# in the job summary, and detangle's exit status (non-zero on errors, or on
# warnings with --strict). Inputs come from the environment: DETANGLE_PATH,
# DETANGLE_ARGS (split on whitespace), DETANGLE_SUMMARY, GITHUB_WORKSPACE,
# GITHUB_STEP_SUMMARY.
set -uo pipefail

read -ra args <<<"${DETANGLE_ARGS:-}"
path=${DETANGLE_PATH:-.}

# detangle reports files relative to the project root: the nearest ancestor
# of `path` with a detangle.toml, else one with a package.json, else `path`
# (as detangle's find_root). GitHub wants them relative to the repository, so
# annotations get the project root's path in front.
find_root() {
  local start=$1 marker dir
  for marker in detangle.toml package.json; do
    dir=$start
    while :; do
      [ -f "$dir/$marker" ] && { echo "$dir"; return; }
      [ "$dir" = / ] && break
      dir=$(dirname "$dir")
    done
  done
  echo "$start"
}
workspace=$(cd "${GITHUB_WORKSPACE:-.}" && pwd -P)
start=$(cd "$path" && pwd -P) || exit 2
project=$(find_root "$start")
prefix=${project#"$workspace"}
prefix=${prefix#/}
[ -n "$prefix" ] && prefix=$prefix/

detangle check "$path" -f github ${args[@]+"${args[@]}"} | sed -E "s#^(::(error|warning|notice) file=)#\\1$prefix#"
status=${PIPESTATUS[0]}

if [ "${DETANGLE_SUMMARY:-true}" = true ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  detangle check "$path" -f markdown ${args[@]+"${args[@]}"} >>"$GITHUB_STEP_SUMMARY" || true
fi

exit "$status"
