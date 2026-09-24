---
name: issue-tracker
description:
  Where issues live for this repository and how the engineering skills read and
  write them.
---

# Issue tracker: GitHub

Issues and specs for this repository live as GitHub issues on
`pgodschalk/nix-config`. Use the `gh` CLI for every operation; it infers the
repository from `git remote -v` when run inside the clone.

## Conventions

- Create an issue: `gh issue create --title "..." --body "..."`, with a heredoc
  for a multi-line body.
- Read an issue: `gh issue view <number> --comments`, fetching labels as well.
- List issues, with `--label` and `--state` filters as needed:

  ```sh
  gh issue list --state open \
    --json number,title,body,labels,comments \
    --jq '[.[] | {number, title, body,
      labels: [.labels[].name], comments: [.comments[].body]}]'
  ```

- Comment: `gh issue comment <number> --body "..."`.
- Apply or remove labels: `gh issue edit <number> --add-label "..."` or
  `--remove-label "..."`.
- Close: `gh issue close <number> --comment "..."`.

## Pull requests as a triage surface

**PRs as a request surface: no.** Set to `yes` if this repository treats
external PRs as feature requests; `/triage` reads this flag.

When set to `yes`, PRs run through the same labels and states as issues, using
the `gh pr` equivalents:

- Read a PR: `gh pr view <number> --comments`, and `gh pr diff <number>` for the
  diff.
- List external PRs for triage, keeping only an `authorAssociation` of
  `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR` or `NONE`:

  ```sh
  gh pr list --state open \
    --json number,title,body,labels,author,authorAssociation,comments
  ```

- Comment, label, close: `gh pr comment`, `gh pr edit --add-label` or
  `--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be
either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The map is a single issue with child issues as tickets.

- Map: one issue labelled `wayfinder:map`, holding the Notes, Decisions-so-far
  and Fog body. `gh issue create --label wayfinder:map`.
- Child ticket: an issue linked to the map as a GitHub sub-issue, through
  `gh api` on the sub-issues endpoint. Where sub-issues are not enabled, add the
  child to a task list in the map body and put `Part of #<map>` at the top of
  the child body. Labels: `wayfinder:<type>`, one of `research`, `prototype`,
  `grilling` or `task`. Once claimed, the ticket is assigned to the driving
  developer.
- Blocking: GitHub's native issue dependencies, the canonical and UI-visible
  representation. `<blocker-db-id>` is the blocker's numeric database id from
  `gh api repos/<owner>/<repo>/issues/<n> --jq .id`, not its `#number` or
  `node_id`:

  ```sh
  gh api --method POST \
    repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by \
    -F issue_id=<blocker-db-id>
  ```

  GitHub reports `issue_dependencies_summary.blocked_by`, counting open blockers
  only, which is the live gate. Where dependencies are not available, fall back
  to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is
  unblocked when every blocker is closed.

- Frontier query: list the map's open children (`gh issue list --state open`,
  scoped to the map's sub-issues or task list), drop any with an open blocker
  (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the
  `Blocked by` line) or an assignee; first in map order wins.
- Claim: `gh issue edit <n> --add-assignee @me`, the session's first write.
- Resolve: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`,
  then append a context pointer (gist plus link) to the map's Decisions-so-far.
