---
name: triage-labels
description:
  The label strings behind the five triage roles the engineering skills use.
---

# Triage labels

The skills speak in terms of five canonical triage roles. This file maps those
roles to the label strings used in this repository's GitHub issues. Here the two
are identical.

| Role in the skills | Label here        | Meaning                           |
| ------------------ | ----------------- | --------------------------------- |
| `needs-triage`     | `needs-triage`    | Maintainer has yet to evaluate it |
| `needs-info`       | `needs-info`      | Waiting on the reporter           |
| `ready-for-agent`  | `ready-for-agent` | Specified enough for an AFK agent |
| `ready-for-human`  | `ready-for-human` | Needs a human to implement it     |
| `wontfix`          | `wontfix`         | Will not be actioned              |

When a skill names a role, such as "apply the AFK-ready triage label", use the
label in the middle column. Edit that column if the vocabulary changes, and
`.github/labels.yml`, which creates the labels on GitHub.
