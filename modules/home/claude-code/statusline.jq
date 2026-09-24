[
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // ""),
    (.workspace.project_dir // ""),
    (.output_style.name // ""),
    (.context_window.used_percentage // ""),
    (.context_window.remaining_percentage // ""),
    (.cost.total_cost_usd // 0)
] |
    .[] |
    tostring |
    gsub("[\n\r\t]"; " ")
