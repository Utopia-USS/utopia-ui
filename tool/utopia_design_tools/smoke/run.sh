#!/usr/bin/env bash
# A7 end-to-end smoke harness for the Utopia Design Protocol tooling.
#
# Exercises, in order:
#   1. in-repo pass of all 7 executables (real repo, real exit codes)
#   2. subprocess bin regression (--help / missing-file / malformed-JSON /
#      invalid-input / --json envelope) for all 7 executables
#   3. a fresh external Flutter app: bootstrap, rebrand (x 4->5 via --fix,
#      color.primary/accent to a new hue), generate_theme, wire it, build,
#      screenshot the rebrand (and the silent-fallback trap without wiring)
#   4. twin-vs-flutter hero screenshots (default + rebranded twin)
#   custom: the A11 custom-component loop - generate_manifest --project against
#      a scratch copy of the fixture consumer, validate_manifest on the merged
#      view, a doctored-utopiaUiVersion freshness-gate negative, and a
#      determinism rerun (deferred from this harness's original checklist
#      item 4 until generate_manifest --project existed)
#   5. writes ledger/checkpoints/A7.md with every command/exit code/artifact
#
# bash 3.2 compatible (macOS default /bin/bash). Idempotent: safe to rerun.
#
# Hard rules: this script only WRITES into the scratchpad/artifacts area and
# ledger/checkpoints/A7.md. It never modifies lib/, example/, protocol/,
# tokens/, manifest/, twin/, or any committed tool source.

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOOL_DIR="$REPO_ROOT/tool/utopia_design_tools"
BIN_DIR="$TOOL_DIR/bin"

SCRATCH_ROOT="/private/tmp/claude-501/-Users-jakobkirchner-IdeaProjects-utopia-ui/a95ae1e5-c7e6-40a0-9d69-3d43322c74d6/scratchpad/a7"
ARTIFACTS_DIR="$SCRATCH_ROOT/artifacts"
WORK_DIR="$SCRATCH_ROOT/work"
PROGRESS_LOG="$SCRATCH_ROOT/progress.log"
RESULTS_TSV="$SCRATCH_ROOT/results.tsv"
FINDINGS_LOG="$SCRATCH_ROOT/findings.log"

EXTERNAL_APP_DIR="$SCRATCH_ROOT/external_app"
TWIN_REBRAND_DIR="$SCRATCH_ROOT/twin_rebrand"

CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

DART_BIN="$(command -v dart)"
FLUTTER_BIN="$(command -v flutter)"

mkdir -p "$ARTIFACTS_DIR" "$WORK_DIR"
: > "$PROGRESS_LOG"
: > "$RESULTS_TSV"
: > "$FINDINGS_LOG"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
  local msg="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$PROGRESS_LOG"
}

banner() {
  local msg="$1"
  log ""
  log "=== $msg ==="
}

# record_result <item> <check> <status:PASS|FAIL> <detail>
record_result() {
  local item="$1" check="$2" status="$3" detail="$4"
  # Flatten embedded newlines/tabs in detail before writing to the TSV: the
  # report renderer splits on tab and expects exactly 4 fields per line.
  local flat_detail
  flat_detail="$(printf '%s' "$detail" | tr '\n\t' '  ')"
  printf '%s\t%s\t%s\t%s\n' "$item" "$check" "$status" "$flat_detail" >> "$RESULTS_TSV"
  log "[$status] $item: $check -- $detail"
}

record_finding() {
  local title="$1" repro="$2"
  {
    echo "### FINDING: $title"
    echo "repro: $repro"
    echo ""
  } >> "$FINDINGS_LOG"
  log "[FINDING] $title"
}

# run_dart <bin-name.dart> [args...] - runs a tool bin with `dart run`,
# capturing stdout/stderr/exit code into globals for the caller to inspect.
LAST_STDOUT=""
LAST_STDERR=""
LAST_EXIT=0

run_dart() {
  local bin="$1"
  shift
  local out err rc
  out="$(mktemp "$WORK_DIR/stdout.XXXXXX")"
  err="$(mktemp "$WORK_DIR/stderr.XXXXXX")"
  set +e
  (cd "$TOOL_DIR" && "$DART_BIN" run "$BIN_DIR/$bin" "$@") >"$out" 2>"$err"
  rc=$?
  set -e
  LAST_STDOUT="$(cat "$out")"
  LAST_STDERR="$(cat "$err")"
  LAST_EXIT=$rc
  rm -f "$out" "$err"
}

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" -eq "$expected" ]; then
    return 0
  else
    log "UNEXPECTED EXIT: $label expected=$expected actual=$actual"
    return 1
  fi
}

cleanup() {
  local rc=$?
  log "cleanup: harness exiting with code $rc"
  rm -f "$WORK_DIR"/stdout.* "$WORK_DIR"/stderr.* 2>/dev/null || true
  # Belt-and-suspenders: make sure none of the screenshot ports this harness
  # uses are left bound to a server on exit (crash, kill, or normal return),
  # so a subsequent rerun never risks a stale server answering with old
  # content instead of the fresh one it just started (see kill_port()).
  for p in 8743 8744 8745 8746 8747; do
    local pids
    pids="$(lsof -ti "tcp:$p" 2>/dev/null || true)"
    if [ -n "$pids" ]; then
      echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
  done
}
trap cleanup EXIT

# serve_and_screenshot <web-dir> <port> <out-png> [label]
# Serves a static directory with python3's http.server, waits for it to come
# up, screenshots with headless Chrome, then tears the server down.
kill_port() {
  local port="$1"
  local pids
  pids="$(lsof -ti "tcp:$port" 2>/dev/null || true)"
  if [ -n "$pids" ]; then
    log "killing stale process(es) on port $port: $pids"
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 0.3
  fi
}

serve_and_screenshot() {
  # path defaults to /index.html: correct for the two Flutter web builds
  # (build/web ships its own index.html). The twin directory has no
  # index.html - only gallery.html/components.html - so python's http.server
  # would otherwise serve a directory LISTING page for "/" and every twin
  # screenshot would silently show that instead of the design surface.
  # Callers screenshotting the twin must pass path=/gallery.html explicitly.
  local web_dir="$1" port="$2" out_png="$3" label="${4:-}" path="${5:-/}"
  # Guard against a stale server left over from a previous (possibly killed
  # or crashed) run of this harness still bound to the port: without this, a
  # leftover server would silently serve STALE content (a different run's
  # directory) to this run's screenshot request. Always start from a clean port.
  kill_port "$port"
  (cd "$web_dir" && exec python3 -m http.server "$port" >"$WORK_DIR/server-$port.log" 2>&1) &
  local pid=$!
  local tries=0
  while ! curl -s -o /dev/null "http://localhost:$port$path" ; do
    tries=$((tries + 1))
    if [ "$tries" -gt 40 ]; then
      log "server on port $port never came up ($label)"
      kill "$pid" 2>/dev/null || true
      kill_port "$port"
      return 1
    fi
    sleep 0.25
  done
  # Give the SPA a moment to finish its first paint.
  sleep 1.5
  "$CHROME_BIN" --headless=new --disable-gpu --no-sandbox \
    --window-size=1400,1000 \
    --virtual-time-budget=4000 \
    --screenshot="$out_png" \
    "http://localhost:$port$path" >>"$WORK_DIR/chrome-$port.log" 2>&1 || true
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  # Belt-and-suspenders: exec above should mean $pid IS the python process,
  # but if anything slipped through, make sure the port is free for whatever
  # runs next (and for a rerun of this same script).
  kill_port "$port"
  if [ -s "$out_png" ]; then
    return 0
  else
    return 1
  fi
}

