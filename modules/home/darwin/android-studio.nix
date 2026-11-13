{ config, ... }:
let
  androidHome = "${config.xdg.dataHome}/android";
in
{
  # Android Studio itself comes from the android-studio cask in
  # apps.nix; the SDK it downloads goes to ~/Library/Android/sdk, where
  # Orca's emulator looks without being told.
  #
  # adb reads only HOME and keeps its key in ~/.android whatever these
  # say; the emulator copies that key from there.

  home.sessionVariables = {
    # Android Studio and the SDK tools keep their settings here, and
    # fall back to ~/.android without it.
    ANDROID_USER_HOME = androidHome;

    # The emulator reads neither ANDROID_USER_HOME nor its avd/, so an
    # emulator started outside Android Studio, as Orca's is, finds no
    # AVDs and writes its own state to ~/.android without these two.
    ANDROID_AVD_HOME = "${androidHome}/avd";
    ANDROID_EMULATOR_HOME = androidHome;

    # The Gradle builds Android Studio runs keep their caches and daemon
    # state here, and fall back to ~/.gradle without it.
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
  };

  my.launchd.extraVariables = [
    "ANDROID_AVD_HOME"
    "ANDROID_EMULATOR_HOME"
    "ANDROID_USER_HOME"
    "GRADLE_USER_HOME"
  ];
}
