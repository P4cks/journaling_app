#!/usr/bin/env bash
# qa.sh — pick an open PR and launch it for manual QA via `flutter run`.
#
# Reuses the PR's existing Claude worktree (under .claude/worktrees), and
# auto-creates one if the PR has no local worktree yet. Closes any running
# simulators first, prefers a cabled iPhone, and otherwise boots the iPhone
# simulator. When more than one suitable device is present it lets
# `flutter run` prompt you to choose.
#
# Usage:
#   ./scripts/qa.sh            # interactive PR menu
#   ./scripts/qa.sh 38         # launch PR #38 directly
#
# Works from any directory: it resolves the repo root from its own location,
# so it is safe to expose as a shell alias.
set -euo pipefail

# --- resolve the main repo root from the script's own location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$MAIN_ROOT"

PREFERRED_SIM="iPhone 16e"

info() { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v flutter >/dev/null || die "flutter not on PATH"
command -v gh      >/dev/null || die "gh not on PATH (brew install gh)"
command -v jq      >/dev/null || die "jq not on PATH (brew install jq)"

# Path of the worktree that has <branch> checked out, or empty.
worktree_for_branch() {
  git worktree list --porcelain | awk -v b="refs/heads/$1" '
    /^worktree /{p=substr($0, 10)}
    $0=="branch "b{print p; exit}'
}

# --- gather open PRs ---
prs_json="$(gh pr list --state open --json number,title,headRefName)"
[ "$(jq 'length' <<<"$prs_json")" -gt 0 ] || die "No open PRs found."

# --- pick a PR (arg wins; otherwise interactive menu) ---
choice="${1:-}"
if [ -z "$choice" ]; then
  echo "Open PRs:"
  while IFS=$'\t' read -r num br title; do
    mark=" "; [ -n "$(worktree_for_branch "$br")" ] && mark="*"
    printf "  %s #%-4s %s\n" "$mark" "$num" "$title"
  done < <(jq -r '.[] | "\(.number)\t\(.headRefName)\t\(.title)"' <<<"$prs_json")
  echo "  (* = worktree already on disk)"
  printf "Enter PR number: "
  read -r choice </dev/tty
fi
[ -n "$choice" ] || die "No PR selected."

branch="$(jq -r --arg n "$choice" '.[] | select(.number == ($n|tonumber)) | .headRefName' <<<"$prs_json")"
[ -n "$branch" ] || die "PR #$choice is not in the open list."
title="$(jq -r --arg n "$choice" '.[] | select(.number == ($n|tonumber)) | .title' <<<"$prs_json")"

# --- resolve (or create) the worktree for this PR ---
wt="$(worktree_for_branch "$branch")"
if [ -z "$wt" ]; then
  info "No worktree for $branch — creating one…"
  git fetch origin "$branch" >/dev/null 2>&1 || warn "fetch of origin/$branch failed; trying with local refs"
  wt="$MAIN_ROOT/.claude/worktrees/$(basename "$branch")"
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt" "$branch"
  else
    git worktree add --track -b "$branch" "$wt" "origin/$branch"
  fi
fi
[ -d "$wt" ] || die "Worktree path does not exist: $wt"

info "PR #$choice — $title"
info "Worktree: $wt"
cd "$wt"

# --- dependencies (only when stale/missing) ---
if [ ! -f .dart_tool/package_config.json ] || [ pubspec.yaml -nt .dart_tool/package_config.json ]; then
  info "Running flutter pub get…"
  flutter pub get
fi

# --- detect a cabled iPhone BEFORE touching simulators ---
devices_json="$(flutter devices --machine 2>/dev/null || echo '[]')"
phys="$(jq -r '.[] | select(.targetPlatform=="ios" and .emulator==false) | .id' <<<"$devices_json")"
phys_count="$(printf '%s' "$phys" | grep -c . || true)"
first_phys="$(printf '%s\n' "$phys" | head -n1)"

# --- close any running simulators first (per request) ---
if xcrun simctl list devices booted 2>/dev/null | grep -q "(Booted)"; then
  info "Shutting down running simulators…"
  xcrun simctl shutdown all || true
fi

launch() { info "Launching: flutter run $*"; exec flutter run "$@"; }

if [ "$phys_count" -gt 1 ]; then
  info "Multiple cabled iOS devices — flutter run will ask you to choose."
  launch
elif [ "$phys_count" -eq 1 ]; then
  info "Using cabled iPhone ($first_phys)."
  launch -d "$first_phys"
else
  info "No cabled iPhone — booting the simulator."
  sim_id="$(xcrun simctl list devices available -j | jq -r --arg n "$PREFERRED_SIM" '[.devices[][] | select(.name==$n)][0].udid // empty')"
  [ -n "$sim_id" ] || sim_id="$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name|startswith("iPhone"))][0].udid // empty')"
  [ -n "$sim_id" ] || die "No iPhone simulator available."
  xcrun simctl boot "$sim_id" >/dev/null 2>&1 || true
  open -a Simulator
  launch -d "$sim_id"
fi
