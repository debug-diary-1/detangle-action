#!/usr/bin/env bash
# Runs `detangle check`: annotations on the pull request, a Markdown report
# in the job summary, and detangle's exit status (non-zero on errors, or on
# warnings with --strict). Inputs come from the environment: DETANGLE_PATH,
# DETANGLE_ARGS (split on whitespace), DETANGLE_SUMMARY, GITHUB_WORKSPACE,
# GITHUB_STEP_SUMMARY.
set -uo pipefail

read -ra args <<<"${DETANGLE_ARGS:-}"
path=${DETANGLE_PATH:-.}

# detangle reports files relative to the project; GitHub wants them relative
# to the repository, so annotations for a project in a subdirectory get its
# path in front.
root=$(cd "${GITHUB_WORKSPACE:-.}" && pwd -P)
project=$(cd "$path" && pwd -P) || exit 2
prefix=${project#"$root"}
prefix=${prefix#/}
[ -n "$prefix" ] && prefix=$prefix/

detangle check "$path" -f github ${args[@]+"${args[@]}"} | sed -E "s#^(::(error|warning|notice) file=)#\\1$prefix#"
status=${PIPESTATUS[0]}

if [ "${DETANGLE_SUMMARY:-true}" = true ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  detangle check "$path" -f markdown ${args[@]+"${args[@]}"} >>"$GITHUB_STEP_SUMMARY" || true
fi

exit "$status"
