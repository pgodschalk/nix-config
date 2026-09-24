{
  config,
  lib,
  substituteFile,
  ...
}:
let
  domain = "com.tinyapp.TablePlus-setapp";
  extras = config.my.theme.dracula.extras;

  # Almost every TablePlus setting lives inside one nested dictionary,
  # alongside 100-odd keys the app manages itself. CustomUserPreferences
  # would write the whole dictionary and discard those, so each key is
  # added individually.
  viewSetting = [
    # CSV delimiter, stored as an index rather than a character; 1 is
    # the comma.
    "ExportCSVDelimiter -int 1"
    # The key means opted out, hence true.
    "IsOutOfCrashaltycs -bool true"
    "QueryEditorKeyBindingMode -int 1"
    # A fixed port, so the endpoint a repository's own MCP config names
    # stays the same.
    "MCPServerEnabled -bool true"
    "MCPServerPortMode -string fixed"
    "MCPServerPort -int 51003"
    "IsEnableLocalAuthentication -bool true"

    # Tab indentation, matching pgfmt. `TabWidthSpaces` is left alone:
    # it is how wide a tab displays, not what gets inserted.
    "IndentType -int 0"
  ];

  # Substituted into the activation script rather than written there, so
  # the pin and its annotation are nowhere near the `\` continuation
  # they would otherwise sit inside.
  # @VERSION https://platform.claude.com/docs/en/models/overview
  anthropicModel = "claude-opus-5-5";
in
{
  # TablePlus comes from SetApp, so only its settings are declared. The
  # domain is outside any sandbox container. The Anthropic API key is
  # not declared: TablePlus keeps it out of this domain.
  home.activation.tablePlusSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    substituteFile ./tableplus/settings.sh {
      inherit domain;
      model = anthropicModel;
      viewSettings = lib.concatMapStrings (
        kv: "run /usr/bin/defaults write ${domain} ViewSetting -dict-add ${kv}\n"
      ) viewSetting;
    }
  );

  # Linked into `Themes/`, which the app creates empty.
  home.file = lib.mkIf (extras != null) (
    lib.genAttrs [ "Dracula Pro.json" "Alucard.json" ] (f: {
      target = "Library/Application Support/${domain}/Themes/${f}";
      source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/tableplus/${f}";
    })
  );
}
