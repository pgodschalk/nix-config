"""Claude Code PreToolUse hook: git or jj, by the nearest repository root.

Handed the Bash tool's event on stdin, it exits 2 with a message on
stderr to refuse the command, and 0 to let it run:

- under a `.jj` (a colocated checkout), a git command jj has a form of
  is refused with that form;
- under a `.git` with no `.jj` of its own but one further up (an Orca
  worktree inside a jj checkout), jj is refused, because it would walk
  up and act on the enclosing checkout's working copy.

The command is parsed with tree-sitter's bash grammar. Only what it
can read with certainty is checked: a command the grammar cannot
parse, a `cd` to a variable, a `--git-dir` or anything else it cannot
resolve lets the command through, since a wrong refusal costs more
than a missed one. Git aliases are not expanded, a function's body is
checked where it is defined rather than where it is called, and a
`nu -c` string is read as bash.
"""

import codecs
import json
import os
import re
import sys
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

# ty runs in CI without the Nix Python environment the hook is built
# with, which is the only place these resolve.
import tree_sitter_bash  # ty: ignore[unresolved-import]
from tree_sitter import Language, Node, Parser  # ty: ignore[unresolved-import]

# A git subcommand jj has a form of, and that form. Anything else, such
# as worktree, check-ignore, config or ls-remote, passes.
JJ_FORMS = {
    "absorb": "jj absorb",
    "add": (
        "nothing: jj snapshots the working copy on its next command;"
        " `jj file track PATH` for an ignored file"
    ),
    "annotate": "jj file annotate",
    "bisect": "jj bisect",
    "blame": "jj file annotate",
    "branch": "jj bookmark",
    "cat-file": "jj file show -r REV PATH, or jj show REV",
    "checkout": "jj new REV, or jj edit REV; jj restore for files",
    "cherry-pick": "jj duplicate",
    "clone": "jj git clone",
    "commit": "jj commit, or jj describe and jj new",
    "diff": "jj diff",
    "diff-files": "jj diff --name-only",
    "diff-index": "jj diff --name-only, or jj status",
    "diff-tree": "jj diff -r REV --name-only",
    "difftool": "jj diff --tool TOOL",
    "fetch": "jj git fetch, or jj git fetch --remote R --branch B",
    "for-each-ref": "jj bookmark list, or jj tag list",
    "gc": "jj util gc",
    "grep": "jj file search --pattern PATTERN",
    "init": "jj git init",
    "log": "jj log",
    "ls-files": "jj file list",
    "ls-tree": "jj file list -r REV",
    "merge": "jj new A B",
    "merge-base": "jj log -r 'heads(::A & ::B)'",
    "mergetool": "jj resolve",
    "mv": "mv; jj records the rename on its next command",
    "pull": "jj git fetch, then jj rebase",
    "push": "jj git push",
    "range-diff": "jj interdiff",
    "rebase": "jj rebase",
    "reflog": "jj op log",
    "remote": "jj git remote",
    "reset": "jj restore, jj abandon or jj squash",
    "restore": "jj restore",
    "rev-list": "jj log -r 'A..B' --no-graph -T commit_id",
    "rev-parse": (
        "jj log -r REV --no-graph -T commit_id; jj root for --show-toplevel"
    ),
    "revert": "jj revert",
    "rm": "jj file untrack for --cached; otherwise rm, which jj picks up",
    "shortlog": "jj log",
    "show": "jj show; jj file show -r REV PATH for REV:PATH",
    "show-ref": "jj bookmark list, or jj tag list",
    "sparse-checkout": "jj sparse",
    "stash": "jj new: the changes stay in their own commit",
    "status": "jj status",
    "switch": "jj new REV",
    "tag": "jj tag",
    "whatchanged": "jj log -s",
}

