---
description: Checkout an open PR's Claude worktree and launch flutter run for manual QA
argument-hint: "[pr-number]"
allowed-tools: Bash(gh pr list:*), Bash(git rev-parse:*), Bash(osascript:*), AskUserQuestion
---

Launch an open PR for manual QA in a **new Terminal window** (so `flutter run`
stays interactive — hot reload with `r`, quit with `q` — independent of this
Claude session).

Steps:

1. Resolve the repo root: `ROOT="$(git rev-parse --show-toplevel)"`. If the
   current directory is a worktree, use the main repo instead:
   `ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`.

2. Determine the PR number:
   - If `$ARGUMENTS` contains a number, use it.
   - Otherwise run `gh pr list --state open --json number,title,headRefName --jq '.[] | "#\(.number) \(.title)"'`
     and use AskUserQuestion to let the user pick one.

3. Open a new Terminal window running the QA engine for that PR. The script
   handles worktree lookup/creation, `flutter pub get`, closing running
   simulators, and device selection:

   ```
   osascript \
     -e "tell application \"Terminal\" to do script \"cd '$ROOT' && ./scripts/qa.sh <PR_NUMBER>\"" \
     -e 'tell application "Terminal" to activate'
   ```

4. Tell the user the QA session is launching in a new Terminal window, and that
   the simulator/device will come up there. Do NOT run `flutter run` inside this
   Claude session — it is long-running and interactive, so it belongs in the
   Terminal window.
