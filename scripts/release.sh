#!/usr/bin/env bash
# release.sh — merge main into release/stage, optionally bumping the app version.
#
# The version in pubspec.yaml follows X.Y.Z where:
#   X = breaking   Y = major   Z = minor
# A bump increments the chosen position and resets every lower one to 0.
# Any "+build" suffix (e.g. 1.1.0+5) is preserved untouched.
#
# The bump is committed on main first, then main is merged into release/stage,
# so both branches share the same version-bump commit.
#
# Both branches are fast-forward pulled from origin before any work, so the
# merge always runs against up-to-date branches. Pass --no-pull to skip.
#
# Usage:
#   ./scripts/release.sh                 # pull, then merge main -> release/stage
#   ./scripts/release.sh --minor         # 1.1.0 -> 1.1.1, then merge
#   ./scripts/release.sh --major         # 1.1.0 -> 1.2.0, then merge
#   ./scripts/release.sh --breaking      # 1.1.0 -> 2.0.0, then merge
#   ./scripts/release.sh --minor --push  # also push main and release/stage
#   ./scripts/release.sh --major --dry-run
#   ./scripts/release.sh --no-pull       # merge local branches as-is
#
# Works from any directory: it resolves the repo root from its own location.
set -euo pipefail

# --- resolve the main repo root from the script's own location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$MAIN_ROOT"

SRC_BRANCH="main"
DST_BRANCH="release/stage"
PUBSPEC="pubspec.yaml"

info() { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

# --- parse args ---
bump=""        # breaking | major | minor | ""
push=0
dry_run=0
pull=1
for arg in "$@"; do
  case "$arg" in
    --breaking|-b) [ -z "$bump" ] || die "Pick only one bump flag."; bump="breaking" ;;
    --major|-m)    [ -z "$bump" ] || die "Pick only one bump flag."; bump="major" ;;
    --minor|-n)    [ -z "$bump" ] || die "Pick only one bump flag."; bump="minor" ;;
    --push)        push=1 ;;
    --dry-run)     dry_run=1 ;;
    --no-pull)     pull=0 ;;
    -h|--help)     usage 0 ;;
    *)             die "Unknown argument: $arg (try --help)" ;;
  esac
done

command -v git >/dev/null || die "git not on PATH"

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf '\033[90m[dry-run] %s\033[0m\n' "$*"
  else
    "$@"
  fi
}

# --- safety: clean tree, known branches ---
[ -z "$(git status --porcelain)" ] || die "Working tree is dirty — commit or stash first."
git show-ref --verify --quiet "refs/heads/$SRC_BRANCH" || die "Branch '$SRC_BRANCH' not found locally."
git show-ref --verify --quiet "refs/heads/$DST_BRANCH" || die "Branch '$DST_BRANCH' not found locally."

start_branch="$(git rev-parse --abbrev-ref HEAD)"
restore_branch() { git checkout --quiet "$start_branch" 2>/dev/null || true; }
trap restore_branch EXIT

# --- get the bump commit onto main (if requested) ---
info "Switching to $SRC_BRANCH ..."
run git checkout "$SRC_BRANCH"
if [ "$pull" -eq 1 ]; then
  info "Pulling $SRC_BRANCH ..."
  run git pull --ff-only origin "$SRC_BRANCH"
fi

if [ -n "$bump" ]; then
  # Read current version: capture the X.Y.Z core and any +build suffix.
  line="$(grep -E '^version:' "$PUBSPEC" | head -n1)"
  [ -n "$line" ] || die "No 'version:' line in $PUBSPEC"
  current="$(printf '%s' "$line" | sed -E 's/^version:[[:space:]]*//')"
  core="${current%%+*}"
  build=""
  [ "$current" != "$core" ] && build="+${current#*+}"

  IFS='.' read -r x y z <<<"$core"
  [[ "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ && "$z" =~ ^[0-9]+$ ]] \
    || die "Version '$core' is not X.Y.Z numeric — bump aborted."

  case "$bump" in
    breaking) x=$((x + 1)); y=0; z=0 ;;
    major)    y=$((y + 1)); z=0 ;;
    minor)    z=$((z + 1)) ;;
  esac
  new="${x}.${y}.${z}${build}"

  info "Version bump (${bump}): $current -> $new"
  if [ "$dry_run" -eq 1 ]; then
    printf '\033[90m[dry-run] set %s version: %s\033[0m\n' "$PUBSPEC" "$new"
  else
    # Replace only the first version: line, preserving the rest of the file.
    tmp="$(mktemp)"
    awk -v new="version: $new" 'BEGIN{done=0} /^version:/ && !done {print new; done=1; next} {print}' \
      "$PUBSPEC" >"$tmp" && mv "$tmp" "$PUBSPEC"
  fi
  run git add "$PUBSPEC"
  run git commit -m "chore: bump version to $new"
fi

# --- merge main into release/stage ---
info "Switching to $DST_BRANCH ..."
run git checkout "$DST_BRANCH"
if [ "$pull" -eq 1 ]; then
  info "Pulling $DST_BRANCH ..."
  run git pull --ff-only origin "$DST_BRANCH"
fi
info "Merging $SRC_BRANCH into $DST_BRANCH ..."
run git merge --no-ff "$SRC_BRANCH" -m "merge: $SRC_BRANCH into $DST_BRANCH"

# --- push (opt-in) ---
if [ "$push" -eq 1 ]; then
  if [ -n "$bump" ]; then
    info "Pushing $SRC_BRANCH ..."
    run git push origin "$SRC_BRANCH"
  fi
  info "Pushing $DST_BRANCH ..."
  run git push origin "$DST_BRANCH"
else
  warn "Not pushing (pass --push to push $DST_BRANCH${bump:+ and $SRC_BRANCH})."
fi

info "Done."