# Flags that take a subcommand somewhere jj does not reach.
NO_JJ_FLAGS = {
    "blame": {
        "-C",
        "-L",
        "-M",
        "-e",
        "-w",
        "--ignore-rev",
        "--ignore-revs-file",
        "--line-porcelain",
        "--porcelain",
        "--reverse",
    },
    "clone": {
        "--bare",
        "--filter",
        "--mirror",
        "--recurse-submodules",
        "--sparse",
    },
    "diff": {"--check", "--exit-code", "--no-index", "--quiet"},
    "diff-files": {"--exit-code", "--quiet"},
    "diff-index": {"--exit-code", "--quiet"},
    "fetch": {
        "--deepen",
        "--depth",
        "--dry-run",
        "--filter",
        "--negotiate-only",
        "--recurse-submodules",
        "--refetch",
        "--shallow-exclude",
        "--shallow-since",
        "--unshallow",
    },
    "grep": {
        "-A",
        "-B",
        "-C",
        "--after-context",
        "--before-context",
        "--context",
        "--no-index",
    },
    "init": {"--bare"},
    "log": {"-L", "--follow"},
    "ls-files": {
        "--error-unmatch",
        "--ignored",
        "--others",
        "--stage",
        "--unmerged",
    },
    "merge-base": {"--fork-point", "--is-ancestor"},
    "rev-list": {"--objects", "--objects-edge"},
    "status": {"--ignored"},
    "tag": {
        "-F",
        "-a",
        "-m",
        "-n",
        "-s",
        "-u",
        "-v",
        "--annotate",
        "--file",
        "--local-user",
        "--message",
        "--sign",
        "--verify",
    },
}
# ls-files short flags for untracked, ignored, staged and unmerged
# files, also combined.
LS_FILES_SHORT = set("oisu")
# remote subcommands that read what jj git remote does not show.
REMOTE_NO_JJ = {"prune", "set-head", "show"}
# A fetch refspec that is not a plain branch name: jj fetches branches.
FETCH_REF = re.compile(
    r"^(?:\+|refs/|pull/|merge-requests/|tags/)|:|^HEAD$|^[0-9a-f]{7,40}$"
)
# rev-parse queries about git's own layout, which jj has no form of.
REV_PARSE_LAYOUT = (
    "--git-",
    "--is-",
    "--absolute-git-dir",
    "--show-cdup",
    "--show-prefix",
    "--show-superproject",
    "--shared-index-path",
    "--show-object-format",
    "--show-ref-format",
    "--local-env-vars",
)

# git options before the subcommand that take a value as the next word.
GIT_VALUE_OPTIONS = {"-c", "--config-env"}
# git options and variables that point it at another repository.
GIT_RETARGET_OPTIONS = ("--git-dir", "--work-tree", "--namespace")
GIT_RETARGET_VARIABLES = {
    "GIT_COMMON_DIR",
    "GIT_DIR",
    "GIT_NAMESPACE",
    "GIT_WORK_TREE",
}
CLONE_VALUE_OPTIONS = {
    "-b",
    "-c",
    "-j",
    "-o",
    "-u",
    "--branch",
    "--bundle-uri",
    "--config",
    "--depth",
    "--filter",
    "--jobs",
    "--origin",
    "--reference",
    "--reference-if-able",
    "--revision",
    "--separate-git-dir",
    "--server-option",
    "--shallow-exclude",
    "--shallow-since",
    "--template",
    "--upload-pack",
}
INIT_VALUE_OPTIONS = {
    "-b",
    "--initial-branch",
    "--object-format",
    "--ref-format",
    "--separate-git-dir",
    "--template",
}

# jj global options that take a value as the next word.
JJ_VALUE_OPTIONS = {
    "--at-op",
    "--at-operation",
    "--color",
    "--config",
    "--config-file",
}
JJ_INFO_FLAGS = {"--help", "-h", "--version", "-V"}
JJ_REPOSITORY_FREE = {"help", "version"}
JJ_UTIL_REPOSITORY_FREE = {
    "completion",
    "config-schema",
    "diff",
    "exec",
    "install-man-pages",
    "markdown-help",
}

# Shells whose -c string runs in the directory, and those of them that
# also run a script on stdin: nu refuses a stdin that is no terminal.
SHELLS = {"bash", "dash", "ksh", "nu", "sh", "zsh"}
STDIN_SHELLS = SHELLS - {"nu"}
SHELL_VALUE_OPTIONS = {"-O", "-o", "+O", "+o", "--init-file", "--rcfile"}

