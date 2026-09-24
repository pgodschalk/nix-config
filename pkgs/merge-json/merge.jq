# `.` is the app's file, $old[0] what was declared last time and $new[0]
# what is declared now. A leaf declared before and not now is removed,
# along with any object that removal leaves empty, then the declaration
# is merged over what is left.
def leaves: [paths(type != "object")];

def prune($path):
  if ($path | length) > 1 and getpath($path[:-1]) == {} then
    delpaths([$path[:-1]]) | prune($path[:-1])
  else
    .
  end;

($new[0] | leaves) as $keep
| reduce ($old[0] | leaves[]) as $path (
    .;
    if any($keep[]; . == $path) then . else delpaths([$path]) | prune($path) end
  )
| . * $new[0]