STEP1_STATUS="PENDING"
STEP2_STATUS="PENDING"
STEP3_STATUS="PENDING"
STEP4_STATUS="PENDING"
STEP_CUSTOM_STATUS="PENDING"

log "A7 smoke harness starting. REPO_ROOT=$REPO_ROOT"
log "Artifacts will be retained under $ARTIFACTS_DIR"

# ===========================================================================
# STEP 1: IN-REPO TOOL PASS (checklist item 1)
# ===========================================================================
banner "STEP 1: in-repo tool pass"

step1_ok=true

# --- export_tokens: regenerate and byte-compare to the committed export ---
banner "1a export_tokens determinism + byte-identical to committed tokens"
EXPORT_TMP="$WORK_DIR/export_tokens_rerun.json"
rm -f "$EXPORT_TMP"
run_dart export_tokens.dart -o "$EXPORT_TMP"
if assert_exit 0 "$LAST_EXIT" "export_tokens"; then
  if diff -q "$EXPORT_TMP" "$REPO_ROOT/tokens/utopia.tokens.json" >/dev/null 2>&1; then
    record_result "1" "export_tokens byte-identical to committed tokens/utopia.tokens.json" "PASS" "$EXPORT_TMP == tokens/utopia.tokens.json"
  else
    record_result "1" "export_tokens byte-identical to committed tokens/utopia.tokens.json" "FAIL" "diff found"
    record_finding "export_tokens output differs from committed tokens/utopia.tokens.json" \
      "cd $TOOL_DIR && dart run bin/export_tokens.dart -o /tmp/x.json && diff /tmp/x.json $REPO_ROOT/tokens/utopia.tokens.json"
    step1_ok=false
  fi
else
  record_result "1" "export_tokens exits 0 against repo" "FAIL" "exit=$LAST_EXIT stderr=$LAST_STDERR"
  step1_ok=false
fi

# --- validate_tokens: clean pass against the committed doc ---
banner "1b validate_tokens clean pass"
run_dart validate_tokens.dart "$REPO_ROOT/tokens/utopia.tokens.json"
if assert_exit 0 "$LAST_EXIT" "validate_tokens clean"; then
  record_result "1" "validate_tokens exit 0 on committed tokens/utopia.tokens.json" "PASS" "0 error(s)"
else
  record_result "1" "validate_tokens exit 0 on committed tokens/utopia.tokens.json" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT"
  step1_ok=false
fi

# --- validate_tokens: one invalid fixture -> exit 1 ---
banner "1c validate_tokens invalid fixture -> exit 1"
INVALID_TOKENS="$WORK_DIR/invalid-tokens.json"
python3 - "$REPO_ROOT/tokens/utopia.tokens.json" "$INVALID_TOKENS" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
d = json.load(open(src))
d["color"]["primary"]["$value"]["hex"] = "#ffffff"  # deliberately incoherent with components
json.dump(d, open(dst, "w"), indent=2)
PY
run_dart validate_tokens.dart "$INVALID_TOKENS"
if assert_exit 1 "$LAST_EXIT" "validate_tokens invalid fixture"; then
  record_result "1" "validate_tokens exit 1 on doctored hex/components mismatch" "PASS" "$LAST_STDOUT"
else
  record_result "1" "validate_tokens exit 1 on doctored hex/components mismatch" "FAIL" "exit=$LAST_EXIT"
  step1_ok=false
fi

# --- generate_manifest: run against repo, determinism byte-check ---
banner "1d generate_manifest determinism (rerun byte-identical)"
MANIFEST_RUN1="$WORK_DIR/manifest_run1.json"
MANIFEST_RUN2="$WORK_DIR/manifest_run2.json"
run_dart generate_manifest.dart -o "$MANIFEST_RUN1"
RUN1_EXIT=$LAST_EXIT
RUN1_OUT="$LAST_STDOUT"
run_dart generate_manifest.dart -o "$MANIFEST_RUN2"
RUN2_EXIT=$LAST_EXIT
if assert_exit 0 "$RUN1_EXIT" "generate_manifest run1" && assert_exit 0 "$RUN2_EXIT" "generate_manifest run2"; then
  if diff -q "$MANIFEST_RUN1" "$MANIFEST_RUN2" >/dev/null 2>&1; then
    record_result "1" "generate_manifest determinism (two reruns byte-identical)" "PASS" "$MANIFEST_RUN1 == $MANIFEST_RUN2"
  else
    record_result "1" "generate_manifest determinism (two reruns byte-identical)" "FAIL" "diff found between reruns"
    record_finding "generate_manifest is non-deterministic across reruns without --timestamp" \
      "cd $TOOL_DIR && dart run bin/generate_manifest.dart -o /tmp/m1.json && dart run bin/generate_manifest.dart -o /tmp/m2.json && diff /tmp/m1.json /tmp/m2.json"
    step1_ok=false
  fi
  if diff -q "$MANIFEST_RUN1" "$REPO_ROOT/manifest/utopia.manifest.json" >/dev/null 2>&1; then
    record_result "1" "generate_manifest output matches committed manifest/utopia.manifest.json" "PASS" "byte-identical"
  else
    record_result "1" "generate_manifest output matches committed manifest/utopia.manifest.json" "FAIL" "diff found vs committed manifest (may be stale committed copy, not necessarily a tool bug)"
  fi
else
  record_result "1" "generate_manifest exits 0 against repo (both reruns)" "FAIL" "run1=$RUN1_EXIT run2=$RUN2_EXIT out=$RUN1_OUT"
  step1_ok=false
fi

# --- validate_manifest: clean pass ---
banner "1e validate_manifest clean pass (zero-arg, default resolution)"
run_dart validate_manifest.dart "$REPO_ROOT/manifest/utopia.manifest.json" --sources "$REPO_ROOT"
if assert_exit 0 "$LAST_EXIT" "validate_manifest clean"; then
  record_result "1" "validate_manifest exit 0 on committed manifest/utopia.manifest.json" "PASS" "0 error(s)"
