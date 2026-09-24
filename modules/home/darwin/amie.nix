{ ... }:
{
  # The only one of Amie's settings that is local: the date format and
  # which calendars are shown belong to the Amie account, and the Apple
  # Calendar connection is a macOS permission.
  #
  # "Hide notch for others" keeps its notch pill out of screen sharing
  # and recordings.
  targets.darwin.defaults."so.amie.electron-app-setapp".hideNotchFromCapture = true;
}
