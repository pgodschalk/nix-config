# Release-binary builder implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** One builder behind every release binary in `pkgs/`, so a package file
is its pin and its metadata and nothing else.

**Architecture:** `pkgs/lib/release-binary.nix` is a `callPackage`-able function
taking the pin and per-system assets and producing the derivation; eight package
files and the impeccable engine become thin callers. `pkgs/python-lsp-wheel.nix`
keeps its own unpack and install but takes one version with per-system wheels.
`pkgs/lib/bun-package.nix` does the same for the three npm tarballs bun runs.
Nothing outside `pkgs/` changes except the two modules that call the wheel
builder and the engine.

**Tech Stack:** Nix (nixpkgs `stdenvNoCC.mkDerivation`, `fetchurl`,
`autoPatchelfHook`, `darwin.autoSignDarwinBinariesHook`, `makeWrapper`), bash
scripts beside their modules, the repository's check scripts.

**Spec:** the "Spec" section below; it is the card 3 decision record from the
2026-10-21 architecture review, copied so the plan travels with it.

## Spec

- `pkgs/lib/release-binary.nix`, called with the arguments listed under Task 2
  Interfaces: the pin, per-system assets, the binaries, extra build inputs and
  meta. URLs are plain strings per system and `@VERSION` stays on the line above
  `version`. The archive kind is derived from the URL rather than passed:
  `.tar.*`, `.tgz` and `.tar` unpack as tar, `.zip` as zip, a bare `.gz` is
  gunzipped to the first binary, and anything else is a bare file copied to the
  first binary.
- All eight migrate: agnix-lsp (two assets, two binaries), css-variable-lsp,
  deps-lsp, package-swift-lsp (zip, extra Linux build inputs), covhl (gzip),
  metal-analyzer, nomad-ls, path-server (bare file). The impeccable engine
  leaves `claude-skills.nix` for `pkgs/impeccable-engine.nix`; the
  skill-to-engine version assertion stays in `claude-skills.nix`, reading the
  package's `version`.
- `pkgs/python-lsp-wheel.nix` takes one version and per-system `{ url; hash }`;
  fastapi-lsp and sqlalchemy-lsp are deleted (no consumer: Zed disables both by
  name, Helix never lists them).
- `pkgs/lib/bun-package.nix` takes the arguments listed under Task 8 Interfaces,
  for skill-language-server, mermaid-formatter and resend-cli; `postInstall` is
  a file beside the package.
- Verification is by output contents, not path: `diff -r` the old and new store
  paths of each package, plus both evaluations.

## Global Constraints

- Every `nix` command runs with the Bash sandbox off; inside it `nix` cannot
  write its cache.
- Flakes and every check see only tracked files: `git add` a new file before any
  `nix` command or check script, or the error names the file.
- Comments: none that recount history; at most 72 columns; the header comment of
  each package file is kept, and only the lines describing the boilerplate that
  moves into the builder are dropped.
- Shell scripts carry `# shellcheck shell=bash` first and a justified `disable`
  for each variable Nix sets.
- Commits: Conventional Commits, subject at most 50 characters, body at 72, no
  trailers, `git -c commit.gpgsign=false commit`. This worktree is git-driven
  (no `.jj`).
- Check scripts to run after every task, from the worktree root:
  `.github/scripts/nix-format.sh`, `.github/scripts/nix-lint.sh`,
  `.github/scripts/shell-lint.sh`, `.github/scripts/shell-format.sh`, and both
  evaluations:

  ```sh
  .github/scripts/nix-eval.sh \
    '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
  .github/scripts/nix-eval.sh \
    '.#homeConfigurations."patrick@linux".activationPackage.drvPath'
  ```

- The build recipe, saved once to `$TMPDIR/build-pkg.sh` by Task 1 and used by
  every later task; it prints the output path of one package file built through
  the Mac host's own `pkgs`:

  ```sh
  #!/usr/bin/env bash
  # usage: build-pkg.sh pkgs/NAME.nix
  set -euo pipefail
  nix build --impure --no-link --print-out-paths --expr "
    let
      f = builtins.getFlake (toString ./.);
      p = f.darwinConfigurations.Patricks-MacBook-Pro.pkgs;
    in
    p.callPackage ./$1 { }"
  ```

- Activation is Patrick's: no `darwin-rebuild`, not even `build`.

## Review Focus

