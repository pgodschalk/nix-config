{ ... }:
{
  # Setapp is a manual install, since it manages and updates other apps.
  # The same domain holds the subscription, customer ids and analytics
  # ids, so individual keys are written rather than the whole domain.
  targets.darwin.defaults."com.setapp.DesktopClient" = {
    # Show in Finder sidebar
    ShouldLoadFinderSyncExtensionOnLaunch = false;
    # Suggestions to rate installed apps
    shouldDisableRateRecentAppWindow = true;
    # Suggestions to share feedback
    shouldDisableFeedbackWindow = true;
    # Notifications about new apps
    shouldBlockNewAppsNotifications = true;
    # Notifications about unused apps
    shouldBlockUnusedAppsNotifications = true;
    # Tips and special offers
    shouldBlockSpecialOffersNotifications = true;
    # Menu bar -> "Show Setapp icon", whose icon is SetappLauncher.
    EnableLauncher = false;
  };
}