# Words before the program a simple command runs.
KEYWORDS = {
    "!",
    "coproc",
    "do",
    "elif",
    "else",
    "if",
    "then",
    "until",
    "while",
    "{",
}
PLAIN_WRAPPERS = {"builtin", "nohup", "noglob"}
# Runners whose program follows a `--`, by name and subcommand.
SEPARATED_RUNNERS = {
    ("fnox", "exec"),
    ("jouet", "job"),
    ("jouet", "test"),
    ("jouet", "wait"),
    ("mise", "exec"),
    ("mise", "x"),
}
TIMEOUT_VALUE_OPTIONS = {"-k", "-s", "--kill-after", "--signal"}
XARGS_VALUE_OPTIONS = {
    "-E",
    "-I",
    "-L",
    "-P",
    "-a",
    "-d",
    "-n",
    "-s",
    "--arg-file",
    "--delimiter",
    "--eof",
    "--max-args",
    "--max-chars",
    "--max-lines",
    "--max-procs",
    "--replace",
}
CD_OPTIONS = {"-@", "-L", "-P", "-e"}

ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
DASH_C = re.compile(r"^-[A-Za-z]*c[A-Za-z]*$")
# A shell option cluster ending in o or O, whose value is the next word.
SHELL_O_CLUSTER = re.compile(r"^[-+][A-Za-z]*[oO]$")
# find runs these in its own directory; -execdir and -okdir run in each
# match's, which cannot be known.
EXEC_FLAGS = {"-exec", "-ok"}
# Flags that finish or drop what git has in progress, which jj cannot.
SEQUENCER_FLAGS = {"--abort", "--continue", "--quit", "--skip"}
ECHO_FLAGS = {"-E", "-e", "-n"}

# The value of a word whose text is only known when it runs, such as
# one holding `$HOME` or `$(…)`.
UNKNOWN = "\x00"
UNKNOWABLE = "$`*?" + UNKNOWN

# Node types whose commands run in a subshell, so a cd in them stays.
SUBSHELLS = {
    "command_substitution",
    "function_definition",
    "process_substitution",
    "subshell",
}
WORD_TYPES = {"number", "variable_name", "word"}

PARSER = Parser(Language(tree_sitter_bash.language()))


def unknowable(target: str) -> bool:
    """Tell whether a path only gets its value when the command runs.

    `-` is the previous directory, and `{}` the path find or xargs puts
    in its place.
    """
    return (
        not target
        or target == "-"
        or "{}" in target
        or any(c in target for c in UNKNOWABLE)
    )


def resolve(base: Path, target: str) -> Path | None:
    """Return `target` relative to `base`, or None if unknowable.

    The path is normalised logically, without following symlinks, the
    way bash's cd moves: `cd ..` from a link goes to the link's parent.
    """
    if unknowable(target):
        return None
    return Path(os.path.normpath(base / os.path.expanduser(target)))


def resolve_physical(base: Path, target: str) -> Path | None:
    """Return `target` as chdir() reaches it, following each link.

    git -C, env -C, direnv exec and cd -P change directory physically,
    so `link/..` is the parent of the link's target.
    """
    if unknowable(target):
        return None
    return (base / os.path.expanduser(target)).resolve()


def program_name(word: str) -> str:
    """Return the program `word` runs; nu's `^git` runs git."""
    return os.path.basename(word).lstrip("^")


def skip_options(words: list[str], i: int, valued: set[str]) -> int:
    """Return the index past the options at `i`, `valued` taking one."""
    while i < len(words) and words[i].startswith("-"):
        i += 2 if words[i] in valued else 1
    return i


def index_after(words: list[str], i: int, markers: set[str]) -> int | None:
    """Return the index after the first of `markers` from `i` on."""
    for j in range(i, len(words)):
        if words[j] in markers:
            return j + 1
    return None