1. A release whose URL ends in `.tar.xz` or `.tbz`: the kind must be tar, not a
   bare file installed as the binary. Pinned by the `passthru.archive` test in
   Task 2.
2. A package with no asset for the evaluating system: reading `meta.platforms`
   must not throw, forcing the derivation must throw a message naming the
   package and system. Pinned in Task 2.
3. A package whose binary name differs from `pname` and whose asset is a bare
   file (the impeccable engine): the file must land under the binary's name.
   Pinned in Task 6.
4. A module that lists a wheel with no entry for the evaluating system must get
   no package rather than an error, as today. Pinned in Task 7.
5. A bun package whose `postInstall` runs the built wrapper must run it offline;
   `--no-install` is what keeps bun off the network. Pinned by the resend-cli
   diff in Task 8, whose completions file is generated by running the wrapper at
   build time.

---

### Task 1: Baseline outputs

**Files:**

- Create: `$TMPDIR/build-pkg.sh` (outside the repository)
- Create: `$TMPDIR/baseline.txt` (outside the repository)

**Interfaces:**

- Produces: `$TMPDIR/baseline.txt`, one `NAME<TAB>/nix/store/...` line per
  package, which every later task diffs against.

- [ ] **Step 1: Save the build recipe**

Write the recipe from Global Constraints to `$TMPDIR/build-pkg.sh` and
`chmod +x` it.

- [ ] **Step 2: Build every package in scope on the untouched tree**

```sh
for name in agnix-lsp css-variable-lsp deps-lsp package-swift-lsp \
  covhl metal-analyzer nomad-ls path-server \
  skill-language-server mermaid-formatter resend-cli; do
  printf '%s\t%s\n' "$name" "$("$TMPDIR/build-pkg.sh" "pkgs/$name.nix")" \
    >>"$TMPDIR/baseline.txt"
done
```

Expected: eleven lines, every path under `/nix/store`.

- [ ] **Step 3: Build the two wheels that survive**

```sh
nix build --impure --no-link --print-out-paths --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.darwinConfigurations.Patricks-MacBook-Pro.pkgs;
    m = import ./modules/home/python-lsps-wheels.nix {
      inherit (p) lib;
      pkgs = p;
    };
  in
  m.home.packages'
```

Expected: four paths. Append the `pytest-language-server-0.24.0` and
`django-language-server-6.1.1` ones to `baseline.txt` under those names.

- [ ] **Step 4: Record the engine's version string**

Run `"$IMPECCABLE_BIN" --version` in a login shell. Expected: `0.1.16+engine`.
The engine is re-signed by the builder, so its bytes change on purpose and this
string is its check in Task 6.

---

### Task 2: The builder, proven on deps-lsp

**Files:**

- Create: `pkgs/lib/release-binary.nix`
- Create: `pkgs/lib/release-binary/install.sh`
- Create: `pkgs/lib/release-binary/unpack-gzip.sh`
- Create: `pkgs/lib/release-binary/unpack-file.sh`
- Modify: `pkgs/deps-lsp.nix` (whole file)
- Delete: `pkgs/deps-lsp/install.sh`

**Interfaces:**

- Produces: `pkgs/lib/release-binary.nix`, a function callable through
  `callPackage` with these arguments beyond what `pkgs` supplies:

  ```nix
  {
    pname, # string
    version, # string
    assets, # attrsOf (either { url; hash } or listOf { url; hash })
    binaries ? [ pname ], # listOf string, installed to $out/bin
    buildInputs ? [ ], # appended to the Linux patchelf inputs
    meta, # description, homepage, license, mainProgram; platforms added
  }
  ```

  The derivation it returns carries `passthru.archive`, one of `"tar"`, `"zip"`,
  `"gzip"`, `"file"`, derived from the first asset's URL.

- [ ] **Step 1: Write the archive-kind test**

Save to `$TMPDIR/archive-kind.sh`:

```sh
#!/usr/bin/env bash
set -euo pipefail
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.darwinConfigurations.Patricks-MacBook-Pro.pkgs;
    mk = url: p.callPackage ./pkgs/lib/release-binary.nix {
      pname = "probe";
      version = "0";
      assets.aarch64-darwin = { inherit url; hash = p.lib.fakeHash; };
      meta = { };
    };
  in
  map (u: (mk "https://x/probe${u}").archive)
    [ ".tar.gz" ".tar.xz" ".tgz" ".zip" ".gz" "-darwin-arm64" ]'
```

