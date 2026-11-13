# `.` is the array of JSON values in the app's file; $old[0] is what
# was declared last time, $new[0] what is declared now, and
# $oldStrategies[0] and $strategies[0] are the strategies last time
# and now, in the declared value's shape: a string names "replace" or
# "union" for the key at its path. Every other key is merged by
# default: a leaf declared before and not now is removed, along with
# any object that removal leaves empty, then the declaration is merged
# over what is left.

# An array is a leaf: a declared one replaces whatever the file holds
# at its path.
def leaves:
  if type == "object" then
    [to_entries[] | .key as $key | .value | leaves[] | [$key] + .]
  else
    [[]]
  end;

def prune($path):
  if ($path | length) > 1 and getpath($path[:-1]) == {} then
    delpaths([$path[:-1]]) | prune($path[:-1])
  else
    .
  end;

# Whether `.` holds a value at $path, reached through objects alone.
def has_path($path):
  if $path == [] then
    true
  else
    type == "object" and has($path[0]) and (.[$path[0]] | has_path($path[1:]))
  end;

def strategy_paths:
  [paths(type == "string") as $path | [$path, getpath($path)]];

# Deletes each of $paths that `.` holds, with any object that leaves
# empty.
def without_paths($paths):
  reduce $paths[] as $path (
    .;
    if has_path($path) then delpaths([$path]) | prune($path) else . end
  );

def merge_default($old; $new):
  ($new | leaves) as $keep
  | reduce ($old | leaves[]) as $path (
      .;
      if any($keep[]; . == $path) then . else delpaths([$path]) | prune($path) end
    )
  | . * $new;

def merge_replace($path; $old; $new):
  if $new | has_path($path) then
    setpath($path; $new | getpath($path))
  elif ($old | has_path($path)) and has_path($path) then
    delpaths([$path])
  else
    .
  end;

def without($elements):
  map(select(. as $element | any($elements[]; . == $element) | not));

# Keeps the file's elements at $path in their order, minus those
# declared last time and not now, then appends each declared element
# the file lacks, comparing by value. A key no longer declared is left
# alone once the file has dropped it, rather than written back empty.
def merge_union($path; $old; $new):
  def declared($from):
    if $from | has_path($path) then $from | getpath($path) // [] else [] end
    | if type == "array" then . else error("\($path | join(".")) is declared as \(type), not an array") end;

  if ($new | has_path($path)) or (($old | has_path($path)) and has_path($path)) then
    (getpath($path) // []) as $current
    | if $current | type != "array" then
        error("\($path | join(".")) is \($current | type) in the file, not an array")
      else
        (declared($old) | without(declared($new))) as $dropped
        | setpath($path; reduce declared($new)[] as $element (
            $current | without($dropped);
            if any(.[]; . == $element) then . else . + [$element] end
          ))
      end
  else
    .
  end;

if length == 0 then
  {}
elif length == 1 then
  .[0]
else
  error("the file holds more than one JSON value")
end
| if type == "object" then . else error("the file holds \(type), not an object") end
| ($old[0] // {}) as $old
| $new[0] as $new
# A key no longer declared is taken back by the strategy it had, unless
# one is declared for its path now.
| (($strategies[0] // {}) | strategy_paths) as $current
| (
    (($oldStrategies[0] // {}) | strategy_paths
      | map(select(.[0] as $path
          | ($new | has_path($path) | not)
            and all($current[]; .[0] != $path))))
    + $current
  ) as $strategies
| ($strategies | map(.[0])) as $paths
| merge_default($old | without_paths($paths); $new | without_paths($paths))
| reduce $strategies[] as [$path, $strategy] (
    .;
    if $strategy == "replace" then
      merge_replace($path; $old; $new)
    elif $strategy == "union" then
      merge_union($path; $old; $new)
    else
      error("\($path | join(".")) has no strategy \($strategy)")
    end
  )