else
  record_result "1" "validate_manifest exit 0 on committed manifest/utopia.manifest.json" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT"
  step1_ok=false
fi

# --- validate_manifest: doctored manifest copy in /tmp -> exit 1 with --sources . ---
banner "1f validate_manifest doctored manifest -> exit 1 with --sources"
DOCTORED_MANIFEST="$WORK_DIR/doctored-manifest.json"
python3 - "$REPO_ROOT/manifest/utopia.manifest.json" "$DOCTORED_MANIFEST" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
d = json.load(open(src))
d["packageVersion"] = "0.0.1-doctored"  # drift gate: must equal resolved utopia_ui pubspec version
json.dump(d, open(dst, "w"), indent=2)
PY
run_dart validate_manifest.dart "$DOCTORED_MANIFEST" --sources "$REPO_ROOT"
if assert_exit 1 "$LAST_EXIT" "validate_manifest doctored"; then
  record_result "1" "validate_manifest exit 1 on doctored packageVersion with --sources $REPO_ROOT" "PASS" "$LAST_STDOUT"
else
  record_result "1" "validate_manifest exit 1 on doctored packageVersion with --sources $REPO_ROOT" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT"
  step1_ok=false
fi

# --- generate_theme: golden byte-check (defaultTheme round trip) ---
banner "1g generate_theme golden byte-check"
THEME_OUT="$WORK_DIR/utopia_theme_run1.g.dart"
THEME_OUT2="$WORK_DIR/utopia_theme_run2.g.dart"
run_dart generate_theme.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$THEME_OUT"
RUN1_EXIT=$LAST_EXIT
run_dart generate_theme.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$THEME_OUT2"
RUN2_EXIT=$LAST_EXIT
if assert_exit 0 "$RUN1_EXIT" "generate_theme run1" && assert_exit 0 "$RUN2_EXIT" "generate_theme run2"; then
  if diff -q "$THEME_OUT" "$THEME_OUT2" >/dev/null 2>&1; then
    record_result "1" "generate_theme byte-identical reruns" "PASS" "deterministic"
  else
    record_result "1" "generate_theme byte-identical reruns" "FAIL" "diff between reruns"
    record_finding "generate_theme is non-deterministic across reruns" \
      "cd $TOOL_DIR && dart run bin/generate_theme.dart $REPO_ROOT/tokens/utopia.tokens.json -o /tmp/t1.dart && dart run bin/generate_theme.dart $REPO_ROOT/tokens/utopia.tokens.json -o /tmp/t2.dart && diff /tmp/t1.dart /tmp/t2.dart"
    step1_ok=false
  fi
else
  record_result "1" "generate_theme exits 0 against committed tokens (golden)" "FAIL" "run1=$RUN1_EXIT run2=$RUN2_EXIT"
  step1_ok=false
fi
# generate_theme on an invalid fixture -> exit 1 and no output file
GEN_THEME_INVALID_OUT="$WORK_DIR/should_not_exist_theme.g.dart"
rm -f "$GEN_THEME_INVALID_OUT"
run_dart generate_theme.dart "$INVALID_TOKENS" -o "$GEN_THEME_INVALID_OUT"
if assert_exit 1 "$LAST_EXIT" "generate_theme invalid fixture" && [ ! -e "$GEN_THEME_INVALID_OUT" ]; then
  record_result "1" "generate_theme exit 1 + nothing written on invalid tokens fixture" "PASS" "no file at $GEN_THEME_INVALID_OUT"
else
  record_result "1" "generate_theme exit 1 + nothing written on invalid tokens fixture" "FAIL" "exit=$LAST_EXIT file_exists=$([ -e "$GEN_THEME_INVALID_OUT" ] && echo yes || echo no)"
  step1_ok=false
fi

# --- generate_twin: freshness byte-check (rerun into scratch dir) ---
banner "1h generate_twin freshness byte-check"
TWIN_RUN1="$WORK_DIR/twin_run1"
TWIN_RUN2="$WORK_DIR/twin_run2"
rm -rf "$TWIN_RUN1" "$TWIN_RUN2"
run_dart generate_twin.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$TWIN_RUN1"
RUN1_EXIT=$LAST_EXIT
run_dart generate_twin.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$TWIN_RUN2"
RUN2_EXIT=$LAST_EXIT
if assert_exit 0 "$RUN1_EXIT" "generate_twin run1" && assert_exit 0 "$RUN2_EXIT" "generate_twin run2"; then
  if diff -rq "$TWIN_RUN1" "$TWIN_RUN2" >/dev/null 2>&1; then
    record_result "1" "generate_twin byte-identical reruns (determinism)" "PASS" "deterministic"
  else
    record_result "1" "generate_twin byte-identical reruns (determinism)" "FAIL" "diff between reruns"
    step1_ok=false
  fi
  if diff -q "$TWIN_RUN1/tokens.css" "$REPO_ROOT/twin/tokens.css" >/dev/null 2>&1; then
    record_result "1" "generate_twin tokens.css matches committed twin/tokens.css" "PASS" "fresh"
  else
    record_result "1" "generate_twin tokens.css matches committed twin/tokens.css" "FAIL" "twin/tokens.css is stale relative to tokens/utopia.tokens.json"
  fi
else
  record_result "1" "generate_twin exits 0 against committed tokens" "FAIL" "run1=$RUN1_EXIT run2=$RUN2_EXIT"
  step1_ok=false
fi

# --- validate_twin: on the real twin -> exit 0 ---
banner "1i validate_twin on the real twin/ -> exit 0"
run_dart validate_twin.dart --twin-dir "$REPO_ROOT/twin" --manifest "$REPO_ROOT/manifest/utopia.manifest.json" --tokens "$REPO_ROOT/tokens/utopia.tokens.json"
if assert_exit 0 "$LAST_EXIT" "validate_twin real twin"; then
  record_result "1" "validate_twin exit 0 on committed twin/" "PASS" "0 error(s)"
else
  record_result "1" "validate_twin exit 0 on committed twin/" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT stderr=$LAST_STDERR"
  step1_ok=false
fi

if $step1_ok; then STEP1_STATUS="PASS"; else STEP1_STATUS="FAIL"; fi
log "STEP 1 overall: $STEP1_STATUS"

# ===========================================================================
# STEP 2: SUBPROCESS BIN REGRESSION (checklist item 2)
# ===========================================================================
banner "STEP 2: subprocess bin regression (7 bins x --help/missing-file/malformed-JSON/invalid/--json)"

step2_ok=true
MALFORMED_JSON="$WORK_DIR/malformed.json"
printf '{not valid json' > "$MALFORMED_JSON"