Expected once Step 3 is done: `["tar","tar","tar","zip","gzip","file"]`.

- [ ] **Step 2: Run it to see it fail**

Run: `git add pkgs/lib; bash "$TMPDIR/archive-kind.sh"` Expected: an error
naming `pkgs/lib/release-binary.nix` as missing.

- [ ] **Step 3: Write `pkgs/lib/release-binary.nix`**

Function header as in Interfaces, plus `lib`, `stdenvNoCC`, `stdenv`,
`fetchurl`, `darwin`, `autoPatchelfHook`, `unzip` from `pkgs`. In a `let`: the
asset for `stdenvNoCC.hostPlatform.system` with
`or (throw "${pname}: no upstream release asset for ${system}")`; the kind from
the first asset's URL (`lib.hasInfix ".tar."` or suffix `.tgz`, `.tar`, `.tbz`
is tar; suffix `.zip` is zip; suffix `.gz` is gzip; else file). The derivation:
`src` for a single asset, `srcs` for a list, each through `fetchurl`;
`sourceRoot = "."`; `dontBuild`; `binaries` passed as an attribute so the script
sees it as a space-separated list; `nativeBuildInputs` is `unzip` for zip, the
Darwin signing hook on Darwin, `autoPatchelfHook` on Linux; `buildInputs` is
`stdenv.cc.cc.lib` on Linux followed by the caller's; `unpackPhase` is
`unpack-gzip.sh` or `unpack-file.sh` only for those kinds, through
`lib.optionalAttrs`; `installPhase` is `install.sh`;
`meta = { platforms = lib.attrNames assets; } // meta`; `passthru.archive` is
the kind.

Comments to carry over from the eight packages, once, at the attribute they
explain: Linux assets are glibc binaries with the FHS loader, so autoPatchelf
points them at the store; every archive here holds its binaries at the root with
no leading directory; a bare `.gz` or a bare file is unpacked to the first name
in `binaries`.

- [ ] **Step 4: Write the three scripts**

`install.sh`: `runHook preInstall`, then for each word in `$binaries` an
`install -Dm755 "$binary" "$out/bin/$binary"`, then `runHook postInstall`.
`unpack-gzip.sh`: `runHook preUnpack`, `gzip -cd "$src" >"${binaries%% *}"`,
`runHook postUnpack`. `unpack-file.sh`: the same with
`cp "$src" "${binaries%% *}"`. Each starts with `# shellcheck shell=bash` and a
one-line comment naming the variables Nix sets with the matching `disable`.

- [ ] **Step 5: Run the archive-kind test**

Run: `git add pkgs/lib; bash "$TMPDIR/archive-kind.sh"` Expected:
`["tar","tar","tar","zip","gzip","file"]`

- [ ] **Step 6: Run the absent-system test**

```sh
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.darwinConfigurations.Patricks-MacBook-Pro.pkgs;
    d = p.callPackage ./pkgs/lib/release-binary.nix {
      pname = "probe";
      version = "0";
      assets.x86_64-linux = { url = "https://x/p.tgz"; hash = p.lib.fakeHash; };
      meta = { };
    };
  in
  [ d.meta.platforms (builtins.tryEval d.outPath).success ]'
```

Expected: `[["x86_64-linux"],false]`. Then the same expression with `d.outPath`
alone must fail with a message containing
`probe: no upstream release asset for aarch64-darwin`.

- [ ] **Step 7: Rewrite `pkgs/deps-lsp.nix`**

Keep the header comment. The file becomes `{ lib, callPackage }:`, a `let`
holding `# @VERSION https://github.com/bug-ops/deps-lsp/releases` above
`version = "3.0.0";`, and `callPackage ./lib/release-binary.nix { ... }` with
`pname`, `inherit version`, `assets` for aarch64-darwin, aarch64-linux and
x86_64-linux (each the full URL with `${version}` and the hash now in the file),
and `meta` with the current description, homepage, `lib.licenses.mit` and
`mainProgram`. Delete `pkgs/deps-lsp/install.sh` with `git rm`.

- [ ] **Step 8: Diff the output against the baseline**

```sh
old=$(awk -F '\t' '$1 == "deps-lsp" { print $2 }' "$TMPDIR/baseline.txt")
diff -r "$old" "$("$TMPDIR/build-pkg.sh" pkgs/deps-lsp.nix)" \
  && echo identical
```

