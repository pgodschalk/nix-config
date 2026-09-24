{ pkgs, ... }:
let
  # Xcode is internally inconsistent about Swift indentation -- its
  # editor uses 4 spaces and its bundled swift-format defaults to 2 --
  # and this reconciles the two. Zed never runs it: sourcekit-lsp
  # passes the editor's own tabSize through. Helix does, because its
  # bundled entry sets an external `swift-format` formatter that takes
  # precedence over LSP formatting and cannot be unset.
  #
  # The injected configuration is a fallback, supplied only when no
  # `.swift-format` exists at or above the file.
  swiftFormat = pkgs.writeShellScriptBin "swift-format-xcode" (
    builtins.readFile ./swift/swift-format-xcode.sh
  );
in
{
  # Xcode's swift-format is reachable only through xcrun. Its
  # sourcekit-lsp and lldb-dap need no help: /usr/bin/sourcekit-lsp is
  # a Command Line Tools shim, and Zed's Swift adapter finds lldb-dap
  # through xcrun.
  home.packages = [ swiftFormat ];
}