check_help() {
  local bin="$1"
  run_dart "$bin" --help
  if assert_exit 0 "$LAST_EXIT" "$bin --help"; then
    record_result "2" "$bin --help exit 0" "PASS" "usage printed"
  else
    record_result "2" "$bin --help exit 0" "FAIL" "exit=$LAST_EXIT"
    step2_ok=false
  fi
}

check_missing_file() {
  local bin="$1"; shift
  run_dart "$bin" "$@"
  if assert_exit 2 "$LAST_EXIT" "$bin missing-file"; then
    record_result "2" "$bin missing-file exit 2" "PASS" "$LAST_STDERR"
  else
    record_result "2" "$bin missing-file exit 2" "FAIL" "exit=$LAST_EXIT stderr=$LAST_STDERR"
    step2_ok=false
  fi
}

check_malformed() {
  local bin="$1"; shift
  run_dart "$bin" "$@"
  if assert_exit 2 "$LAST_EXIT" "$bin malformed-JSON"; then
    record_result "2" "$bin malformed-JSON exit 2" "PASS" "$LAST_STDERR"
  else
    record_result "2" "$bin malformed-JSON exit 2" "FAIL" "exit=$LAST_EXIT stderr=$LAST_STDERR"
    step2_ok=false
  fi
}

for bin in export_tokens.dart validate_tokens.dart generate_manifest.dart validate_manifest.dart generate_theme.dart generate_twin.dart validate_twin.dart; do
  check_help "$bin"
done

# missing-file: only meaningful for bins with a file-ish argument.
check_missing_file validate_tokens.dart "$WORK_DIR/nope-tokens.json"
check_missing_file validate_manifest.dart "$WORK_DIR/nope-manifest.json"
check_missing_file generate_theme.dart "$WORK_DIR/nope-tokens.json"
check_missing_file generate_twin.dart "$WORK_DIR/nope-tokens.json"
check_missing_file validate_twin.dart --twin-dir "$WORK_DIR/nope-twin-dir"

# malformed-JSON
check_malformed validate_tokens.dart "$MALFORMED_JSON"
check_malformed validate_manifest.dart "$MALFORMED_JSON"
check_malformed generate_theme.dart "$MALFORMED_JSON"
check_malformed generate_twin.dart "$MALFORMED_JSON"
check_malformed validate_manifest.dart --schema "$MALFORMED_JSON" "$REPO_ROOT/manifest/utopia.manifest.json"
check_malformed validate_twin.dart --manifest "$MALFORMED_JSON"
check_malformed validate_twin.dart --tokens "$MALFORMED_JSON"

# invalid input -> exit 1, findings, nothing written (where applicable)
run_dart validate_tokens.dart "$INVALID_TOKENS"
if assert_exit 1 "$LAST_EXIT" "validate_tokens invalid"; then
  record_result "2" "validate_tokens invalid input exit 1 with findings" "PASS" "$LAST_STDOUT"
else
  record_result "2" "validate_tokens invalid input exit 1 with findings" "FAIL" "exit=$LAST_EXIT"
  step2_ok=false
fi

run_dart validate_manifest.dart "$DOCTORED_MANIFEST" --sources "$REPO_ROOT"
if assert_exit 1 "$LAST_EXIT" "validate_manifest invalid"; then
  record_result "2" "validate_manifest invalid input exit 1 with findings" "PASS" "$LAST_STDOUT"
else
  record_result "2" "validate_manifest invalid input exit 1 with findings" "FAIL" "exit=$LAST_EXIT"
  step2_ok=false
fi

NOTHING_WRITTEN_THEME="$WORK_DIR/regress_theme_should_not_exist.g.dart"
rm -f "$NOTHING_WRITTEN_THEME"
run_dart generate_theme.dart "$INVALID_TOKENS" -o "$NOTHING_WRITTEN_THEME"
if assert_exit 1 "$LAST_EXIT" "generate_theme invalid" && [ ! -e "$NOTHING_WRITTEN_THEME" ]; then
  record_result "2" "generate_theme invalid input exit 1, nothing written" "PASS" "no file"
else
  record_result "2" "generate_theme invalid input exit 1, nothing written" "FAIL" "exit=$LAST_EXIT"
  step2_ok=false
fi

NOTHING_WRITTEN_TWIN="$WORK_DIR/regress_twin_should_not_exist"
rm -rf "$NOTHING_WRITTEN_TWIN"
run_dart generate_twin.dart "$INVALID_TOKENS" -o "$NOTHING_WRITTEN_TWIN"
if assert_exit 1 "$LAST_EXIT" "generate_twin invalid" && [ ! -e "$NOTHING_WRITTEN_TWIN" ]; then
  record_result "2" "generate_twin invalid input exit 1, nothing written" "PASS" "no dir"
else
  record_result "2" "generate_twin invalid input exit 1, nothing written" "FAIL" "exit=$LAST_EXIT"
  step2_ok=false
fi

# --json envelope shape, parsed with python3 -m json.tool
check_json_envelope() {
  local bin="$1"; shift
  local out
  out="$(mktemp "$WORK_DIR/json_env.XXXXXX")"
  set +e
  (cd "$TOOL_DIR" && "$DART_BIN" run "$BIN_DIR/$bin" "$@" --json) >"$out" 2>/dev/null
  set -e
  if python3 -m json.tool "$out" >/dev/null 2>&1; then
    record_result "2" "$bin --json envelope parses" "PASS" "valid JSON"
  else
    record_result "2" "$bin --json envelope parses" "FAIL" "invalid JSON emitted"
    step2_ok=false
  fi
  rm -f "$out"
}

check_json_envelope validate_tokens.dart "$REPO_ROOT/tokens/utopia.tokens.json"
check_json_envelope validate_manifest.dart "$REPO_ROOT/manifest/utopia.manifest.json" --sources "$REPO_ROOT"
check_json_envelope validate_twin.dart --twin-dir "$REPO_ROOT/twin" --manifest "$REPO_ROOT/manifest/utopia.manifest.json" --tokens "$REPO_ROOT/tokens/utopia.tokens.json"
check_json_envelope generate_theme.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$WORK_DIR/json_envelope_theme.g.dart"
check_json_envelope generate_twin.dart "$REPO_ROOT/tokens/utopia.tokens.json" -o "$WORK_DIR/json_envelope_twin"
check_json_envelope export_tokens.dart -o "$WORK_DIR/json_envelope_export.json"
check_json_envelope generate_manifest.dart -o "$WORK_DIR/json_envelope_manifest.json"

if $step2_ok; then STEP2_STATUS="PASS"; else STEP2_STATUS="FAIL"; fi
log "STEP 2 overall: $STEP2_STATUS"

# ===========================================================================
# STEP 3: FRESH EXTERNAL APP E2E (checklist item 3)
# ===========================================================================
banner "STEP 3: fresh external Flutter app end-to-end"

step3_ok=true