Expected: `identical`.

- [ ] **Step 9: Run the check scripts and both evaluations**

Run the six commands from Global Constraints. Expected: each exits 0;
`nix-lint.sh` prints nothing; `shell-lint.sh` prints nothing. If shellcheck
reports SC2086 on the `for` loop over `$binaries`, add that code to the script's
existing `disable` line, since the split is the point.

- [ ] **Step 10: Commit**

```sh
git add pkgs/lib pkgs/deps-lsp.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): add a release-binary builder"
```

Body: the eight release packages repeat the same fetch, sign, patchelf and
install; one builder takes the pin and the assets, deps-lsp is the first caller,
and output contents are unchanged.

---

### Task 3: The plain tarballs

**Files:**

- Modify: `pkgs/css-variable-lsp.nix`, `pkgs/metal-analyzer.nix`,
  `pkgs/nomad-ls.nix` (whole files)
- Delete: `pkgs/css-variable-lsp/install.sh`, `pkgs/metal-analyzer/install.sh`,
  `pkgs/nomad-ls/install.sh`

**Interfaces:**

- Consumes: `pkgs/lib/release-binary.nix` from Task 2.

- [ ] **Step 1: Rewrite the three files in the Task 2 Step 7 shape**

css-variable-lsp: three assets, `lib.licenses.gpl3Only`. metal-analyzer: one
aarch64-darwin asset, `mit`, version from the `finalAttrs` form moves into the
`let`. nomad-ls: one aarch64-darwin asset, `lib.licenses.unfree` with its
comment, version likewise. `git rm` the three `install.sh` files.

- [ ] **Step 2: Diff each output against the baseline**

Run the Task 2 Step 8 command for each of the three names. Expected: `identical`
three times.

- [ ] **Step 3: Confirm the unfree allowlist still matches**

Run:

```sh
nix eval --impure --raw --expr '
  ((builtins.getFlake (toString ./.)).darwinConfigurations
    .Patricks-MacBook-Pro.pkgs.callPackage ./pkgs/nomad-ls.nix { }).pname'
```

Expected: `nomad-ls`, the name `my.allowUnfree` lists.

- [ ] **Step 4: Run the check scripts and both evaluations**

Expected: all clean.

- [ ] **Step 5: Commit**

```sh
git add pkgs/css-variable-lsp.nix pkgs/metal-analyzer.nix pkgs/nomad-ls.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): build tarball releases with the builder"
```

---

### Task 4: Zip, gzip and bare file

**Files:**

- Modify: `pkgs/package-swift-lsp.nix`, `pkgs/covhl.nix`, `pkgs/path-server.nix`
  (whole files)
- Delete: `pkgs/package-swift-lsp/install.sh`, `pkgs/covhl/install.sh`,
  `pkgs/covhl/unpack.sh`, `pkgs/path-server/install.sh`

**Interfaces:**

- Consumes: `pkgs/lib/release-binary.nix` from Task 2.

- [ ] **Step 1: Rewrite package-swift-lsp**

Header comment kept. `{ lib, stdenv, callPackage, curl, sqlite }:`; three `.zip`
assets;
`buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ curl sqlite ];`;
`mit`.

- [ ] **Step 2: Rewrite covhl**

Header comment kept, including the signing rationale. Three `.gz` assets; `mit`.
The builder's gzip kind replaces `covhl/unpack.sh`.

- [ ] **Step 3: Rewrite path-server**

Header comment kept. One bare-file aarch64-darwin asset; `asl20`. The builder's
file kind replaces `dontUnpack`.

- [ ] **Step 4: Diff each output against the baseline**

Expected: `identical` for all three.

- [ ] **Step 5: Run the check scripts and both evaluations**

Expected: all clean.

- [ ] **Step 6: Commit**

```sh
git add pkgs/package-swift-lsp.nix pkgs/covhl.nix pkgs/path-server.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): absorb zip, gzip and bare releases"
```

---

### Task 5: agnix-lsp, two assets and two binaries

**Files:**

- Modify: `pkgs/agnix-lsp.nix` (whole file)
- Delete: `pkgs/agnix-lsp/install.sh`

**Interfaces:**

- Consumes: `pkgs/lib/release-binary.nix` from Task 2, the list form of
  `assets.<system>` and `binaries`.