def unwrap(
    words: list[str], directory: Path
) -> tuple[list[str], Path | None, bool]:
    """Strip assignments, keywords and wrappers off a simple command.

    Returns the program's words, the directory it runs in (None when
    unknowable), and whether a GIT_DIR-like assignment retargets it.
    """
    retargeted = False
    i = 0
    while i < len(words):
        word = words[i]
        name = program_name(word)
        runner = words[i + 1 : i + 2]
        if ASSIGNMENT.match(word):
            retargeted |= word.split("=", 1)[0] in GIT_RETARGET_VARIABLES
            i += 1
        elif word == "coproc":
            i += 3 if words[i + 2 : i + 3] == ["{"] else 1
        elif word in KEYWORDS or name in PLAIN_WRAPPERS:
            i += 1
        elif name == "function":
            i += 2
        elif name == "command":
            if runner in (["-v"], ["-V"]):
                return [], directory, retargeted
            i = skip_options(words, i + 1, set())
        elif name in ("exec", "time"):
            i = skip_options(words, i + 1, {"-a"})
        elif name == "nice":
            i = skip_options(words, i + 1, {"-n"})
        elif name == "timeout":
            i = skip_options(words, i + 1, TIMEOUT_VALUE_OPTIONS) + 1
        elif name == "xargs":
            replace = xargs_replace(words, i + 1)
            i = skip_options(words, i + 1, XARGS_VALUE_OPTIONS)
            if replace:
                words = words[:i] + [
                    w.replace(replace, UNKNOWN) for w in words[i:]
                ]
        elif name == "nix" and runner in (["develop"], ["shell"]):
            after = index_after(words, i + 2, {"-c", "--command"})
            if after is None:
                return [], directory, retargeted
            i = after
        elif runner and (name, runner[0]) in SEPARATED_RUNNERS:
            after = index_after(words, i + 2, {"--"})
            if after is None:
                return [], directory, retargeted
            i = after
        elif name == "direnv" and runner == ["exec"] and i + 2 < len(words):
            moved_to = resolve_physical(directory, words[i + 2])
            if moved_to is None:
                return words[i + 3 :], None, retargeted
            directory = moved_to
            i += 3
        elif name == "env":
            i, moved_to, env_retarget = unwrap_env(words, i + 1, directory)
            retargeted |= env_retarget
            if moved_to is None:
                return words[i:], None, retargeted
            directory = moved_to
        else:
            break
    return words[i:], directory, retargeted


def xargs_replace(words: list[str], i: int) -> str | None:
    """Return the string xargs replaces with each input, if it has one."""
    while i < len(words) and words[i].startswith("-"):
        word = words[i]
        if word in ("-I", "--replace") and i + 1 < len(words):
            return words[i + 1]
        if word.startswith("--replace="):
            return word.split("=", 1)[1] or "{}"
        if word.startswith("-I"):
            return word[2:]
        if word.startswith("-i"):
            return word[2:] or "{}"
        i += 2 if word in XARGS_VALUE_OPTIONS else 1
    return None


def unwrap_env(
    words: list[str], i: int, directory: Path
) -> tuple[int, Path | None, bool]:
    """Skip env's options and assignments, following its -C."""
    retargeted = False
    current: Path | None = directory
    while i < len(words) and current is not None:
        word = words[i]
        if ASSIGNMENT.match(word):
            retargeted |= word.split("=", 1)[0] in GIT_RETARGET_VARIABLES
            i += 1
        elif word in ("-u", "--unset"):
            i += 2
        elif word in ("-C", "--chdir") and i + 1 < len(words):
            current = resolve_physical(current, words[i + 1])
            i += 2
        elif word.startswith("--chdir="):
            current = resolve_physical(current, word.split("=", 1)[1])
            i += 1
        elif word.startswith(("-S", "--split-string")):
            current = None
        elif word.startswith("-"):
            i += 1
        else:
            break
    return i, current, retargeted


def cd_target(name: str, args: list[str]) -> tuple[str | None, bool]:
    """Return the directory a cd or pushd names, None if unclear.

    The flag returned is whether `-P` asks for the physical directory.
    """
    physical = False
    i = 0
    while i < len(args) and (args[i] in CD_OPTIONS or args[i] == "-n"):
        physical |= args[i] == "-P"
        i += 1
    if args[i : i + 1] == ["--"]:
        i += 1
    rest = args[i:]
    if not rest:
        return ("~" if name == "cd" else None), physical
    if len(rest) != 1 or rest[0].startswith("+"):
        return None, physical
    return rest[0], physical


def existing_ancestor(path: Path) -> Path:
    """Return `path`, or its nearest ancestor that exists."""
    while not path.exists() and path != path.parent:
        path = path.parent
    return path


def nearest_root(start: Path) -> tuple[str, Path | None, Path | None]:
    """Classify `start` by the first `.jj` or `.git` above it.

    The physical path decides, since git and jj both find their
    repository from it. Returns the kind ("jj", "git" or "none"), the
    directory holding the marker, and the nearest `.jj` at or above it,
    which for a git worktree is the checkout jj would act on.
    """
    start = start.resolve()
    for directory in (start, *start.parents):
        if (directory / ".jj").is_dir():
            return "jj", directory, directory
        if (directory / ".git").exists():
            enclosing = next(
                (d for d in directory.parents if (d / ".jj").is_dir()), None
            )
            return "git", directory, enclosing
    return "none", None, None


def has_flag(arg: str, flags: set[str]) -> bool:
    """Tell whether `arg` is one of `flags`, with or without a value.

    A long flag may carry `=VALUE`; a short one may have its value
    attached, as in `-L10,20:a`.
    """
    if arg.split("=", 1)[0] in flags:
        return True
    return not arg.startswith("--") and arg[:2] in flags