if [ -d "$EXTERNAL_APP_DIR" ]; then
  log "external app already exists at $EXTERNAL_APP_DIR, removing for a clean rerun"
  rm -rf "$EXTERNAL_APP_DIR"
fi

log "flutter create external_app (this can take a minute)"
if (cd "$SCRATCH_ROOT" && "$FLUTTER_BIN" create --platforms=web --project-name external_app external_app) >>"$PROGRESS_LOG" 2>&1; then
  record_result "3" "flutter create scratch app" "PASS" "$EXTERNAL_APP_DIR"
else
  record_result "3" "flutter create scratch app" "FAIL" "see progress.log"
  step3_ok=false
fi

# --- pubspec: add utopia_ui + utopia_design_tools as path deps WITH the
# dependency_overrides pattern B8 documented (needed for BOTH). ---
banner "3b wire pubspec.yaml with path deps + dependency_overrides (B8 friction pattern)"
EXT_PUBSPEC="$EXTERNAL_APP_DIR/pubspec.yaml"
python3 - "$EXT_PUBSPEC" "$REPO_ROOT" <<'PY'
import sys

path, repo_root = sys.argv[1], sys.argv[2]
text = open(path).read()

# 1. add utopia_ui as a direct path dep, right after the first "dependencies:"
#    block's "sdk: flutter" line (flutter create always emits that pair first).
text = text.replace(
    "dependencies:\n  flutter:\n    sdk: flutter\n",
    "dependencies:\n  flutter:\n    sdk: flutter\n"
    f"  utopia_ui:\n    path: {repo_root}\n",
    1,
)

# 2. add utopia_design_tools as a dev path dep, right after the first
#    "dev_dependencies:" block's "sdk: flutter" line (flutter_test).
text = text.replace(
    "dev_dependencies:\n  flutter_test:\n    sdk: flutter\n",
    "dev_dependencies:\n  flutter_test:\n    sdk: flutter\n"
    f"  utopia_design_tools:\n    path: {repo_root}/tool/utopia_design_tools\n",
    1,
)

# 3. dependency_overrides for BOTH utopia_ui and utopia_design_tools (B8
#    friction, ledger/B.md B8 row): the tool pins a hosted utopia_ui
#    constraint pre-publish, and a root-only path dep does not propagate to
#    the tool's own resolution - consumers need overrides for both packages.
text += (
    "\ndependency_overrides:\n"
    f"  utopia_ui:\n    path: {repo_root}\n"
    f"  utopia_design_tools:\n    path: {repo_root}/tool/utopia_design_tools\n"
)

open(path, "w").write(text)
print("pubspec.yaml patched: utopia_ui path dep, utopia_design_tools dev path dep, "
      "dependency_overrides for both (B8 friction pattern)")
PY
cat "$EXT_PUBSPEC" | tee -a "$PROGRESS_LOG"

log "flutter pub get in external app"
if (cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub get) >>"$PROGRESS_LOG" 2>&1; then
  record_result "3" "flutter pub get resolves path deps + dependency_overrides (utopia_ui AND utopia_design_tools)" "PASS" "resolved"
else
  record_result "3" "flutter pub get resolves path deps + dependency_overrides (utopia_ui AND utopia_design_tools)" "FAIL" "see progress.log"
  step3_ok=false
fi

# --- bootstrap design/tokens.json via the printed copy command ---
banner "3c bootstrap design/tokens.json via the tool's printed copy command"
set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:validate_tokens) >"$WORK_DIR/bootstrap_msg.txt" 2>&1
BOOTSTRAP_EXIT=$?
set -e
cat "$WORK_DIR/bootstrap_msg.txt" | tee -a "$PROGRESS_LOG"
if [ "$BOOTSTRAP_EXIT" -eq 2 ] && grep -q "cp " "$WORK_DIR/bootstrap_msg.txt"; then
  record_result "3" "validate_tokens prints bootstrap message with copy command (exit 2, no design/tokens.json yet)" "PASS" "message contained cp command"
else
  record_result "3" "validate_tokens prints bootstrap message with copy command (exit 2, no design/tokens.json yet)" "FAIL" "exit=$BOOTSTRAP_EXIT"
  step3_ok=false
fi

mkdir -p "$EXTERNAL_APP_DIR/design"
cp "$REPO_ROOT/tokens/utopia.tokens.json" "$EXTERNAL_APP_DIR/design/tokens.json"
record_result "3" "bootstrap design/tokens.json (copy of packaged default)" "PASS" "$EXTERNAL_APP_DIR/design/tokens.json"

# --- REBRAND: x 4 -> 5 via --fix flow ---
banner "3d rebrand: x 4->5, then validate_tokens --fix, then validate clean"
python3 - "$EXTERNAL_APP_DIR/design/tokens.json" <<'PY'
import json
path = "design/tokens.json".replace("design/tokens.json", "")
import sys
p = sys.argv[0] if False else None
PY
python3 - "$EXTERNAL_APP_DIR/design/tokens.json" <<'PY'
import json, sys
path = sys.argv[1]
d = json.load(open(path))
d['x']['$value'] = 5  # bumped from 4; every derivation-carrying token is now stale
json.dump(d, open(path, 'w'), indent=2)
PY

set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:validate_tokens design/tokens.json) >"$WORK_DIR/doctor_x.txt" 2>&1
DOCTOR_EXIT=$?
set -e
cat "$WORK_DIR/doctor_x.txt" | tee -a "$PROGRESS_LOG"
if [ "$DOCTOR_EXIT" -eq 1 ] && grep -qi "derivation" "$WORK_DIR/doctor_x.txt"; then
  record_result "3" "doctor x=5 -> validate_tokens exit 1 with stale-derivation findings" "PASS" "$(grep -i derivation "$WORK_DIR/doctor_x.txt" | head -1)"
else
  record_result "3" "doctor x=5 -> validate_tokens exit 1 with stale-derivation findings" "FAIL" "exit=$DOCTOR_EXIT"
  step3_ok=false
fi

set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:validate_tokens design/tokens.json --fix) >"$WORK_DIR/fix_run.txt" 2>&1
FIX_EXIT=$?
set -e
cat "$WORK_DIR/fix_run.txt" | tee -a "$PROGRESS_LOG"
if [ "$FIX_EXIT" -eq 0 ]; then
  record_result "3" "validate_tokens --fix re-derives x=5 values, exits 0" "PASS" "$(head -3 "$WORK_DIR/fix_run.txt" | tr '\n' ' ')"
else
  record_result "3" "validate_tokens --fix re-derives x=5 values, exits 0" "FAIL" "exit=$FIX_EXIT"
  step3_ok=false
fi

