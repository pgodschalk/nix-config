# Removes every agent-hook group that runs one of the commands this
# repository's modules declare.
def declared_here:
  (.command? // "") as $command
  | ($command | endswith("/bin/claude-vcs-guard"))
    or ($command | endswith("/bin/claude-md-lint"))
    or ($command | contains("jouet hook claude "))
    or ($command | contains("rex __internal session-start"));

if .hooks then
  .hooks |= map_values(map(select(any(.hooks[]?; declared_here) | not)))
else
  .
end
