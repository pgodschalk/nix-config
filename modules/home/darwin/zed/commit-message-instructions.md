Follow the commit-message convention in the project rules above, if they give
one: it wins over every rule below.

When the project rules give no convention, write a Conventional Commits message:

- First line: `type: subject`, or `type(scope): subject`.
- Allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert,
  style, test.
- Do not start the subject with a capital letter.

Unless that convention says otherwise:

- The whole first line must be 50 characters or fewer.
- Do not end the subject with a full stop.
- If there is a body, leave one blank line after the subject and wrap every body
  line at 72 characters or fewer.
- Describe why the change was made, not a file-by-file list.
