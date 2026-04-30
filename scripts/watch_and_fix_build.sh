#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  watch_and_fix_build.sh
#
#  Monitors GitHub Actions build, extracts Dart compile errors, applies
#  known fixes automatically, and pushes until the build is green.
#
#  Usage: bash scripts/watch_and_fix_build.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e
REPO="taqi59a/POS-Africa"
MAX_ROUNDS=10
ROUND=0

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { echo "[$(date '+%H:%M:%S')] ✓ $*"; }
fail() { echo "[$(date '+%H:%M:%S')] ✗ $*"; }

# ── Wait for a run to finish ─────────────────────────────────────────────────
wait_for_run() {
  local run_id="$1"
  log "Waiting for run $run_id to complete..."
  while true; do
    local status conclusion
    status=$(gh run view "$run_id" --repo "$REPO" --json status --jq '.status' 2>/dev/null)
    conclusion=$(gh run view "$run_id" --repo "$REPO" --json conclusion --jq '.conclusion' 2>/dev/null)
    if [[ "$status" == "completed" ]]; then
      echo "$conclusion"
      return
    fi
    sleep 20
  done
}

# ── Get latest run id ────────────────────────────────────────────────────────
latest_run_id() {
  gh run list --repo "$REPO" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null
}

# ── Extract dart errors from a failed run ────────────────────────────────────
get_errors() {
  local run_id="$1"
  gh run view "$run_id" --repo "$REPO" --log-failed 2>/dev/null \
    | grep "\.dart.*error G" \
    | sed 's/.*2026.*Z //' \
    | grep -v "MSB8066\|Build process\|##\[error\]Process\|flutter_assemble"
}

# ── Apply known auto-fixes ───────────────────────────────────────────────────
apply_fixes() {
  local errors="$1"
  local fixed=0

  # Pattern: wrong relative import depth (../../feature -> ../../../feature)
  while IFS= read -r err; do
    local file col msg
    file=$(echo "$err" | grep -oP "lib/[^(]+")
    msg=$(echo "$err"  | grep -oP ": error \w+: .+")
    [[ -z "$file" ]] && continue

    # "Cannot find path" or "isn't a type" -> likely wrong import depth
    if echo "$msg" | grep -qiE "cannot find the path|isn't a type|not found"; then
      local suspect_import
      suspect_import=$(grep -n "import '../../" "$file" 2>/dev/null | head -5)
      if [[ -n "$suspect_import" ]]; then
        log "  Auto-fix: adjusting import depth in $file"
        sed -i "s|import '../../features/|import '../../../|g" "$file" 2>/dev/null && fixed=$((fixed+1))
        sed -i "s|import '../../inventory/|import '../../../inventory/|g" "$file" 2>/dev/null
        sed -i "s|import '../../reports/|import '../../../reports/|g" "$file" 2>/dev/null
        sed -i "s|import '../../settings/|import '../../../settings/|g" "$file" 2>/dev/null
        sed -i "s|import '../../auth/|import '../../../auth/|g" "$file" 2>/dev/null
      fi
    fi

    # fold(0, ...) -> fold(0.0, ...) double/int mismatch
    if echo "$msg" | grep -qi "can't be returned from a function with return type 'int'"; then
      log "  Auto-fix: fold(0,...) -> fold(0.0,...) in $file"
      sed -i "s/\.fold(0, /.fold(0.0, /g" "$file" 2>/dev/null && fixed=$((fixed+1))
    fi

    # wrong field name on generated Drift class
    if echo "$msg" | grep -qi "getter '.*' isn't defined"; then
      log "  NOTE: Generated Drift field name mismatch in $file - manual inspection needed"
    fi

  done <<< "$errors"

  return $fixed
}

# ── MAIN LOOP ────────────────────────────────────────────────────────────────
log "=== Build Watch & Auto-Fix starting (repo: $REPO) ==="

while [[ $ROUND -lt $MAX_ROUNDS ]]; do
  ROUND=$((ROUND + 1))
  log ""
  log "── Round $ROUND of $MAX_ROUNDS ──────────────────────────────"

  # Wait a few seconds for GitHub to register the push
  sleep 10

  RUN_ID=$(latest_run_id)
  if [[ -z "$RUN_ID" ]]; then
    fail "Could not find a run. Is the workflow enabled?"
    exit 1
  fi
  log "Latest run: $RUN_ID"

  CONCLUSION=$(wait_for_run "$RUN_ID")
  log "Run $RUN_ID finished: $CONCLUSION"

  if [[ "$CONCLUSION" == "success" ]]; then
    pass "BUILD GREEN! EXE is ready at:"
    pass "https://github.com/$REPO/actions/runs/$RUN_ID"
    log ""
    log "Download the artifact:"
    gh run view "$RUN_ID" --repo "$REPO" --json url --jq '.url'
    exit 0
  fi

  if [[ "$CONCLUSION" != "failure" ]]; then
    fail "Unexpected conclusion: $CONCLUSION"
    exit 1
  fi

  # Build failed — extract and display errors
  log ""
  log "Build failed. Extracting errors..."
  ERRORS=$(get_errors "$RUN_ID")
  if [[ -z "$ERRORS" ]]; then
    fail "Could not extract errors. Check manually:"
    fail "https://github.com/$REPO/actions/runs/$RUN_ID"
    exit 1
  fi

  log "Errors found:"
  echo "$ERRORS" | while IFS= read -r line; do
    log "  $line"
  done

  # Try automatic fixes
  log "Attempting automatic fixes..."
  apply_fixes "$ERRORS"
  FIXED=$?

  if [[ $FIXED -eq 0 ]]; then
    fail "No automatic fix available for these errors."
    fail "Errors need manual intervention:"
    echo "$ERRORS"
    exit 1
  fi

  log "Applied $FIXED fix(es). Committing and pushing..."
  git add -A
  git diff --cached --stat
  git commit -m "fix(auto): round $ROUND — auto-fix based on CI errors" || {
    log "Nothing to commit — errors may need manual fix"
    exit 1
  }
  git push origin main

  log "Pushed. Waiting for new build to start..."
  sleep 15
done

fail "Reached max rounds ($MAX_ROUNDS) without a green build."
exit 1
