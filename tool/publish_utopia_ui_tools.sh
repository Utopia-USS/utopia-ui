#!/usr/bin/env bash
# Publishes utopia_ui_tools from a staging copy outside this repo.
#
# pub applies every ignore file from the git root down, so the root .pubignore
# entry that keeps tool/ out of the utopia_ui tarball also hides this nested
# package from its own publish ("The pubspec is hidden"). A copy outside the
# repo has no ancestor ignore files.
#
# Usage, from anywhere:
#   tool/publish_utopia_ui_tools.sh --dry-run
#   tool/publish_utopia_ui_tools.sh
#
# The copy never carries the dev-time dependency_overrides block. A real
# publish therefore resolves utopia_ui from pub.dev: publish utopia_ui first
# (RELEASING.md step e). --dry-run points a pubspec_overrides.yaml at this
# checkout instead, so it also works before utopia_ui is live (pub reports
# that as a hint, not a warning).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo/tool/utopia_ui_tools"
stage="$(mktemp -d)/utopia_ui_tools"
trap 'rm -rf "$(dirname "$stage")"' EXIT
mkdir -p "$stage"

# Tracked plus untracked-but-not-ignored files: no build/, .dart_tool/ or lockfile.
(cd "$src" && git ls-files -co --exclude-standard -z) |
  rsync -a --from0 --files-from=- "$src/" "$stage/"

# Drop the dependency_overrides block (key line through its indented body).
awk '
  /^dependency_overrides:/ { skip = 1; next }
  skip && /^[^[:space:]#]/ { skip = 0 }
  !skip
' "$src/pubspec.yaml" > "$stage/pubspec.yaml"

for arg in "$@"; do
  if [ "$arg" = "--dry-run" ] || [ "$arg" = "-n" ]; then
    printf 'dependency_overrides:\n  utopia_ui:\n    path: %s\n' "$repo" > "$stage/pubspec_overrides.yaml"
  fi
done

cd "$stage"
flutter pub publish "$@"
