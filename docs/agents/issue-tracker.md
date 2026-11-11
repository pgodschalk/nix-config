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
- Read an issue, body and comments together:

  ```sh
  gh issue view <number> --json number,title,body,labels,comments
  ```

  Off a TTY, `gh issue view <number> --comments` prints only the comments.

- List issues, with `--label` and `--state` filters as needed:

  ```sh
  gh issue list --state open \
    --json number,title,body,labels,comments \
    --jq '[.[] | {number, title, body,
      labels: [.labels[].name], comments: [.comments[].body]}]'
  ```

- Make an issue a sub-issue of a parent: `gh issue create --parent <parent>`, or
  `gh issue edit <parent> --add-sub-issue <child>` afterwards. Where sub-issues
  are not enabled, put `Part of #<parent>` at the top of the child body.
- Blocking: GitHub's native issue dependencies, the canonical and UI-visible
  representation. Add an edge with `gh issue create --blocked-by <n>,<n>` or
  `gh issue edit <child> --add-blocked-by <blocker>`. Where dependencies are not
  available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the
  child body. A ticket is unblocked when every blocker is closed.
- Count open blockers, where 0 means startable:

  ```sh
  gh api repos/{owner}/{repo}/issues/<n> \
    --jq .issue_dependencies_summary.blocked_by
  ```

  `gh issue view <n> --json blockedBy` lists closed blockers too, so filter it
  with `--jq '[.blockedBy.nodes[] | select(.state == "OPEN")] | length'`.

- Comment: `gh issue comment <number> --body "..."`.
- Apply or remove labels: `gh issue edit <number> --add-label "..."` or
  `--remove-label "..."`.
- Close: post the explanation with `gh issue comment <number> --body "..."`,
  then `gh issue close <number>`. On an already-closed issue,
  `gh issue close --comment` drops the comment and still exits 0.

File issues only into `pgodschalk/nix-config`, never into `mattpocock/skills`,
where these skills come from. Before the first `gh issue create` of a session,
check the target with `gh repo view --json nameWithOwner`; this clone is no
fork, so any other name means a wrong clone or an `-R`, and the write waits for
Patrick to confirm it.

## Pull requests as a triage surface

**PRs as a request surface: no.** Set to `yes` if this repository treats
external PRs as feature requests; `/triage` reads this flag.

When set to `yes`, PRs run through the same labels and states as issues, using
the `gh pr` equivalents:

- Read a PR: `gh pr view <number>`, then `gh pr view <number> --comments`, which
  off a TTY prints only the comments, and `gh pr diff <number>` for the diff.
- List external PRs for triage, dropping any whose author is the owner, a member
  or a collaborator:

  ```sh
  gh api --paginate 'repos/{owner}/{repo}/pulls?state=open' \
    --jq '.[] | select(.author_association
      | IN("OWNER", "MEMBER", "COLLABORATOR") | not)
      | {number, title, author: .user.login, author_association,
        labels: [.labels[].name]}'
  ```

- Comment, label, close: `gh pr comment`, `gh pr edit --add-label` or
  `--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be
either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in Conventions under "Read an issue".

## Wayfinding operations

Used by `/wayfinder`. The map is a single issue with child issues as tickets.

- Map: one issue labelled `wayfinder:map`, holding the Notes, Decisions-so-far
  and Fog body. `gh issue create --label wayfinder:map`.
- Child ticket: an issue linked to the map as a GitHub sub-issue, created with
  `gh issue create --parent <map>` as in Conventions. Where sub-issues are not
  enabled, add the child to a task list in the map body and put `Part of #<map>`
  at the top of the child body. Labels: `wayfinder:<type>`, one of `research`,
  `prototype`, `grilling` or `task`. Once claimed, the ticket is assigned to the
  driving developer.
- Blocking: as in Conventions under "Blocking".
- Frontier query: list the map's open children (`gh issue list --state open`,
  scoped to the map's sub-issues or task list), drop any with an open blocker
  (as in Conventions under "Count open blockers", or an open issue in the
  `Blocked by` line) or an assignee; first in map order wins.
- Claim: `gh issue edit <n> --add-assignee @me`, the session's first write.
- Resolve: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`,
  then append a context pointer (gist plus link) to the map's Decisions-so-far.
