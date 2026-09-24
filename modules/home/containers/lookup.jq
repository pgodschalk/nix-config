(.[$r] // empty) |
    select((.scopeDirs |
        length) == 0 or any(.scopeDirs[]; . as $d | $pwd == $d or ($pwd |
        startswith($d + "/")))) |
    .account, .vault, .item, .field
