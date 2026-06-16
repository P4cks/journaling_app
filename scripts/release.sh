#!/usr/bin/env bash
# release.sh — merge main into release/stage, optionally bumping the app version
# and shipping an internal test build to the stores.
#
# Store delivery is two-sided:
#   - Apple: pushing release/stage triggers Xcode Cloud, which builds and ships
#     to TestFlight. Nothing to do here beyond --push.
#   - Google Play: there is no cloud trigger, so --play builds a signed prod AAB
#     locally and uploads it to the Play "internal testing" track via fastlane
#     (see android/fastlane/ and PLAY_RELEASE_SETUP.md for one-time setup).
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
#   ./scripts/release.sh --play          # merge, then build + upload Play internal
#   ./scripts/release.sh --minor --push --play  # full release: both stores
#   ./scripts/release.sh --major --dry-run
#   ./scripts/release.sh --no-pull       # merge local branches as-is
#
# --play builds whatever is on release/stage after the merge, signs it with the
# upload keystore (android/key.properties), and uploads to the Play internal
# track. The Android versionCode is derived from the commit count so it always
# increases without hand-editing pubspec's +build suffix.
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

# --- Play Store (--play) ---
ANDROID_DIR="$MAIN_ROOT/android"
AAB_PATH="$MAIN_ROOT/build/app/outputs/bundle/prodRelease/app-prod-release.aab"
# Service-account JSON for the Play Developer API. Override with the env var.
PLAY_SERVICE_ACCOUNT_JSON="${PLAY_SERVICE_ACCOUNT_JSON:-$ANDROID_DIR/play-service-account.json}"

info() { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  # Print the leading comment header (from line 2 until the first non-comment
  # line), stripping the leading "# ". Robust to edits in the header length.
  awk 'NR>=2 { if ($0 ~ /^#/) { sub(/^# ?/, ""); print } else { exit } }' \
    "${BASH_SOURCE[0]}"
  exit "${1:-0}"
}

# --- parse args ---
bump=""        # breaking | major | minor | ""
push=0
dry_run=0
pull=1
play=0
for arg in "$@"; do
  case "$arg" in
    --breaking|-b) [ -z "$bump" ] || die "Pick only one bump flag."; bump="breaking" ;;
    --major|-m)    [ -z "$bump" ] || die "Pick only one bump flag."; bump="major" ;;
    --minor|-n)    [ -z "$bump" ] || die "Pick only one bump flag."; bump="minor" ;;
    --push)        push=1 ;;
    --play)        play=1 ;;
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

# Resolve how to invoke fastlane: prefer bundler when android/Gemfile.lock is
# present (reproducible), else a fastlane already on PATH. Sets `fastlane_cmd`.
fastlane_cmd=()
resolve_fastlane() {
  if [ -f "$ANDROID_DIR/Gemfile.lock" ] && command -v bundle >/dev/null; then
    fastlane_cmd=(bundle exec fastlane)
  elif command -v fastlane >/dev/null; then
    fastlane_cmd=(fastlane)
  else
    die "fastlane not found. Run 'cd android && bundle install' (or 'gem install fastlane'). See PLAY_RELEASE_SETUP.md."
  fi
}

# Fail fast (before any merge/push) when --play prerequisites are missing.
preflight_play() {
  command -v flutter >/dev/null || die "flutter not on PATH — required for the Play build (--play)."
  [ -f "$ANDROID_DIR/key.properties" ] \
    || die "android/key.properties not found — the upload keystore is required to sign a Play build. See PLAY_RELEASE_SETUP.md."
  [ -f "$PLAY_SERVICE_ACCOUNT_JSON" ] \
    || die "Play service-account JSON not found at '$PLAY_SERVICE_ACCOUNT_JSON'. See PLAY_RELEASE_SETUP.md, or set PLAY_SERVICE_ACCOUNT_JSON."
  resolve_fastlane
}

# Build the signed prod AAB and upload it to the Play internal testing track.
# Runs on release/stage after the merge, so it ships the merged code.
build_and_upload_play() {
  # versionCode must strictly increase on every Play upload. Derive it from the
  # commit count rather than hand-bumping pubspec's +build suffix (which this
  # script intentionally leaves untouched), so re-uploads are never rejected.
  local build_number
  build_number="$(git rev-list --count HEAD)"

  info "Building signed Android App Bundle (prod, versionCode=$build_number) ..."
  run flutter build appbundle --flavor prod --release --build-number="$build_number"

  if [ "$dry_run" -eq 0 ] && [ ! -f "$AAB_PATH" ]; then
    die "Expected AAB not found at $AAB_PATH after build."
  fi

  info "Uploading AAB to the Play Store internal track via fastlane supply ..."
  if [ "$dry_run" -eq 1 ]; then
    printf '\033[90m[dry-run] (cd %s && PLAY_SERVICE_ACCOUNT_JSON=%s %s internal aab:%s)\033[0m\n' \
      "$ANDROID_DIR" "$PLAY_SERVICE_ACCOUNT_JSON" "${fastlane_cmd[*]}" "$AAB_PATH"
  else
    ( cd "$ANDROID_DIR" \
      && PLAY_SERVICE_ACCOUNT_JSON="$PLAY_SERVICE_ACCOUNT_JSON" \
         "${fastlane_cmd[@]}" internal aab:"$AAB_PATH" )
  fi
}

# --- safety: clean tree, known branches ---
[ -z "$(git status --porcelain)" ] || die "Working tree is dirty — commit or stash first."
git show-ref --verify --quiet "refs/heads/$SRC_BRANCH" || die "Branch '$SRC_BRANCH' not found locally."
git show-ref --verify --quiet "refs/heads/$DST_BRANCH" || die "Branch '$DST_BRANCH' not found locally."

start_branch="$(git rev-parse --abbrev-ref HEAD)"
restore_branch() { git checkout --quiet "$start_branch" 2>/dev/null || true; }
trap restore_branch EXIT

# Check Play prerequisites up front so we never merge/push and then fail at the
# build step with no way to ship Android.
[ "$play" -eq 1 ] && preflight_play

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

# --- Google Play internal test build (opt-in) ---
# Apple ships via Xcode Cloud on the push above; Android has no such trigger,
# so build + upload the AAB here. We are on $DST_BRANCH (merged code) now.
if [ "$play" -eq 1 ]; then
  build_and_upload_play
else
  warn "Not building for Play (pass --play to ship a Play internal test build)."
fi

info "Done."
