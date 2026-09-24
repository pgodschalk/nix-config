{ lib, substituteFile, ... }:
let
  plist = "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory";
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter (
    substituteFile ./analytics/set-diagnostics.sh { plist = lib.escapeShellArg plist; }
  );
}