- [ ] **Step 1: Rewrite agnix-lsp**

Header comment kept. Each system's asset is a two-element list: the
`agnix-lsp-<triple>.tar.gz` URL with the current `lspHash`, then the
`agnix-<triple>.tar.gz` URL with the current `cliHash`.
`binaries = [ "agnix-lsp" "agnix" ];`
`license = with lib.licenses; [ mit asl20 ];` `mainProgram = "agnix-lsp"`.

- [ ] **Step 2: Diff the output against the baseline**

Expected: `identical`, and `ls "$new/bin"` lists `agnix` and `agnix-lsp`.

- [ ] **Step 3: Run the check scripts and both evaluations**

Expected: all clean.

- [ ] **Step 4: Commit**

```sh
git add pkgs/agnix-lsp.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): build agnix-lsp with the builder"
```

---

### Task 6: The impeccable engine becomes a package

**Files:**

- Create: `pkgs/impeccable-engine.nix`
- Modify: `modules/home/claude-skills.nix:286-333` and `:394-395`
- Delete: `modules/home/claude-skills/impeccable-engine.sh`

**Interfaces:**

- Consumes: `pkgs/lib/release-binary.nix` from Task 2.
- Produces: `pkgs/impeccable-engine.nix`, a derivation with
  `version = "0.1.16"`, `bin/impeccable`, platforms aarch64-darwin,
  aarch64-linux, x86_64-linux.

- [ ] **Step 1: Write `pkgs/impeccable-engine.nix`**

Header comment: the engine behind the impeccable skill, pinned so the launcher
never reaches its download branch and never creates `~/.impeccable`; it must
equal the skill's `scripts/VERSION`, which `modules/home/claude-skills.nix`
asserts. `{ lib, callPackage }:`; the
`@VERSION https://github.com/pbakaus/impeccable/releases` line above
`version = "0.1.16"`; assets at
`https://github.com/pbakaus/impeccable/releases/download/engine-v${version}/`
followed by `impeccable-darwin-arm64`, `impeccable-linux-arm64`,
`impeccable-linux-x64`, with the three hashes now at
`claude-skills.nix:301-313`; `binaries = [ "impeccable" ];`; meta with
description "Engine behind the impeccable design skill", homepage
`https://github.com/pbakaus/impeccable`, `lib.licenses.asl20`,
`mainProgram = "impeccable"`.

- [ ] **Step 2: Rewire `claude-skills.nix`**

Replace lines 297-333 (`impeccableEngineVersion` through the `runCommand`) with:

```nix
impeccableEngine =
  let
    engine = pkgs.callPackage ../../pkgs/impeccable-engine.nix { };
  in
  assert lib.assertMsg (impeccableSkillVersion == engine.version) (
    "claude-skills: impeccable's skill wants engine ${impeccableSkillVersion},"
    + " but pkgs/impeccable-engine.nix is ${engine.version}"
  );
  if lib.meta.availableOn pkgs.stdenv.hostPlatform engine then engine else null;
```

Keep the comment block at lines 286-295 about `$IMPECCABLE_BIN` above it,
dropping its last sentence about the assertion "below". Lines 394-395 stay as
they are. `git rm` `claude-skills/impeccable-engine.sh`.

- [ ] **Step 3: Verify the assertion still trips**

Change `version` in `pkgs/impeccable-engine.nix` to `"0.1.15"`, run the macOS
evaluation. Expected: failure whose message contains
`impeccable's skill wants engine 0.1.16`. Revert the change.

- [ ] **Step 4: Verify the engine runs**

```sh
"$("$TMPDIR/build-pkg.sh" pkgs/impeccable-engine.nix)/bin/impeccable" \
  --version
```

Expected: `0.1.16+engine`.

- [ ] **Step 5: Run the check scripts and both evaluations**

Expected: all clean. The Linux evaluation exercises the x86_64-linux asset entry
and `availableOn`.

- [ ] **Step 6: Commit**

```sh
git add pkgs/impeccable-engine.nix modules/home/claude-skills.nix \
  modules/home/claude-skills
git -c commit.gpgsign=false commit \
  -m "refactor(claude-skills): package the impeccable engine"
```

---

### Task 7: One version per wheel, two wheels fewer

**Files:**

