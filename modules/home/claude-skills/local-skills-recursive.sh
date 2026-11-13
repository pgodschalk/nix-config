# shellcheck shell=bash

# The reader of a recursive directory does not descend into a linked
# directory, and a checkout outside the store cannot be walked at
# build time, so each local skill is mirrored into every recursive
# directory as real directories of file links.
recursiveDirs=(@recursiveDirs@)
localSkills=(@localSkills@)

for dir in "${recursiveDirs[@]}"; do
  for skill in "${localSkills[@]}"; do
    name=${skill%%=*}
    src=${skill#*=}
    dest="$dir/$name"

    if [ ! -f "$src/SKILL.md" ]; then
      echo "claude-skills: no $src/SKILL.md; skipping $name in $dir" >&2
      continue
    fi

    run rm -rf "$dest"
    (cd "$src" && find . \( -name .git -o -name .jj \) -prune -o -type f -print) \
      | while IFS= read -r file; do
        file=${file#./}
        run mkdir -p "$(dirname "$dest/$file")"
        run ln -s "$src/$file" "$dest/$file"
      done
  done
done