def escapes_jj(subcommand: str, rest: list[str]) -> bool:
    """Tell whether flags take a git subcommand beyond jj's forms."""
    if "--help" in rest or "-h" in rest:
        return True
    if subcommand == "rev-parse":
        return any(a.startswith(REV_PARSE_LAYOUT) for a in rest)
    if subcommand == "cat-file":
        return "-p" not in rest
    if subcommand == "stash":
        return (
            bool(rest)
            and not rest[0].startswith("-")
            and rest[0]
            not in (
                "push",
                "save",
            )
        )
    if subcommand in ("cherry-pick", "merge", "rebase", "revert"):
        return bool(SEQUENCER_FLAGS & set(rest))
    if subcommand == "bisect":
        return rest[:1] != ["run"]
    if subcommand == "remote":
        return bool(REMOTE_NO_JJ & set(rest[:1]))
    flags = NO_JJ_FLAGS.get(subcommand, set())
    if any(has_flag(a, flags) for a in rest):
        return True
    if subcommand == "fetch":
        refs = [a for a in rest if not a.startswith("-")][1:]
        return any(FETCH_REF.search(r) for r in refs)
    return subcommand == "ls-files" and any(
        a.startswith("-")
        and not a.startswith("--")
        and bool(set(a[1:]) & LS_FILES_SHORT)
        for a in rest
    )


def clone_or_init_target(
    subcommand: str, rest: list[str], directory: Path
) -> Path | None:
    """Return the directory a clone or init creates its repository in."""
    valued = (
        CLONE_VALUE_OPTIONS if subcommand == "clone" else INIT_VALUE_OPTIONS
    )
    positional: list[str] = []
    i = 0
    while i < len(rest):
        arg = rest[i]
        if arg == "--":
            positional.extend(rest[i + 1 :])
            break
        if arg.startswith("-"):
            i += 2 if arg in valued else 1
            continue
        positional.append(arg)
        i += 1
    named = positional[1:2] if subcommand == "clone" else positional[:1]
    if not named:
        return directory
    return resolve(directory, named[0])


def check_git(directory: Path, args: list[str]) -> str | None:
    """Refuse a git subcommand that jj covers, in a jj repository."""
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "-C" and i + 1 < len(args):
            target = resolve_physical(directory, args[i + 1])
            if target is None:
                return None
            directory = target
            i += 2
        elif arg in GIT_VALUE_OPTIONS:
            i += 2
        elif arg.startswith(GIT_RETARGET_OPTIONS) or arg in ("--help", "-h"):
            return None
        elif arg.startswith("-"):
            i += 1
        else:
            break
    if i >= len(args) or not directory.is_dir():
        return None
    subcommand, rest = args[i], args[i + 1 :]
    if subcommand not in JJ_FORMS or escapes_jj(subcommand, rest):
        return None
    probe: Path | None = directory
    if subcommand in ("clone", "init"):
        probe = clone_or_init_target(subcommand, rest, directory)
    if probe is None:
        return None
    kind, root, _ = nearest_root(existing_ancestor(probe))
    if kind != "jj":
        return None
    return (
        f"vcs-guard: {root} is a jj repository; use"
        f" `{JJ_FORMS[subcommand]}` rather than `git {subcommand}`."
        " git is for what jj has no command for, such as worktree,"
        " check-ignore, config and ls-remote."
    )


def jj_needs_repository(args: list[str]) -> bool:
    """Tell whether a jj command loads the repository it runs in."""
    if any(
        a.startswith(("-R", "--repository=")) or a == "--repository"
        for a in args
    ) or JJ_INFO_FLAGS & set(args):
        return False
    i = 0
    while i < len(args) and args[i].startswith("-"):
        i += 2 if args[i] in JJ_VALUE_OPTIONS else 1
    command = args[i : i + 2]
    if not command:
        return True
    if command[0] in JJ_REPOSITORY_FREE:
        return False
    if command[0] == "config":
        return "--repo" in args[i:]
    if command[0] == "util":
        return command[1:] != [] and command[1] not in JJ_UTIL_REPOSITORY_FREE
    return command not in (["git", "clone"], ["git", "init"])


