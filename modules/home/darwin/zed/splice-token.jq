# initialization_options, not settings: the extension forwards no
# workspace configuration, and the server reads sessionToken only when
# it initializes.
.lsp["gh-actions-language-server"].initialization_options.sessionToken = env.ZED_GH_TOKEN