set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:validate_tokens design/tokens.json) >"$WORK_DIR/post_fix_validate.txt" 2>&1
POST_FIX_EXIT=$?
set -e
if [ "$POST_FIX_EXIT" -eq 0 ]; then
  record_result "3" "post-fix validate_tokens clean (0 errors)" "PASS" "$(cat "$WORK_DIR/post_fix_validate.txt")"
else
  record_result "3" "post-fix validate_tokens clean (0 errors)" "FAIL" "exit=$POST_FIX_EXIT out=$(cat "$WORK_DIR/post_fix_validate.txt")"
  step3_ok=false
fi

# --- rebrand colors: primary + accent to a visibly different hue family (#e91e63) ---
banner "3e rebrand colors: primary + accent -> #e91e63 family, hex/components coherent"
python3 - "$EXTERNAL_APP_DIR/design/tokens.json" <<'PY'
import json, sys

path = sys.argv[1]
d = json.load(open(path))

def set_color(node, hex_str):
    hex_str = hex_str.lstrip('#')
    r = int(hex_str[0:2], 16) / 255.0
    g = int(hex_str[2:4], 16) / 255.0
    b = int(hex_str[4:6], 16) / 255.0
    node['$value']['components'] = [round(r, 6), round(g, 6), round(b, 6)]
    node['$value']['hex'] = '#' + hex_str.lower()

set_color(d['color']['primary'], '#e91e63')
set_color(d['color']['accent'], '#c2185b')

json.dump(d, open(path, 'w'), indent=2)
print('color.primary -> #e91e63, color.accent -> #c2185b (components recomputed)')
PY

set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:validate_tokens design/tokens.json) >"$WORK_DIR/post_rebrand_validate.txt" 2>&1
POST_REBRAND_EXIT=$?
set -e
cat "$WORK_DIR/post_rebrand_validate.txt" | tee -a "$PROGRESS_LOG"
if [ "$POST_REBRAND_EXIT" -eq 0 ]; then
  record_result "3" "rebrand color.primary/accent to #e91e63 family, validate_tokens clean" "PASS" "0 errors"
else
  record_result "3" "rebrand color.primary/accent to #e91e63 family, validate_tokens clean" "FAIL" "exit=$POST_REBRAND_EXIT out=$(cat "$WORK_DIR/post_rebrand_validate.txt")"
  step3_ok=false
fi

# --- generate_theme ---
banner "3f generate_theme into the external app"
set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:generate_theme design/tokens.json) >"$WORK_DIR/generate_theme_run.txt" 2>&1
GEN_THEME_EXIT=$?
set -e
cat "$WORK_DIR/generate_theme_run.txt" | tee -a "$PROGRESS_LOG"
if [ "$GEN_THEME_EXIT" -eq 0 ] && [ -f "$EXTERNAL_APP_DIR/lib/theme/utopia_theme.g.dart" ]; then
  record_result "3" "generate_theme writes lib/theme/utopia_theme.g.dart in external app" "PASS" "$EXTERNAL_APP_DIR/lib/theme/utopia_theme.g.dart"
else
  record_result "3" "generate_theme writes lib/theme/utopia_theme.g.dart in external app" "FAIL" "exit=$GEN_THEME_EXIT"
  step3_ok=false
fi

# --- WIRE buildUtopiaTheme() into a minimal main.dart with UtopiaButton + UtopiaCard + UtopiaTextField ---
banner "3g wire buildUtopiaTheme() into main.dart (rendering UtopiaButton + UtopiaCard + UtopiaTextField)"
cat > "$EXTERNAL_APP_DIR/lib/main.dart" <<'DART'
import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

import 'theme/utopia_theme.g.dart';

void main() => runApp(const RebrandSmokeApp());

class RebrandSmokeApp extends StatelessWidget {
  const RebrandSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A7 rebrand smoke',
      debugShowCheckedModeBanner: false,
      home: UtopiaTheme(
        data: buildUtopiaTheme(),
        child: const _SmokeScreen(),
      ),
    );
  }
}