def check_jj(directory: Path, args: list[str]) -> str | None:
    """Refuse jj in a git worktree that a jj checkout encloses."""
    if not directory.is_dir() or not jj_needs_repository(args):
        return None
    kind, root, enclosing = nearest_root(directory)
    if kind != "git" or enclosing is None:
        return None
    return (
        f"vcs-guard: {root} is a git worktree with no .jj of its own, so"
        f" jj here walks up to {enclosing} and acts on that checkout's"
        " working copy. Use git in this worktree, or `jj -R"
        f" {enclosing}` to mean the enclosing checkout."
    )


def shell_arguments(args: list[str]) -> tuple[str | None, bool]:
    """Return a shell's `-c` string, and whether it runs a script file.

    A shell running a file reads stdin as that program's data, not as
    commands.
    """
    reads_stdin = False
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--commands" or DASH_C.match(arg):
            rest = [a for a in args[i + 1 :] if not a.startswith(("-", "+"))]
            return (rest[0] if rest else None), False
        if arg in SHELL_VALUE_OPTIONS or SHELL_O_CLUSTER.match(arg):
            i += 2
        elif arg.startswith(("-", "+")):
            reads_stdin |= not arg.startswith("--") and "s" in arg[1:]
            i += 1
        else:
            return None, not reads_stdin
    return None, False


def reads_script_on_stdin(words: list[str]) -> bool:
    """Tell whether a command is a shell running what stdin holds."""
    if not words or program_name(words[0]) not in STDIN_SHELLS:
        return False
    string, runs_file = shell_arguments(words[1:])
    return string is None and not runs_file


def value(node: Node) -> str:
    """Return the text a word stands for, or UNKNOWN if it expands."""
    text = node.text.decode()
    kind = node.type
    if kind == "command_name":
        return value(node.named_children[0]) if node.named_children else text
    if kind in WORD_TYPES:
        return re.sub(r"\\(.)", r"\1", text)
    if kind == "raw_string":
        return text[1:-1]
    if kind == "string":
        if any(c.type != "string_content" for c in node.named_children):
            return UNKNOWN
        return re.sub(r'\\([$`"\\\n])', r"\1", text[1:-1])
    if kind == "ansi_c_string":
        try:
            return codecs.decode(text[2:-1], "unicode_escape")
        except UnicodeDecodeError:
            return UNKNOWN
    if kind == "concatenation":
        parts = [value(c) for c in node.named_children]
        return UNKNOWN if UNKNOWN in parts else "".join(parts)
    return UNKNOWN


def command_words(node: Node) -> list[str]:
    """Return a command node's words: assignments, name, arguments."""
    words: list[str] = []
    for child in node.named_children:
        if child.type == "variable_assignment":
            name = child.child_by_field_name("name")
            words.append((value(name) if name else UNKNOWN) + "=")
    name = node.child_by_field_name("name")
    if name is None:
        return []
    words.append(value(name))
    words.extend(value(a) for a in node.children_by_field_name("argument"))
    return words


def echoed(node: Node | None) -> str | None:
    """Return what an `echo` or a %-free `printf` prints, if fixed."""
    if node is None or node.type != "command":
        return None
    words = command_words(node)
    if not words or UNKNOWN in words:
        return None
    if words[0] == "echo":
        return " ".join(w for w in words[1:] if w not in ECHO_FLAGS)
    if words[0] == "printf" and len(words) > 1 and "%" not in words[1]:
        try:
            return codecs.decode(words[1], "unicode_escape")
        except UnicodeDecodeError:
            return None
    return None


def statement_command(node: Node) -> Node | None:
    """Return the simple command a statement runs, past its redirects."""
    if node.type == "redirected_statement":
        body = node.child_by_field_name("body")
        return statement_command(body) if body else None
    return node if node.type == "command" else None


@dataclass
class Place:
    """Where commands run: a directory, None when unknowable, and the
    stack pushd and popd move through."""

    directory: Path | None
    stack: list[Path | None] = field(default_factory=list)

    def copy(self) -> "Place":
        """Return a copy, for a subshell whose cd stays inside it."""
        return Place(self.directory, list(self.stack))


