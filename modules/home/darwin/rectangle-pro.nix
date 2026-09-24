{
  # Rectangle Pro's bundle id is `com.knollsoft.Hookshot`;
  # `com.knollsoft.Rectangle` is the free app.
  #
  #   loc  9 means "exact placement" and is the only value that consults
  #        x/y. The others are screen anchors: 0 centre, 1 top, 2
  #        bottom, 3 left, 4 right, 5 topLeft, 6 topRight, 7 bottomLeft,
  #        8 bottomRight.
  #   x/y  offsets from the display's usable origin (bottom-left, AppKit
  #        orientation), not absolute screen coordinates. An offset past
  #        the right edge is discarded silently and the window snaps to
  #        the left edge.
  #   w/h  absolute points, as strings. A percentage such as "100%" is
  #        ignored, and the bad value also drops the position. An
  #        oversized value clamps to the usable extent, so h = "9999"
  #        expresses "full height" and re-clamps per invocation as the
  #        Dock moves between displays.
  targets.darwin.defaults."com.knollsoft.Hookshot" =
    let
      ctrl = 262144;
      opt = 524288;

      ultrawide = {
        id = "2B3D367A-9C99-4FFE-8A3E-F18F10BF315B";
        name = "LC49G95T";
        frame = [
          [
            1512
            0
          ]
          [
            5120
            1440
          ]
        ];
      };
      laptop = {
        id = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
        name = "Built-in Retina Display";
        frame = [
          [
            0
            0
          ]
          [
            1512
            982
          ]
        ];
      };

      # keyCodes are physical, so they follow the key position rather
      # than the Dutch layout's labels: 42 is the key labelled \, and
      # 33/30 are the two keys right of P.
      spec =
        {
          name,
          id,
          x,
          w,
          h,
          keyCode,
          display,
        }:
        {
          inherit name id;
          loc = 9;
          x = toString x;
          y = "0";
          w = toString w;
          h = toString h;
          # -4 selects displayID below rather than "current display".
          display = -4;
          displayID = display.id;
          displayName = display.name;
          displayFrame = display.frame;
          shortcut = {
            modifierFlags = ctrl + opt;
            inherit keyCode;
          };
        };
    in
    {
      hideMenubarIcon = 1;

      SUEnableAutomaticChecks = false;

      # 2 = off. Syncing would give the settings a second writer and let
      # a sync overwrite what activation declares.
      iCloudSync = 2;

      launchOnLogin = 1;

      # A JSON string, which is how Rectangle Pro stores it.
      manualSpecs = builtins.toJSON [
        (spec {
          name = "Left";
          id = 28;
          x = 0;
          w = 1280;
          h = 9999;
          keyCode = 33;
          display = ultrawide;
        })
        (spec {
          name = "Centre";
          id = 27;
          x = 1280;
          w = 2560;
          h = 9999;
          keyCode = 42;
          display = ultrawide;
        })
        (spec {
          name = "Right";
          id = 29;
          x = 3840;
          w = 1280;
          h = 9999;
          keyCode = 30;
          display = ultrawide;
        })
        (spec {
          name = "Laptop fill";
          id = 30;
          x = 0;
          # An absolute width, unlike the three above: an oversized
          # width clamps against the display the window is currently on
          # rather than the one the spec targets, so "9999" spans the
          # whole desktop when invoked from the external display. An
          # oversized height clamps to the target display and is safe.
          w = 1512;
          h = 9999;
          keyCode = 39;
          display = laptop;
        })
      ];
    };
}
