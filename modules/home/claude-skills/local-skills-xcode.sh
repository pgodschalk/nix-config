# shellcheck shell=bash

# Xcode's plug-in importer does not descend into a symlinked directory,
# and a checkout outside the store cannot be walked at build time, so
# each local skill is mirrored here as real directories of file links.
xcodeSkillsDir=@xcodeSkillsDir@
localSkills=(@localSkills@)

for skill in "${localSkills[@]}"; do
  name=${skill%%=*}
  src=${skill#*=}
  dest="$xcodeSkillsDir/$name"

  if [ ! -f "$src/SKILL.md" ]; then
    echo "claude-skills: no $src/SKILL.md; skipping $name for Xcode" >&2
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