@dataclass
class Walker:
    """Walk a bash syntax tree, checking each command where it runs.

    `substitutions` is off for a nu string, where a backtick is text
    rather than a command; nu's `(…)` still runs, as a subshell does.
    """

    substitutions: bool = True

    def visit(
        self, node: Node, place: Place, stdin: list[str] | None = None
    ) -> str | None:
        """Check `node`; return the first refusal, or None."""
        kind = node.type
        if kind in SUBSHELLS:
            if kind.endswith("_substitution") and not self.substitutions:
                return None
            return self.children(node, place.copy())
        if kind == "pipeline":
            return self.pipeline(node, place, stdin or [])
        if kind == "redirected_statement":
            return self.redirected(node, place, stdin or [])
        if kind == "command":
            return self.command(node, place, stdin or [])
        if kind == "declaration_command":
            return self.declaration(node, place)
        return self.children(node, place)

    def children(self, node: Node, place: Place) -> str | None:
        """Check a node's children in order, sharing one place."""
        for child in node.named_children:
            message = self.visit(child, place)
            if message:
                return message
        return None

    def pipeline(
        self, node: Node, place: Place, stdin: list[str]
    ) -> str | None:
        """Check each stage in its own subshell, as bash runs them.

        The first stage reads `stdin`; a later shell stage reading
        stdin runs what the stage before it echoes, as in
        `echo 'git status' | bash`.
        """
        stages = node.named_children
        for i, stage in enumerate(stages):
            if i:
                stdin = []
            if i and reads_script_on_stdin(self.words_of(stage)):
                script = echoed(statement_command(stages[i - 1]))
                stdin = [script] if script is not None else []
            message = self.visit(stage, place.copy(), stdin)
            if message:
                return message
        return None

    def words_of(self, node: Node) -> list[str]:
        """Return the words of the simple command a statement runs."""
        command = statement_command(node)
        return command_words(command) if command else []

    def redirected(
        self, node: Node, place: Place, stdin: list[str]
    ) -> str | None:
        """Check a statement and its redirects, feeding a shell its
        heredoc or here-string as the script it runs.

        A redirect on a compound statement has no field name, so every
        named child but the body counts.
        """
        body = node.child_by_field_name("body")
        redirects = [
            child
            for i, child in enumerate(node.children)
            if child.is_named and node.field_name_for_child(i) != "body"
        ]
        scripts = [
            heredoc_text(r) for r in redirects if r.type == "heredoc_redirect"
        ]
        for redirect in redirects:
            message = self.expansions(redirect, place)
            if message:
                return message
        if body is not None:
            message = self.visit(body, place, stdin + scripts)
            if message:
                return message
        for redirect in redirects:
            if redirect.type == "heredoc_redirect":
                message = self.heredoc(
                    redirect, place, [heredoc_text(redirect)]
                )
                if message:
                    return message
        return None

    def expansions(self, node: Node, place: Place) -> str | None:
        """Check the substitutions in a redirect, outside any statement
        a heredoc operator carries on with."""
        for child in node.named_children:
            if child.type in ("pipeline", "list", "command"):
                continue
            message = self.visit(child, place)
            if message:
                return message
        directory = place.directory
        if node.type != "heredoc_redirect" or directory is None:
            return None
        for script in backticks(node):
            message = check_script(script, directory)
            if message:
                return message
        return None

    def heredoc(self, node: Node, place: Place, body: list[str]) -> str | None:
        """Check the statement a heredoc operator's line goes on with.

        In `cat <<EOF | bash`, the pipeline is part of the redirect
        node, and its first stage reads the heredoc's body.
        """
        for child in node.named_children:
            if child.type == "pipeline":
                message = self.pipeline(child, place, body)
                if message:
                    return message
            elif child.type in ("list", "command"):
                message = self.visit(child, place)
                if message:
                    return message
        return None

    def declaration(self, node: Node, place: Place) -> str | None:
        """Check `export` and the like; exporting GIT_DIR retargets
        every git after it."""
        message = self.children(node, place)
        if message:
            return message
        for child in node.named_children:
            name = child.child_by_field_name("name")
            if child.type == "variable_assignment" and name is not None:
                variable = value(name)
            elif child.type in ("variable_name", "word"):
                variable = value(child)
            else:
                continue
            if variable in GIT_RETARGET_VARIABLES:
                place.directory = None
        return None

    def command(
        self, node: Node, place: Place, stdin: list[str]
    ) -> str | None:
        """Check a simple command: its substitutions, then the program.

        Substitutions in its words run first, in the directory in
        effect before the command, so `cd "$(git rev-parse
        --show-toplevel)"` checks git where it is.
        """
        if place.directory is None:
            return None
        message = self.children(node, place)
        if message:
            return message
        words = command_words(node)
        stdin = stdin + [
            value(r.named_children[0])
            for r in node.children_by_field_name("redirect")
            if r.type == "herestring_redirect" and r.named_children
        ]
        return self.program(words, place, stdin)

    def program(
        self, words: list[str], place: Place, stdin: list[str]
    ) -> str | None:
        """Follow cd and its kin, or check git, jj and what runs them."""
        directory = place.directory
        if directory is None:
            return None
        words, here, retargeted = unwrap(words, directory)
        if not words:
            return None
        name = program_name(words[0])
        if name in ("cd", "pushd"):
            target, physical = cd_target(name, words[1:])
            follow = resolve_physical if physical else resolve
            moved = None if target is None else follow(directory, target)
            if name == "pushd" and "-n" in words[1:]:
                place.stack.append(moved)
                return None
            if name == "pushd":
                place.stack.append(directory)
            place.directory = moved
            return None
        if name == "popd":
            return self.popd(words[1:], place)
        if here is None or retargeted:
            return None
        return self.call(here, words, stdin)

    def popd(self, args: list[str], place: Place) -> None:
        """Follow popd: plain, it returns to the last pushd; `-n` drops
        that entry and stays; `+N` or `-N` drops one the guard cannot
        tell, so the stack is forgotten."""
        if not args:
            place.directory = place.stack.pop() if place.stack else None
        elif args == ["-n"]:
            if place.stack:
                place.stack.pop()
        else:
            place.stack.clear()

    def call(
        self, directory: Path, words: list[str], stdin: list[str]
    ) -> str | None:
        """Check one program, already unwrapped, run in `directory`."""
        name = program_name(words[0])
        if name == "git":
            return check_git(directory, words[1:])
        if name == "jj":
            return check_jj(directory, words[1:])
        if UNKNOWN in words:
            return None
        if name == "eval":
            return check_script(" ".join(words[1:]), directory)
        if name in SHELLS:
            string, runs_file = shell_arguments(words[1:])
            if string is not None:
                return check_script(string, directory, name != "nu")
            for script in [] if runs_file or name == "nu" else stdin:
                message = check_script(script, directory)
                if message:
                    return message
            return None
        if name == "find":
            for k, word in enumerate(words):
                if word in EXEC_FLAGS:
                    message = self.program(
                        words[k + 1 :], Place(directory), []
                    )
                    if message:
                        return message
        return None


