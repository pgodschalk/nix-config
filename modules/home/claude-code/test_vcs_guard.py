"""Tests for vcs_guard against marker trees built in a temporary dir."""

import io
import json
import tempfile
import unittest
from collections.abc import Callable
from contextlib import redirect_stderr
from pathlib import Path

import vcs_guard

TAB = "\t"


def lines(*parts: str) -> str:
    """Join `parts` into one multi-line command."""
    return "\n".join(parts)


class GuardTest(unittest.TestCase):
    """Each layout the hook tells apart, built from `.jj` and `.git`."""

    def setUp(self) -> None:
        """Build a colocated repo, an Orca worktree, a git-only repo."""
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name).resolve()
        self.jj = root / "jjrepo"
        (self.jj / ".jj").mkdir(parents=True)
        (self.jj / ".git").mkdir()
        (self.jj / "sub").mkdir()
        self.wt = self.jj / ".orca" / "worktrees" / "wt"
        self.wt.mkdir(parents=True)
        (self.wt / ".git").write_text("gitdir: ../../../.git/worktrees/wt\n")
        self.git = root / "gitrepo"
        (self.git / ".git").mkdir(parents=True)
        self.plain = root / "plain"
        self.plain.mkdir()

    def tearDown(self) -> None:
        """Remove the marker trees."""
        self.tmp.cleanup()

    def check(self, cwd: Path, command: str) -> str | None:
        """Return the block message for `command` run in `cwd`."""
        event = {"cwd": str(cwd), "tool_input": {"command": command}}
        return vcs_guard.decide(event)

    def assert_blocked(self, cwd: Path, command: str, hint: str) -> None:
        """Assert `command` is refused with `hint` in the message."""
        message = self.check(cwd, command)
        self.assertIsNotNone(message, command)
        self.assertIn(hint, message or "")

    def assert_allowed(self, cwd: Path, command: str) -> None:
        """Assert `command` passes."""
        self.assertIsNone(self.check(cwd, command), command)

    def test_git_in_jj_repo_names_the_jj_command(self) -> None:
        """A git command jj covers is refused with its jj form."""
        cases = {
            "git status": "jj status",
            "git status --short": "jj status",
            "git diff HEAD": "jj diff",
            "git log --oneline -5": "jj log",
            "git rev-parse HEAD": "commit_id",
            "git ls-files '*.nix'": "jj file list",
            "git add foo": "jj file track",
            "git commit -m x": "jj commit",
            "git push": "jj git push",
            "git fetch": "jj git fetch",
            "git branch -a": "jj bookmark",
            "git stash": "jj new",
            "git blame flake.nix": "jj file annotate",
            "git remote -v": "jj git remote",
            "git grep foo": "jj file search",
        }
        for command, hint in cases.items():
            with self.subTest(command=command):
                self.assert_blocked(self.jj, command, hint)

    def test_git_without_a_jj_equivalent_passes(self) -> None:
        """Git commands jj has no form of stay available."""
        for command in [
            "git worktree list",
            "git check-ignore -v result",
            "git config --get core.hooksPath",
            "git config core.hooksPath hooks",
            "git ls-remote origin",
            "git clean -n",
        ]:
            with self.subTest(command=command):
                self.assert_allowed(self.jj, command)

    def test_global_options_are_skipped(self) -> None:
        """Options before the subcommand do not hide it."""
        for command in [
            "git -c commit.gpgsign=false commit -m x",
            "git --no-pager log",
            "/usr/bin/git status",
        ]:
            with self.subTest(command=command):
                self.assertIsNotNone(self.check(self.jj, command))

    def test_jj_in_jj_repo_passes(self) -> None:
        """Jj itself, including `jj git`, is the intended tool."""
        for command in ["jj status", "jj git fetch", "jj git push -b main"]:
            with self.subTest(command=command):
                self.assert_allowed(self.jj, command)

    def test_subdirectory_of_jj_repo(self) -> None:
        """The nearest root is found from below it."""
        self.assert_blocked(self.jj / "sub", "git status", "jj status")

    def test_compound_commands(self) -> None:
        """Every segment of a list or pipeline is checked."""
        for command in [
            "echo hi && git status",
            "jj st; git status",
            "git status | head",
            "true || git status",
            lines("jj st", "git status"),
            "FOO=1 git status",
            "env FOO=1 git status",
            "git status # trailing comment",
        ]:
            with self.subTest(command=command):
                self.assertIsNotNone(self.check(self.jj, command))

    def test_git_mentioned_but_not_run(self) -> None:
        """A `git` that is an argument, string or body is not a call."""
        for command in [
            "grep git foo",
            "jouet search 'git status'",
            'jj describe -m "fix; git status"',
            "echo nixpkgs#git && jj st",
            lines("cat <<'EOF' > msg", "git status", "EOF", "jj st"),
            lines("cat <<-EOF", TAB + "git status", TAB + "EOF"),
        ]:
            with self.subTest(command=command):
                self.assert_allowed(self.jj, command)

    def test_cd_and_dash_c_retarget(self) -> None:
        """A leading cd or `git -C` moves the check to that dir."""
        self.assert_allowed(self.jj, "cd .orca/worktrees/wt && git status")
        self.assert_allowed(self.jj, f"git -C {self.wt} status")
        self.assert_allowed(self.jj, f"cd {self.git}; git status")
        self.assert_blocked(self.wt, "cd ../../.. && git status", "jj")

    def test_unknown_directory_is_unchecked(self) -> None:
        """A cd the hook cannot resolve stops the check."""
        self.assert_allowed(self.jj, "cd $X && git status")
        self.assert_allowed(self.jj, "cd - && git status")

    def test_orca_worktree_uses_git(self) -> None:
        """In a git worktree inside a jj checkout, git is right."""
        self.assert_allowed(self.wt, "git status")
        self.assert_allowed(self.wt, "git -c commit.gpgsign=false commit")

    def test_orca_worktree_refuses_jj(self) -> None:
        """Jj there would walk up and act on the enclosing checkout."""
        message = self.check(self.wt, "jj status")
        self.assertIsNotNone(message)
        self.assertIn(str(self.jj), message or "")
        self.assertIsNotNone(self.check(self.wt, "jj git fetch"))

    def test_jj_with_explicit_repository_passes(self) -> None:
        """`jj -R` names its repository, so nothing walks up."""
        self.assert_allowed(self.wt, f"jj -R {self.jj} status")
        self.assert_allowed(self.wt, f"jj --repository={self.jj} log")

    def test_git_only_repo(self) -> None:
        """Without a jj repo above, neither tool is refused."""
        self.assert_allowed(self.git, "git status")
        self.assert_allowed(self.git, "jj status")
        self.assert_allowed(self.plain, "git status")

    def test_unparseable_input_passes(self) -> None:
        """A command shlex cannot split, or a missing dir, passes."""
        self.assert_allowed(self.jj, "git status 'unterminated")
        self.assert_allowed(self.jj / "missing", "git status")
        self.assertIsNone(vcs_guard.decide({}))

    def assert_all_blocked(self, cwd: Path, commands: list[str]) -> None:
        """Assert every command in `commands` is refused in `cwd`."""
        for command in commands:
            with self.subTest(command=command):
                self.assertIsNotNone(self.check(cwd, command), command)

    def assert_all_allowed(self, cwd: Path, commands: list[str]) -> None:
        """Assert every command in `commands` passes in `cwd`."""
        for command in commands:
            with self.subTest(command=command):
                self.assert_allowed(cwd, command)

    def test_subshell_and_popd_restore_the_directory(self) -> None:
        """A cd inside (…), $(…) or undone by popd does not leak."""
        jj = self.jj
        self.assert_all_allowed(
            self.wt,
            [
                f"(cd {jj} && jj log); git status",
                f"(cd {jj}) && git status",
                f"echo $(cd {jj}); git status",
                f"pushd {jj}; popd; git status",
            ],
        )
        self.assert_blocked(
            self.jj, "(cd .orca/worktrees/wt) && git status", "jj status"
        )

    def test_git_dir_in_the_environment_retargets(self) -> None:
        """GIT_DIR and GIT_WORK_TREE act like --git-dir."""
        repo = self.git
        self.assert_all_allowed(
            self.jj,
            [
                f"GIT_DIR={repo}/.git git status",
                f"env GIT_DIR={repo}/.git GIT_WORK_TREE={repo} git log",
                f"export GIT_DIR={repo}/.git; git status",
            ],
        )

    def test_flag_forms_without_a_jj_equivalent(self) -> None:
        """A flag that takes a subcommand outside jj's reach passes."""
        self.assert_all_allowed(
            self.jj,
            [
                "git diff --no-index a b",
                "git grep --no-index foo",
                "git ls-files --others --ignored --exclude-standard",
                "git ls-files -o",
                "git status --ignored",
                "git log --help",
                "git rev-parse --git-dir",
                "git rev-parse --is-inside-work-tree",
                "git cat-file -t HEAD",
            ],
        )
        self.assert_blocked(
            self.jj, "git rev-parse --show-toplevel", "jj root"
        )
        self.assert_blocked(self.jj, "git cat-file -p HEAD", "jj file show")

    def test_jj_that_never_opens_the_repository(self) -> None:
        """In an Orca worktree, jj help, version and config pass."""
        self.assert_all_allowed(
            self.wt,
            [
                "jj --version",
                "jj help log",
                "jj log --help",
                "jj util completion zsh",
                "jj config get user.name",
                "jj --color never version",
                "jj git clone https://example.com/x /tmp/z",
            ],
        )
        self.assert_all_blocked(
            self.wt,
            [
                "jj config set --repo user.name x",
                "jj --ignore-working-copy log",
                "jj --at-op @ log",
            ],
        )

    def test_clone_and_init_judge_their_target(self) -> None:
        """Clone and init act on their target, not the cwd."""
        plain = self.plain
        self.assert_all_allowed(
            self.jj,
            [
                f"git clone --depth 1 https://example.com/x {plain}/clone",
                f"git init {plain}/fixture",
                f"git init -b main {plain}/fixture",
            ],
        )
        self.assert_blocked(self.jj, "git clone https://x/y", "jj git clone")
        self.assert_blocked(self.jj, "git init", "jj git init")
        self.assert_blocked(
            self.jj, f"git init {self.jj}/sub/x", "jj git init"
        )

    def test_shell_keywords_do_not_hide_the_program(self) -> None:
        """Git after if, !, while, do or { is still checked."""
        self.assert_all_blocked(
            self.jj,
            [
                "if ! git push; then echo x; fi",
                "if true; then git commit -m wip; fi",
                "! git status",
                'for f in a b; do git add "$f"; done',
                "while ! git push; do sleep 2; done",
                "{ git status; }",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "if jj st; then :; fi"))

    def test_wrappers_do_not_hide_the_program(self) -> None:
        """Timeout, nice, xargs and env with options are seen through."""
        self.assert_all_blocked(
            self.jj,
            [
                "timeout 60 git push",
                "timeout -k 5 60 git fetch",
                "nice git log",
                "nice -n 10 git log",
                "noglob git log",
                "xargs git add < files",
                "find . -name x | xargs -I{} git add {}",
                "xargs -n 1 git rm",
                "env -u PAGER git log",
                "/usr/bin/env git status",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "timeout 30 jj st"))
        self.assert_allowed(self.jj, f"env -C {self.wt} git status")
        self.assert_allowed(self.jj, "command -v git")

    def test_cd_with_redirects_and_options(self) -> None:
        """A cd target is still read past redirects and -P or --."""
        jj = self.jj
        self.assert_allowed(
            jj, "cd .orca/worktrees/wt >/dev/null && git status"
        )
        self.assert_all_blocked(
            self.plain,
            [
                f"cd {jj} 2>/dev/null && git status",
                f"pushd {jj} >/dev/null && git status",
                f"cd -P {jj}/sub && git status",
                f"cd -- {jj}/sub && git status",
            ],
        )

    def test_quoted_substitutions_are_checked(self) -> None:
        """$(…) and backticks run, quoted or not; '…' stays literal."""
        self.assert_all_blocked(
            self.jj,
            [
                'echo "$(git rev-parse HEAD)"',
                'echo "sha: `git rev-parse HEAD`"',
                "echo `git rev-parse HEAD`",
            ],
        )
        self.assert_all_allowed(
            self.jj,
            [
                "echo '$(git rev-parse HEAD)'",
                'jj describe -m "use \\$(git x)"',
            ],
        )
        self.assertIsNotNone(
            self.check(self.wt, 'echo "change: $(jj log -r @)"')
        )

    def test_plumbing_with_a_jj_form(self) -> None:
        """Plumbing jj covers is refused with its jj form."""
        cases = {
            "git merge-base main HEAD": "heads(",
            "git rev-list --count HEAD": "jj log",
            "git diff-tree -r HEAD": "jj diff",
            "git show-ref": "jj bookmark list",
            "git for-each-ref refs/heads": "jj bookmark list",
            "git range-diff a...b": "jj interdiff",
            "git mergetool": "jj resolve",
            "git gc": "jj util gc",
            "git absorb": "jj absorb",
            "git difftool": "jj diff --tool",
            "git whatchanged": "jj log",
        }
        for command, hint in cases.items():
            with self.subTest(command=command):
                self.assert_blocked(self.jj, command, hint)

    def test_heredoc_delimiters_of_any_form(self) -> None:
        """Quoted, escaped or punctuated delimiters end a body too."""
        self.assert_all_allowed(
            self.jj,
            [
                lines("cat <<\\EOF", "git status", "EOF", "jj st"),
                lines("cat <<'END-MSG'", "git status", "END-MSG"),
                lines('cat <<"EOF1"', "git push", "EOF1"),
            ],
        )

    def test_continuations_and_comments(self) -> None:
        """A backslash-newline joins; an unquoted # starts a comment."""
        self.assert_allowed(self.wt, lines("jj \\", f"  -R {self.jj} log"))
        self.assert_blocked(self.jj, lines("git \\", "  status"), "jj")
        self.assert_all_allowed(
            self.jj,
            ["jj st # don't use git status", "jj st # a; git status"],
        )
        self.assertIsNotNone(self.check(self.jj, "echo a#b; git status"))

    def test_substitution_bodies_keep_their_own_quotes(self) -> None:
        """Inside "$(…)", '…' is literal again, as bash reads it."""
        self.assert_all_allowed(
            self.jj,
            [
                "gh pr create --body \"$(printf '%s' 'Run `git status`')\"",
                "jj describe -m \"$(printf '%s' 'use `git log` here')\"",
                lines(f'echo "$(printf "PR #12")"; cd {self.git}', "git log"),
            ],
        )

    def test_substitutions_run_where_they_appear(self) -> None:
        """A body is checked in the directory in effect at its place."""
        self.assert_all_blocked(
            self.jj,
            [
                'cd "$(git rev-parse --show-toplevel)" && ls',
                'ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"',
                'echo "$(git rev-parse HEAD)" && cd /tmp',
            ],
        )
        self.assert_blocked(
            self.plain, f'cd {self.jj} && echo "$(git log -1)"', "jj log"
        )
        self.assert_allowed(self.jj, f'cd {self.wt} && echo "$(git log)"')

    def test_process_substitution_is_checked(self) -> None:
        """<(…) and >(…) run their command; the rest stays checked."""
        self.assert_all_blocked(
            self.jj,
            [
                "diff <(git show HEAD:flake.nix) flake.nix",
                "comm -13 <(git ls-files | sort) <(ls | sort)",
                "diff <(true) x; git status",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "diff <(jj file show a) a"))

    def test_shell_command_strings_are_checked(self) -> None:
        """The string given to bash -c, sh -c or nu -c is a command."""
        self.assert_all_blocked(
            self.jj,
            [
                "bash -c 'git status'",
                "bash -lc 'git status'",
                'sh -c "git log -1"',
                "timeout 60 bash -c 'git fetch'",
                "nu -l -c 'git push'",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "bash -c 'jj st'"))
        self.assert_all_allowed(self.jj, ["bash -c 'jj st'", "bash x.sh"])

    def test_more_forms_without_a_jj_equivalent(self) -> None:
        """Bare repos, annotated tags, refspecs and the like pass."""
        self.assert_all_allowed(
            self.jj,
            [
                "git init --bare remote.git",
                "git clone --bare x mirror.git",
                "git clone --mirror https://a/b b.git",
                "git fetch origin pull/123/head:pr-123",
                "git tag -a v1.0 -m rel",
                "git bisect start",
                "git diff --quiet",
                "git diff --exit-code -- a",
                "git merge-base --is-ancestor main HEAD",
                "git log -L 10,20:a",
                "git log -L10,20:a",
                "git log --follow -- a",
                "git blame -L 1,2 a",
                "git --help log",
                "git log -h",
            ],
        )
        self.assert_all_blocked(
            self.jj,
            ["git bisect run make", "git tag v1", "git fetch origin"],
        )

    def test_jj_util_without_a_repository(self) -> None:
        """jj util exec and diff need no repository; gc does."""
        self.assert_all_allowed(
            self.wt, ["jj util exec -- true", "jj util diff a b"]
        )
        self.assertIsNotNone(self.check(self.wt, "jj util gc"))

    def test_heredoc_operator_in_quotes_or_arithmetic(self) -> None:
        """A quoted or arithmetic << starts no heredoc."""
        self.assert_all_blocked(
            self.jj,
            [
                lines("python3 -c 'print(1 << 3)'", "git status"),
                lines('echo "a <<b"', "git status"),
                lines("x=$((1<<2))", "git status"),
            ],
        )

    def test_case_patterns_close_no_subshell(self) -> None:
        """A case pattern's ) leaves the checks running."""
        self.assert_all_blocked(
            self.jj,
            [
                'case "$1" in *) ;; esac; git status',
                lines('case "$1" in *) ;; esac', "git status"),
            ],
        )

    def test_attached_repository_option(self) -> None:
        """jj -R<path> names its repository like jj -R <path>."""
        self.assert_allowed(self.wt, f"jj -R{self.jj} log")

    def test_cd_is_logical(self) -> None:
        """`cd ..` from a symlink goes to the link's parent, as in bash."""
        link = self.git / "link"
        link.symlink_to(self.jj / "sub")
        self.assert_allowed(link, "cd .. && git status")

    def test_heredoc_inside_a_substitution_is_data(self) -> None:
        """A commit message heredoc in "$(…)" is never read as shell."""
        message = lines(
            "jj describe -m \"$(cat <<'EOF'",
            "fix: don't let `git status` through",
            "1) refuse `git log` and $(git push)",
            "EOF",
            ')"',
        )
        self.assert_allowed(self.jj, message)
        self.assert_allowed(
            self.wt, message.replace("jj describe", "git commit")
        )

    def test_quoted_parentheses_are_words(self) -> None:
        """A quoted or escaped ( or ) is an argument, not a subshell."""
        self.assert_all_allowed(
            self.jj,
            [
                "(cd .orca/worktrees/wt && grep -c ')' a; git status)",
                "(cd .orca/worktrees/wt && echo \\) && git status)",
            ],
        )

    def test_case_inside_a_subshell(self) -> None:
        """A case pattern's ) inside (…) leaves the subshell open."""
        self.assert_allowed(
            self.jj,
            "(cd .orca/worktrees/wt; case x in *) git status;; esac)",
        )

    def test_nu_strings_keep_backticks_literal(self) -> None:
        """In nu, a backtick inside a string is text, and ^git runs git."""
        self.assert_allowed(
            self.jj, "nu -l -c 'gh pr create --body \"Uses `git log`\"'"
        )
        self.assertIsNotNone(self.check(self.jj, "nu -c '^git status'"))

    def test_symlinks_are_judged_physically(self) -> None:
        """A link into another repository belongs to that repository."""
        outside = self.plain / "ext"
        outside.mkdir()
        link = self.jj / "extlink"
        link.symlink_to(outside)
        self.assert_allowed(link, "git init")
        self.assert_allowed(self.jj, "cd extlink && git init")

    def test_more_flags_without_a_jj_equivalent(self) -> None:
        """Fetch depth, blame detection, tag verify and the like pass."""
        self.assert_all_allowed(
            self.jj,
            [
                "git fetch --unshallow",
                "git fetch --depth=50",
                "git fetch --dry-run",
                "git blame -w a",
                "git blame -C -C a",
                "git blame --porcelain a",
                "git tag -v v1",
                "git ls-files --error-unmatch a",
                "git fetch origin refs/heads/main",
            ],
        )
        self.assert_blocked(self.jj, "git fetch origin main", "--branch")

    def test_array_assignment_runs_nothing(self) -> None:
        """`cmd=(git status)` defines an array."""
        self.assert_allowed(self.jj, 'cmd=(git status --short); echo "$cmd"')

    def test_function_bodies_are_checked(self) -> None:
        """Both function forms run their body when called."""
        self.assert_all_blocked(
            self.jj,
            ["function f { git status; }; f", "f() { git status; }; f"],
        )

    def test_substitution_as_a_redirect_target(self) -> None:
        """`< <(git …)` and `<<< "$(git …)"` run their command."""
        self.assert_all_blocked(
            self.jj,
            [
                'while read -r f; do echo "$f"; done < <(git ls-files)',
                'grep foo <<< "$(git status --porcelain)"',
                'echo hi > "$(git rev-parse --show-toplevel)/out"',
            ],
        )

    def test_shell_options_before_dash_c(self) -> None:
        """Valued options and +options do not hide the -c string."""
        self.assert_all_blocked(
            self.jj,
            [
                "bash -o pipefail -c 'git log | head'",
                "bash -O extglob -c 'git status'",
                "sh +e -c 'git log'",
            ],
        )

    def test_scripts_fed_to_a_shell(self) -> None:
        """A heredoc or here-string given to a shell is a script."""
        self.assert_all_blocked(
            self.jj,
            [
                lines("bash <<'EOF'", "git status", "EOF"),
                lines("cat <<EOF | bash", "git status", "EOF"),
                "bash <<< 'git status'",
            ],
        )
        self.assert_allowed(self.jj, lines("cat <<'EOF'", "git status", "EOF"))

    def test_heredoc_detection_edges(self) -> None:
        """Heredocs across multi-line strings, odd delimiters, shifts."""
        self.assert_all_allowed(
            self.jj,
            [
                lines(
                    'jj describe -m "x', "y\" && cat <<'EOF'", "git log", "EOF"
                ),
                lines("cat <<.END", "git log", ".END"),
            ],
        )
        self.assert_all_blocked(
            self.jj,
            [
                lines("echo $(( 1 << n ))", "git status"),
                lines("x=$(( a << b ))", "git log"),
            ],
        )

    def test_runner_wrappers(self) -> None:
        """nix develop -c, mise exec --, eval and coproc run a program."""
        self.assert_all_blocked(
            self.jj,
            [
                "nix develop -c git status",
                "nix shell nixpkgs#git -c git log",
                "mise exec -- git status",
                "eval git status",
                'eval "git log --oneline"',
                "coproc git log",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "mise exec -- jj log"))

    def test_reparsed_strings_see_their_own_syntax(self) -> None:
        """bash -c, eval and here-strings keep their $(…) and (…)."""
        repo = self.git
        self.assert_all_blocked(
            self.jj,
            [
                "bash -c 'echo $(git log -1)'",
                "bash -c '(git status)'",
                "zsh -c 'f() { git status; }; f'",
                "bash <<< 'echo $(git status)'",
                "eval '$(git status)'",
            ],
        )
        self.assert_all_allowed(
            self.jj,
            [
                f"bash -c '(cd {repo} && git log -1)'",
                f"eval '(cd {repo} && git log -1)'",
            ],
        )

    def test_outer_substitutions_in_reparsed_strings(self) -> None:
        """An outer $(…) inside a -c or eval string does not crash."""
        self.assert_all_allowed(
            self.jj,
            [
                'bash -c "echo $(date)"',
                'eval "$(ssh-agent -s)"',
                'nu -c "ls $(pwd)"',
            ],
        )

    def test_subshell_closed_by_a_redirect(self) -> None:
        """`(…)>file` closes its subshell like `(…) >file`."""
        jj = self.jj
        self.assert_all_allowed(
            self.git,
            [
                f"(cd {jj} && jj log)>/dev/null; git status",
                f"(cd {jj} && jj log)>>/tmp/l; git status",
                f"(cd {jj} && jj log)&>/dev/null; git status",
            ],
        )

    def test_comment_apostrophes_do_not_hide_a_heredoc(self) -> None:
        """A quote in a comment or a nested $(…) opens nothing."""
        self.assert_all_allowed(
            self.jj,
            [
                lines("# it's used by CI", "cat > x <<'EOF'", "git st", "EOF"),
                lines(
                    'jj describe -m "$(printf \'%s\' "it\'s")"',
                    "cat > x <<'EOF'",
                    "git log",
                    "EOF",
                ),
            ],
        )

    def test_subshell_inside_a_case_arm(self) -> None:
        """A real (…) in a case arm still scopes its cd."""
        self.assert_allowed(
            self.git, f"case x in x) (cd {self.jj} && jj log) ;; esac; git st"
        )
        self.assertIsNotNone(
            self.check(
                self.git, f"case x in x) (cd {self.jj}; git status) ;; esac"
            )
        )

    def test_function_definitions_do_not_move(self) -> None:
        """A cd in a function body does not move the caller."""
        self.assert_all_allowed(
            self.git,
            [
                f"f() {{ cd {self.jj}; }}; git status",
                f"function f {{ cd {self.jj}; }}; git status",
            ],
        )

    def test_script_operand_reads_its_own_stdin(self) -> None:
        """`bash FILE <<<…` runs FILE; the string is its input."""
        self.assert_all_allowed(
            self.jj,
            [
                "bash ./tools/fill.sh <<< 'git status'",
                lines("bash ./tools/fill.sh <<'EOF'", "git status", "EOF"),
            ],
        )

    def test_dash_c_options_are_physical(self) -> None:
        """git -C, env -C and cd -P follow a link before `..`."""
        repo = self.plain / "repo"
        (repo / ".git").mkdir(parents=True)
        (repo / "sub").mkdir()
        link = self.jj / "gitlink"
        link.symlink_to(repo / "sub")
        self.assert_all_allowed(
            self.jj,
            [
                "git -C gitlink/.. status",
                "env -C gitlink/.. git status",
                "cd -P gitlink/.. && git status",
            ],
        )
        self.assert_blocked(self.jj, "cd gitlink/.. && git status", "jj")

    def test_flag_forms_without_a_jj_equivalent_round_four(self) -> None:
        """Pull refs, object ids, remote show and the like pass."""
        sha = "0123456789abcdef0123456789abcdef01234567"
        self.assert_all_allowed(
            self.jj,
            [
                "git fetch origin pull/123/head",
                f"git fetch origin {sha}",
                "git remote show origin",
                "git tag -n",
                "git tag -n5 -l 'v*'",
                "git fetch --filter=blob:none origin",
                "git ls-files -s",
                "git ls-files --stage",
                "git grep -A3 foo",
                "git rev-list --objects HEAD",
            ],
        )
        self.assert_blocked(self.jj, "git fetch origin feature/x", "--branch")

    def test_arrays_filled_from_a_substitution(self) -> None:
        """`x=($(git …))` runs the substitution."""
        self.assert_all_blocked(
            self.jj,
            [
                "files=($(git ls-files '*.nix'))",
                "declare -a changed=($(git diff --name-only))",
            ],
        )
        self.assertIsNotNone(self.check(self.wt, "arr=($(jj log))"))

    def test_option_clusters_ending_in_o(self) -> None:
        """`bash -euo pipefail -c` still reaches its -c string."""
        self.assert_all_blocked(
            self.jj,
            [
                "bash -euo pipefail -c 'git status'",
                "bash -eo pipefail -c 'git log -1'",
            ],
        )

    def test_unquoted_heredoc_bodies_expand(self) -> None:
        """In <<EOF, but not <<'EOF', $(…) and backticks run."""
        self.assert_all_blocked(
            self.jj,
            [
                lines(
                    "cat > notes.md <<EOF",
                    "Head: $(git rev-parse HEAD)",
                    "EOF",
                ),
                lines("cat <<EOF", "rev: `git log -1`", "EOF"),
            ],
        )
        self.assert_allowed(
            self.jj, lines("cat <<'EOF'", "$(git rev-parse HEAD)", "EOF")
        )
        self.assertIsNotNone(
            self.check(self.wt, lines("cat <<EOF", "$(jj log -r @)", "EOF"))
        )

    def test_find_exec_and_direnv_exec(self) -> None:
        """find -exec and direnv exec run a program."""
        self.assert_all_blocked(
            self.jj,
            [
                "find . -name '*.nix' -exec git log -1 -- {} \\;",
                "direnv exec . git status",
            ],
        )
        self.assert_allowed(self.jj, f"direnv exec {self.git} git status")

    def test_echo_piped_into_a_shell(self) -> None:
        """A fixed echo or printf piped into a shell is its script."""
        self.assert_all_blocked(
            self.jj,
            ["echo 'git status' | bash", "printf 'git log\\n' | sh"],
        )
        self.assert_allowed(self.jj, "echo 'git status' | cat")

    def test_unparseable_commands_pass(self) -> None:
        """What the bash grammar cannot parse whole is let through."""
        self.assert_allowed(self.jj, "print -l ${(f)x}; git status")

    def test_find_execdir_runs_somewhere_unknown(self) -> None:
        """-execdir and -okdir run in each match's own directory."""
        self.assert_all_allowed(
            self.jj,
            [
                f"find {self.plain} -execdir git status \\;",
                f"find {self.plain} -okdir git status \\;",
            ],
        )
        self.assertIsNotNone(self.check(self.jj, "find . -exec git log \\;"))

    def test_pushd_n_and_popd_arguments(self) -> None:
        """pushd -n and popd -n or +N change no directory."""
        jj, plain = self.jj, self.plain
        self.assert_allowed(plain, f"pushd -n {jj} >/dev/null; git status")
        self.assert_all_allowed(
            jj,
            [
                f"pushd {plain} >/dev/null; popd -n >/dev/null; git status",
                f"pushd {plain} >/dev/null; popd +1 >/dev/null; git status",
            ],
        )

    def test_nu_subexpressions_run(self) -> None:
        """In nu, (…) runs its command."""
        self.assertIsNotNone(self.check(self.jj, "nu -c '(git status)'"))
        self.assertIsNotNone(self.check(self.wt, "nu -c '(jj log)'"))

    def test_heredoc_reaches_a_shell_stage_with_more_after_it(self) -> None:
        """`cat <<A | bash 2>/dev/null` and `| bash | cat` run the body."""
        self.assert_all_blocked(
            self.jj,
            [
                lines("cat <<'A' | bash 2>/dev/null", "git status", "A"),
                lines("cat <<'A' | bash | cat", "git status", "A"),
            ],
        )

    def test_bad_printf_escape_checks_the_rest(self) -> None:
        """A printf escape that cannot decode spares nothing else."""
        self.assertIsNotNone(
            self.check(self.jj, "printf 'done\\x' | sh; git status")
        )

    def test_nu_reads_no_script_on_stdin(self) -> None:
        """nu without a tty runs nothing from stdin."""
        self.assert_all_allowed(
            self.jj, ["echo 'git status' | nu", "nu <<< 'git status'"]
        )

    def test_braces_placeholder_is_unknowable(self) -> None:
        """find's and xargs' {} name a path the guard cannot know."""
        repo = self.git
        self.assert_all_allowed(
            self.jj,
            [
                f"find {repo} -name .git -exec git -C {{}}/.. status \\;",
                f"ls -d {repo}/.git | xargs -I{{}} git -C {{}}/.. status",
                f"ls -d {repo}/.git | xargs -I % git -C %/.. status",
            ],
        )

    def test_stash_beyond_creating_one(self) -> None:
        """jj sees no git stash, so reading or applying one passes."""
        self.assert_all_allowed(
            self.jj,
            ["git stash list", "git stash show -p", "git stash apply 0"],
        )
        self.assert_all_blocked(
            self.jj, ["git stash", "git stash push -m x", "git stash -m x"]
        )

    def test_plumbing_quiet_checks(self) -> None:
        """diff-index and diff-files answer --quiet by exit status."""
        self.assert_all_allowed(
            self.jj,
            ["git diff-index --quiet HEAD --", "git diff-files --quiet"],
        )

    def test_finishing_git_in_progress_state(self) -> None:
        """--abort and --continue act on state only git holds."""
        self.assert_all_allowed(
            self.jj,
            [
                "git rebase --abort",
                "git merge --abort",
                "git merge --continue",
                "git cherry-pick --abort",
                "git revert --skip",
            ],
        )

    def test_herestring_on_a_compound_statement(self) -> None:
        """`while …; done <<< "$(git …)"` runs the substitution."""
        self.assert_all_blocked(
            self.jj,
            [
                'while read -r s; do echo "$s"; done <<< "$(git rev-list HEAD)"',
                'if true; then :; fi <<< "$(git log)"',
            ],
        )

    def test_runners_this_machine_uses(self) -> None:
        """fnox exec and jouet's runners run the command after --."""
        self.assert_all_blocked(
            self.jj,
            [
                "fnox exec -- git push",
                "jouet job start b -- git fetch",
                "jouet test --cmd -- git diff",
                "jouet wait cmd -- git status",
            ],
        )

    def test_bash_s_with_arguments_reads_stdin(self) -> None:
        """With -s, operands are arguments and stdin is the script."""
        self.assert_all_blocked(
            self.jj,
            [
                lines("bash -s -- arg <<'EOF'", "git status", "EOF"),
                "echo 'git status' | bash -s -- x",
            ],
        )

    def test_named_coproc_and_trailing_continuation(self) -> None:
        """coproc NAME { … } runs its body; a trailing \\ is harmless."""
        self.assert_all_blocked(
            self.jj, ["coproc PROC { git log; }", "git log -5 \\\n"]
        )

    def run_main(self, stdin: str) -> tuple[int, str]:
        """Run main() on `stdin`; return its exit code and stderr."""
        err = io.StringIO()
        reader: Callable[[], str] = io.StringIO(stdin).read
        with redirect_stderr(err):
            code = vcs_guard.main(reader)
        return code, err.getvalue()

    def test_main_exit_codes(self) -> None:
        """Exit 2 with the message on stderr blocks; 0 allows."""
        event = {"cwd": str(self.jj), "tool_input": {"command": "git st"}}
        code, err = self.run_main(json.dumps(event))
        self.assertEqual(code, 0)
        event["tool_input"]["command"] = "git status"
        code, err = self.run_main(json.dumps(event))
        self.assertEqual(code, 2)
        self.assertIn("jj status", err)
        self.assertEqual(self.run_main("not json"), (0, ""))


if __name__ == "__main__":
    unittest.main()
