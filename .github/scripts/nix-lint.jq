# nixf counts lines and columns from zero, and leaves each `{}` in the
# message for the matching entry of `args`.
.[]
| (reduce .args[] as $arg (.message; sub("\\{\\}"; $arg))) as $message
| "\($file):\(.range.lCur.line + 1):\(.range.lCur.column + 1): \($message) [\(.sname)]"
