# `.` is the array of JSON values in the app's file; $old[0] is what
# was declared last time, $new[0] what is declared now, and
# $oldStrategies[0] and $strategies[0] map a top-level key to "replace"
# or "union", last time and now. Every other key is merged by default:
# a leaf declared before and not now is removed, along with any object
# that removal leaves empty, then the declaration is merged over what
# is left.

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

def merge_default($old; $new):
  ($new | leaves) as $keep
  | reduce ($old | leaves[]) as $path (
      .;
      if any($keep[]; . == $path) then . else delpaths([$path]) | prune($path) end
    )
  | . * $new;

def merge_replace($key; $old; $new):
  if $new | has($key) then
    .[$key] = $new[$key]
  elif $old | has($key) then
    del(.[$key])
  else
    .
  end;

def without($elements):
  map(select(. as $element | any($elements[]; . == $element) | not));

# Keeps the file's elements under $key in their order, minus those
# declared last time and not now, then appends each declared element
# the file lacks, comparing by value. A key no longer declared is left
# alone once the file has dropped it, rather than written back empty.
def merge_union($key; $old; $new):
  def declared($from):
    $from[$key] // []
    | if type == "array" then . else error("\($key) is declared as \(type), not an array") end;

  if ($new | has($key)) or (($old | has($key)) and has($key)) then
    (.[$key] // []) as $current
    | if $current | type != "array" then
        error("\($key) is \($current | type) in the file, not an array")
      else
        (declared($old) | without(declared($new))) as $dropped
        | .[$key] = reduce declared($new)[] as $element (
            $current | without($dropped);
            if any(.[]; . == $element) then . else . + [$element] end
          )
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
# one is declared for it now.
| (
    (($oldStrategies[0] // {}) | with_entries(select(.key as $key | $new | has($key) | not)))
    + ($strategies[0] // {})
  ) as $strategies
| merge_default(
    $old | with_entries(select($strategies[.key] == null));
    $new | with_entries(select($strategies[.key] == null))
  )
| reduce ($strategies | to_entries[]) as {key: $key, value: $strategy} (
    .;
    if $strategy == "replace" then
      merge_replace($key; $old; $new)
    elif $strategy == "union" then
      merge_union($key; $old; $new)
    else
      error("\($key) has no strategy \($strategy)")
    end
  )