class _SmokeScreen extends StatelessWidget {
  const _SmokeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: UtopiaCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('A7 rebrand smoke', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  UtopiaTextField(value: '', onChanged: (_) {}, hint: const Text('Type something')),
                  const SizedBox(height: 16),
                  UtopiaButton(onTap: () {}, child: const Text('Primary action')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DART
record_result "3" "main.dart wired with UtopiaTheme(data: buildUtopiaTheme()) wrapping UtopiaButton/UtopiaCard/UtopiaTextField" "PASS" "$EXTERNAL_APP_DIR/lib/main.dart"

log "flutter build web (wired / rebranded)"
if (cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" build web) >>"$PROGRESS_LOG" 2>&1; then
  record_result "3" "flutter build web (rebranded, wired)" "PASS" "$EXTERNAL_APP_DIR/build/web"
else
  record_result "3" "flutter build web (rebranded, wired)" "FAIL" "see progress.log"
  step3_ok=false
fi

REBRAND_PNG="$ARTIFACTS_DIR/external-app-rebranded.png"
if serve_and_screenshot "$EXTERNAL_APP_DIR/build/web" 8743 "$REBRAND_PNG" "rebranded wired app"; then
  record_result "3" "screenshot rebranded+wired app (headless Chrome)" "PASS" "$REBRAND_PNG"
else
  record_result "3" "screenshot rebranded+wired app (headless Chrome)" "FAIL" "server/screenshot failed, see $WORK_DIR/chrome-8743.log"
  step3_ok=false
fi

# --- save a copy of the wired main.dart before overwriting for the control build ---
cp "$EXTERNAL_APP_DIR/lib/main.dart" "$WORK_DIR/main.wired.dart"

# --- ALSO build once WITHOUT the UtopiaTheme wrapper (documented silent-fallback trap) ---
banner "3h control build WITHOUT UtopiaTheme wiring -> defaultTheme colors (silent-fallback trap)"
cat > "$EXTERNAL_APP_DIR/lib/main.dart" <<'DART'
import 'package:flutter/material.dart';
import 'package:utopia_ui/utopia_ui.dart';

void main() => runApp(const UnwiredSmokeApp());

class UnwiredSmokeApp extends StatelessWidget {
  const UnwiredSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Deliberately NOT wrapped in UtopiaTheme(data: buildUtopiaTheme()) - this
    // is the documented silent-fallback trap: components still render, using
    // UtopiaThemeData.defaultTheme instead of the rebrand.
    return const MaterialApp(
      title: 'A7 unwired control',
      debugShowCheckedModeBanner: false,
      home: _SmokeScreen(),
    );
  }
}

class _SmokeScreen extends StatelessWidget {
  const _SmokeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: UtopiaCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('A7 unwired control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  UtopiaTextField(value: '', onChanged: (_) {}, hint: const Text('Type something')),
                  const SizedBox(height: 16),
                  UtopiaButton(onTap: () {}, child: const Text('Primary action')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DART

log "flutter build web (unwired control)"
if (cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" build web) >>"$PROGRESS_LOG" 2>&1; then
  record_result "3" "flutter build web (unwired control, no UtopiaTheme)" "PASS" "$EXTERNAL_APP_DIR/build/web"
else
  record_result "3" "flutter build web (unwired control, no UtopiaTheme)" "FAIL" "see progress.log"
  step3_ok=false
fi

UNWIRED_PNG="$ARTIFACTS_DIR/external-app-unwired-default-fallback.png"
if serve_and_screenshot "$EXTERNAL_APP_DIR/build/web" 8744 "$UNWIRED_PNG" "unwired control app"; then
  record_result "3" "screenshot unwired control app (silent-fallback trap, headless Chrome)" "PASS" "$UNWIRED_PNG"
else
  record_result "3" "screenshot unwired control app (silent-fallback trap, headless Chrome)" "FAIL" "server/screenshot failed, see $WORK_DIR/chrome-8744.log"
  step3_ok=false
fi

# restore the wired main.dart so the app directory reflects the rebranded, wired state
cp "$WORK_DIR/main.wired.dart" "$EXTERNAL_APP_DIR/lib/main.dart"

# --- generate_twin into the app (design surface regenerated with rebrand) ---
banner "3i generate_twin into the external app (rebranded design surface)"
set +e
(cd "$EXTERNAL_APP_DIR" && "$FLUTTER_BIN" pub run utopia_design_tools:generate_twin design/tokens.json -o twin) >"$WORK_DIR/generate_twin_app_run.txt" 2>&1
GEN_TWIN_APP_EXIT=$?
set -e
cat "$WORK_DIR/generate_twin_app_run.txt" | tee -a "$PROGRESS_LOG"
if [ "$GEN_TWIN_APP_EXIT" -eq 0 ] && [ -f "$EXTERNAL_APP_DIR/twin/tokens.css" ]; then
  record_result "3" "generate_twin into external app (rebranded twin/tokens.css)" "PASS" "$EXTERNAL_APP_DIR/twin/tokens.css"
else
  record_result "3" "generate_twin into external app (rebranded twin/tokens.css)" "FAIL" "exit=$GEN_TWIN_APP_EXIT"
  step3_ok=false
fi

if $step3_ok; then STEP3_STATUS="PASS"; else STEP3_STATUS="FAIL"; fi
log "STEP 3 overall: $STEP3_STATUS"

# ===========================================================================
# STEP 4: TWIN VS FLUTTER HERO SIDE-BY-SIDES (checklist item 5)
# ===========================================================================
banner "STEP 4: twin vs flutter hero side-by-sides"

step4_ok=true

# --- hero-twin-default.png: twin/gallery.html (default theme) ---
banner "4a hero-twin-default.png"
HERO_TWIN_DEFAULT="$ARTIFACTS_DIR/hero-twin-default.png"
if serve_and_screenshot "$REPO_ROOT/twin" 8745 "$HERO_TWIN_DEFAULT" "twin gallery default" "/gallery.html"; then
  record_result "5" "hero-twin-default.png (twin/gallery.html, default theme)" "PASS" "$HERO_TWIN_DEFAULT"
else
  record_result "5" "hero-twin-default.png (twin/gallery.html, default theme)" "FAIL" "see $WORK_DIR/chrome-8745.log"
  step4_ok=false
fi

# --- hero-flutter-default.png: example app web build (dashboard route is the default) ---
banner "4b hero-flutter-default.png"
HERO_FLUTTER_DEFAULT="$ARTIFACTS_DIR/hero-flutter-default.png"
EXAMPLE_WEB_DIR="$REPO_ROOT/example/build/web"
if [ ! -d "$EXAMPLE_WEB_DIR" ]; then
  log "example/build/web missing, building it (read-only exercise of the existing example app, not a source edit)"
  (cd "$REPO_ROOT/example" && "$FLUTTER_BIN" build web) >>"$PROGRESS_LOG" 2>&1 || true
fi
if [ -d "$EXAMPLE_WEB_DIR" ] && serve_and_screenshot "$EXAMPLE_WEB_DIR" 8746 "$HERO_FLUTTER_DEFAULT" "example app dashboard"; then
  record_result "5" "hero-flutter-default.png (example/build/web dashboard route, default theme)" "PASS" "$HERO_FLUTTER_DEFAULT"
else
  record_result "5" "hero-flutter-default.png (example/build/web dashboard route, default theme)" "FAIL" "see $WORK_DIR/chrome-8746.log"
  step4_ok=false
fi

# --- hero-twin-rebrand.png: generate_twin from the rebranded external-app
# tokens into a scratch twin dir, copy twin/*.html + components.css next to
# it, screenshot gallery.html ---
banner "4c hero-twin-rebrand.png"
rm -rf "$TWIN_REBRAND_DIR"
mkdir -p "$TWIN_REBRAND_DIR"
run_dart generate_twin.dart "$EXTERNAL_APP_DIR/design/tokens.json" -o "$TWIN_REBRAND_DIR"
GEN_TWIN_REBRAND_EXIT=$LAST_EXIT
cp "$REPO_ROOT/twin/gallery.html" "$TWIN_REBRAND_DIR/gallery.html"
cp "$REPO_ROOT/twin/components.html" "$TWIN_REBRAND_DIR/components.html"
cp "$REPO_ROOT/twin/components.css" "$TWIN_REBRAND_DIR/components.css"

HERO_TWIN_REBRAND="$ARTIFACTS_DIR/hero-twin-rebrand.png"
if [ "$GEN_TWIN_REBRAND_EXIT" -eq 0 ] && serve_and_screenshot "$TWIN_REBRAND_DIR" 8747 "$HERO_TWIN_REBRAND" "twin gallery rebrand" "/gallery.html"; then
  record_result "5" "hero-twin-rebrand.png (regenerated twin css from rebranded external-app tokens)" "PASS" "$HERO_TWIN_REBRAND"
else
  record_result "5" "hero-twin-rebrand.png (regenerated twin css from rebranded external-app tokens)" "FAIL" "gen_exit=$GEN_TWIN_REBRAND_EXIT, see $WORK_DIR/chrome-8747.log"
  step4_ok=false
fi

if $step4_ok; then STEP4_STATUS="PASS"; else STEP4_STATUS="FAIL"; fi
log "STEP 4 overall: $STEP4_STATUS"

# ===========================================================================
# STEP CUSTOM: custom-component loop (A11, deferred from A7 checklist item 4)
# ===========================================================================
banner "STEP CUSTOM: custom-component loop (generate_manifest --project + merged freshness gate)"

step_custom_ok=true

# Work on a throwaway copy of the fixture consumer project, not the repo
# checkout: this harness only writes into scratch/artifacts.
FIXTURE_SRC="$TOOL_DIR/test/fixtures/project_consumer"
FIXTURE_SMOKE_DIR="$WORK_DIR/project_consumer_smoke"
rm -rf "$FIXTURE_SMOKE_DIR"
mkdir -p "$FIXTURE_SMOKE_DIR"
cp -R "$FIXTURE_SRC/." "$FIXTURE_SMOKE_DIR/"
rm -rf "$FIXTURE_SMOKE_DIR/design/project.manifest.json" "$FIXTURE_SMOKE_DIR/design/merged.manifest.json"

banner "CUSTOMa generate_manifest --project against the fixture consumer -> exit 0, both files written"
run_dart generate_manifest.dart --project --project-dir "$FIXTURE_SMOKE_DIR"
if assert_exit 0 "$LAST_EXIT" "generate_manifest --project on fixture consumer" \
  && [ -f "$FIXTURE_SMOKE_DIR/design/project.manifest.json" ] \
  && [ -f "$FIXTURE_SMOKE_DIR/design/merged.manifest.json" ]; then
  record_result "4" "generate_manifest --project on the fixture consumer writes both manifests" "PASS" "$LAST_STDOUT"
else
  record_result "4" "generate_manifest --project on the fixture consumer writes both manifests" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT stderr=$LAST_STDERR"
  step_custom_ok=false
fi

banner "CUSTOMb validate_manifest on the merged view -> exit 0"
run_dart validate_manifest.dart "$FIXTURE_SMOKE_DIR/design/merged.manifest.json" --sources "$REPO_ROOT" --project-dir "$FIXTURE_SMOKE_DIR"
if assert_exit 0 "$LAST_EXIT" "validate_manifest clean on merged fixture view"; then
  record_result "4" "validate_manifest exit 0 on the fixture's merged.manifest.json" "PASS" "0 error(s)"
else
  record_result "4" "validate_manifest exit 0 on the fixture's merged.manifest.json" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT"
  step_custom_ok=false
fi

banner "CUSTOMc doctor utopiaUiVersion in the merged view -> validate_manifest exit 1 (freshness gate fires)"
DOCTORED_MERGED="$WORK_DIR/doctored-merged.json"
python3 - "$FIXTURE_SMOKE_DIR/design/merged.manifest.json" "$DOCTORED_MERGED" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
d = json.load(open(src))
d["utopiaUiVersion"] = "0.0.1-doctored"  # SPEC 3.8 freshness gate: must equal the resolved utopia_ui version
json.dump(d, open(dst, "w"), indent=2)
PY
run_dart validate_manifest.dart "$DOCTORED_MERGED" --sources "$REPO_ROOT" --project-dir "$FIXTURE_SMOKE_DIR"
if assert_exit 1 "$LAST_EXIT" "validate_manifest doctored utopiaUiVersion" && printf '%s' "$LAST_STDOUT" | grep -qi "stale merged view"; then
  record_result "4" "validate_manifest exit 1 on doctored utopiaUiVersion (freshness gate)" "PASS" "$(printf '%s' "$LAST_STDOUT" | grep -i 'stale merged view' | head -1)"
else
  record_result "4" "validate_manifest exit 1 on doctored utopiaUiVersion (freshness gate)" "FAIL" "exit=$LAST_EXIT out=$LAST_STDOUT"
  step_custom_ok=false
fi

banner "CUSTOMd determinism: generate_manifest --project rerun is byte-identical"
CUSTOM_PROJECT_RUN1="$FIXTURE_SMOKE_DIR/design/project.manifest.json"
CUSTOM_MERGED_RUN1="$WORK_DIR/custom_merged_run1.json"
CUSTOM_MERGED_RUN2="$WORK_DIR/custom_merged_run2.json"
cp "$FIXTURE_SMOKE_DIR/design/merged.manifest.json" "$CUSTOM_MERGED_RUN1"
cp "$CUSTOM_PROJECT_RUN1" "$WORK_DIR/custom_project_run1.json"
run_dart generate_manifest.dart --project --project-dir "$FIXTURE_SMOKE_DIR"
RERUN_EXIT=$LAST_EXIT
cp "$FIXTURE_SMOKE_DIR/design/merged.manifest.json" "$CUSTOM_MERGED_RUN2"
if assert_exit 0 "$RERUN_EXIT" "generate_manifest --project rerun" \
  && diff -q "$WORK_DIR/custom_project_run1.json" "$FIXTURE_SMOKE_DIR/design/project.manifest.json" >/dev/null 2>&1 \
  && diff -q "$CUSTOM_MERGED_RUN1" "$CUSTOM_MERGED_RUN2" >/dev/null 2>&1; then
  record_result "4" "generate_manifest --project two runs are byte-identical (determinism)" "PASS" "project.manifest.json and merged.manifest.json unchanged across reruns"
else
  record_result "4" "generate_manifest --project two runs are byte-identical (determinism)" "FAIL" "rerun_exit=$RERUN_EXIT, diff found"
  step_custom_ok=false
fi

if $step_custom_ok; then STEP_CUSTOM_STATUS="PASS"; else STEP_CUSTOM_STATUS="FAIL"; fi
log "STEP CUSTOM overall: $STEP_CUSTOM_STATUS"

# ===========================================================================
# STEP 5: write ledger/checkpoints/A7.md (checklist item 8)
# ===========================================================================
banner "STEP 5: writing ledger/checkpoints/A7.md"

A7_MD="$REPO_ROOT/ledger/checkpoints/A7.md"
python3 "$TOOL_DIR/smoke/render_report.py" \
  --results "$RESULTS_TSV" \
  --findings "$FINDINGS_LOG" \
  --step1 "$STEP1_STATUS" --step2 "$STEP2_STATUS" --step3 "$STEP3_STATUS" --step4 "$STEP4_STATUS" \
  --step-custom "$STEP_CUSTOM_STATUS" \
  --artifacts-dir "$ARTIFACTS_DIR" \
  --out "$A7_MD"

log "wrote $A7_MD"
log "A7 smoke harness finished. step1=$STEP1_STATUS step2=$STEP2_STATUS step3=$STEP3_STATUS step4=$STEP4_STATUS step_custom=$STEP_CUSTOM_STATUS"

overall_ok=true
[ "$STEP1_STATUS" = "PASS" ] || overall_ok=false
[ "$STEP2_STATUS" = "PASS" ] || overall_ok=false
[ "$STEP3_STATUS" = "PASS" ] || overall_ok=false
[ "$STEP4_STATUS" = "PASS" ] || overall_ok=false
[ "$STEP_CUSTOM_STATUS" = "PASS" ] || overall_ok=false

if $overall_ok; then
  log "ALL STEPS PASS"
  exit 0
else
  log "ONE OR MORE STEPS FAILED - see $A7_MD and $FINDINGS_LOG"
  exit 1
fi