- Modify: `pkgs/python-lsp-wheel.nix:24-33` (the inner function's arguments) and
  `:38` (`src`), `:60-64` (`meta`)
- Modify: `modules/home/python-lsps-wheels.nix` (whole file)

**Interfaces:**

- Produces: `pkgs/python-lsp-wheel.nix`, whose inner function takes

  ```nix
  {
    pname,
    version,
    binary ? pname,
    wheels, # attrsOf { url; hash }, keyed by hostPlatform.system
    description,
    homepage,
    license,
  }
  ```

  throws `"${pname}: no wheel for ${system}"` when the derivation is forced on a
  system with no entry, and sets `meta.platforms` to the wheels' keys.

- [ ] **Step 1: Change the wheel builder's interface**

Replace `url, hash` with `wheels`; in a `let`, pick
`wheels.${system} or (throw ...)`;
`src = fetchurl { inherit (wheel) url hash; }`;
`meta.platforms = lib.attrNames wheels`. The outer function, the scripts and the
hooks do not change.

- [ ] **Step 2: Rewrite `modules/home/python-lsps-wheels.nix`**

```nix
home.packages =
  lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [ ... ];
```

The list holds two calls of `mkWheelLsp`: pytest-language-server (version
`0.24.0`, three wheels with the URLs and hashes now at lines 29-49, `mit`) and
django-language-server (`binary = "djls"`, version `6.1.1`, the URLs and hashes
at lines 117-137, `asl20`, with its comment about the binary name). Each
`@VERSION` line sits above its `version`. The header comment about
`hostPlatform.system`, x86_64-darwin and manylinux stays; the "Installed
globally" paragraph goes with the two packages it described.

- [ ] **Step 3: Verify the absent-system behaviour**

```sh
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.darwinConfigurations.Patricks-MacBook-Pro.pkgs;
    mk = p.callPackage ./pkgs/python-lsp-wheel.nix { };
    d = mk {
      pname = "probe"; version = "0";
      wheels.x86_64-linux = { url = "https://x/p.whl"; hash = p.lib.fakeHash; };
      description = ""; homepage = ""; license = p.lib.licenses.mit;
    };
  in
  p.lib.meta.availableOn p.stdenv.hostPlatform d'
```

Expected: `false`, with no error.

- [ ] **Step 4: Diff the two kept wheels against the baseline**

Build with the Task 1 Step 3 expression. Expected: exactly two paths, and
`diff -r` of each against its baseline line prints nothing.

- [ ] **Step 5: Run the check scripts and both evaluations**

Expected: all clean.

- [ ] **Step 6: Commit**

```sh
git add pkgs/python-lsp-wheel.nix modules/home/python-lsps-wheels.nix
git -c commit.gpgsign=false commit \
  -m "refactor(python-lsps): pin each wheel once, drop two"
```

Body: fastapi-lsp and sqlalchemy-lsp had no consumer, Zed disables both by name
and Helix never lists them; the builder now selects the wheel per system so each
version is written once.

---

### Task 8: The bun-package builder

**Files:**

- Create: `pkgs/lib/bun-package.nix`
- Create: `pkgs/lib/bun-package/install.sh`
- Create: `pkgs/resend-cli/post-install.sh`,
  `pkgs/mermaid-formatter/post-install.sh`
- Modify: `pkgs/skill-language-server.nix`, `pkgs/mermaid-formatter.nix`,
  `pkgs/resend-cli.nix` (whole files)
- Delete: `pkgs/skill-language-server/install.sh`,
  `pkgs/mermaid-formatter/install.sh`, `pkgs/resend-cli/install.sh`

**Interfaces:**

- Produces: `pkgs/lib/bun-package.nix`, callable through `callPackage` with

  ```nix
  {
    pname, # also the npm package name
    version,
    hash, # of the registry tarball
    entry, # path inside the tarball bun runs, e.g. "dist/cli.cjs"
    binary ? pname,
    copy ? [ "dist" "package.json" ], # paths copied to $out/lib/<pname>
    postInstall ? null, # a file, read into the postInstall hook
    meta, # description, homepage, license; mainProgram and platforms added
  }
  ```

- [ ] **Step 1: Write the builder and its script**

`src` is `fetchurl` of
`https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz`;
`nativeBuildInputs = [ makeWrapper ]`; `bun = lib.getExe bun` and `entry`,
`binary`, `copy` passed as attributes; `dontBuild`; `installPhase` reads
`bun-package/install.sh`; `postInstall` is
`lib.optionalString (postInstall != null) (builtins.readFile postInstall)`;
`meta = { mainProgram = binary; platforms = lib.platforms.all; } // meta`. The
header comment carries the `--no-install` rationale from
`skill-language-server.nix`.

`install.sh`, between the two `runHook` lines; the split of `$copy` is the
point, so SC2086 is disabled on that line with that reason:

```sh
mkdir -p "$out/lib/$pname"
cp -R $copy "$out/lib/$pname/"
makeWrapper "$bun" "$out/bin/$binary" \
  --add-flags --no-install \
  --add-flags "$out/lib/$pname/$entry"
```

- [ ] **Step 2: Write the two post-install files**

No `runHook` lines: these are hook bodies. `resend-cli/post-install.sh`:

```sh
mkdir -p "$out/share/fish/vendor_completions.d"
"$out/bin/resend" completion fish \
  >"$out/share/fish/vendor_completions.d/resend.fish"
```

`mermaid-formatter/post-install.sh`:

```sh
ln -s "$out/bin/mermaidfmt" "$out/bin/mermaid-formatter"
```

- [ ] **Step 3: Rewrite the three package files**

Each keeps its header comment, becomes `{ lib, callPackage }:` with the
`@VERSION` line above `version` in a `let`, and calls `./lib/bun-package.nix`.
skill-language-server: `entry = "dist/main.cjs"`. mermaid-formatter:
`entry = "dist/cli.js"`, `binary = "mermaidfmt"`,
`postInstall = ./mermaid-formatter/post-install.sh`. resend-cli:
`entry = "dist/cli.cjs"`, `binary = "resend"`,
`copy = [ "dist" "skills" "package.json" ]`,
`postInstall = ./resend-cli/post-install.sh`. `git rm` the three `install.sh`
files.

- [ ] **Step 4: Diff each output against the baseline**

Run the Task 2 Step 8 command for each. Expected: the only differing lines are
under `bin/` and each contains `/nix/store/`, since the wrapper embeds its own
output path and the mermaid-formatter symlink points at it; `lib/` and the
completions file are identical.

- [ ] **Step 5: Run the check scripts and both evaluations**

Expected: all clean.

- [ ] **Step 6: Commit**

```sh
git add pkgs/lib/bun-package.nix pkgs/lib/bun-package \
  pkgs/skill-language-server.nix pkgs/mermaid-formatter.nix \
  pkgs/mermaid-formatter pkgs/resend-cli.nix pkgs/resend-cli
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): add a bun-package builder"
```

---

### Task 9: Architecture note and final sweep

**Files:**

- Modify: `docs/architecture.md` (the `pkgs/` bullet)
- Modify: `codebook.toml` only if `codebook` flags a word in a new comment

**Interfaces:**

- Consumes: everything above.

- [ ] **Step 1: Describe `pkgs/lib/`**

Extend the `pkgs/` bullet in `docs/architecture.md` with one sentence:
`pkgs/lib/` holds the builders packages share, `release-binary.nix` for upstream
release binaries and `bun-package.nix` for npm tarballs bun runs, each called
through `callPackage` from the package file.

- [ ] **Step 2: Run every check**

Run the six commands from Global Constraints plus
`.github/scripts/markdown-format.sh` and `.github/scripts/markdown-lint.sh`.
Expected: all clean.

- [ ] **Step 3: Confirm nothing in scope is left hand-written**

```sh
grep -l autoSignDarwinBinariesHook pkgs/*.nix pkgs/lib/*.nix modules/home/*.nix
ls pkgs/*/install.sh
```

Expected: the first lists `pkgs/lib/release-binary.nix` and
`pkgs/python-lsp-wheel.nix` only; the second lists `pkgs/astro-tsdk`,
`pkgs/dockerhub-mcp-server`, `pkgs/jdtls-settings`, `pkgs/markdownlint-lsp`,
`pkgs/prettier-with-plugins`, `pkgs/python-lsp-wheel` and `pkgs/tipctl` only,
the ones outside this card's scope.

- [ ] **Step 4: Commit**

```sh
git add docs/architecture.md codebook.toml
git -c commit.gpgsign=false commit \
  -m "docs(architecture): describe the pkgs/lib builders"
```

- [ ] **Step 5: Hand over**

Report the nine commits, the diff results, and the one command left for Patrick:

```nu
sudo -H darwin-rebuild switch
```