def backticks(node: Node) -> list[str]:
    """Return the backtick commands an unquoted heredoc body runs.

    The grammar reads `$(…)` in such a body but leaves backticks as
    text.
    """
    start = next(
        (c for c in node.named_children if c.type == "heredoc_start"), None
    )
    if start is None or start.text.decode()[:1] in "'\"\\":
        return []
    return re.findall(r"(?<!\\)`((?:\\.|[^`\\])*)`", heredoc_text(node))


def heredoc_text(node: Node) -> str:
    """Return a heredoc's body as the text a shell reading it runs."""
    body = next(
        (c for c in node.named_children if c.type == "heredoc_body"), None
    )
    return body.text.decode() if body else ""


def check_script(
    script: str, cwd: Path, substitutions: bool = True
) -> str | None:
    """Return why `script`, run in `cwd`, is refused, or None.

    A script the grammar cannot parse whole passes.
    """
    # A command may end in a backslash-newline, which bash takes and
    # the grammar rejects.
    script = re.sub(r"(?<!\\)\\\n\s*\Z", "", script)
    tree = PARSER.parse(script.encode())
    if tree.root_node.has_error:
        return None
    return Walker(substitutions).visit(tree.root_node, Place(cwd))


def decide(event: dict[str, object]) -> str | None:
    """Return why the event's Bash command is refused, or None."""
    tool_input = event.get("tool_input")
    cwd = event.get("cwd")
    if not isinstance(tool_input, dict) or not isinstance(cwd, str):
        return None
    command = tool_input.get("command")
    if not isinstance(command, str):
        return None
    try:
        return check_script(command, Path(cwd))
    # A crashed hook refuses nothing and tells the agent nothing, so
    # whatever cannot be read passes, like an unparseable command.
    except Exception:  # noqa: BLE001
        return None


def main(read: Callable[[], str] = sys.stdin.read) -> int:
    """Read the hook event, print any refusal, return the exit code."""
    try:
        event = json.loads(read())
    except json.JSONDecodeError:
        return 0
    if not isinstance(event, dict):
        return 0
    message = decide(event)
    if message is None:
        return 0
    print(message, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
