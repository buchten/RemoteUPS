# Remote UPS Monitor — Plasma 6

A small Plasma 6 panel widget that parses `/usr/bin/apcaccess status` every 15 seconds.
It is intended for machines where `apcaccess` gets UPS state from a remote `apcupsd` server.

No AUR package or compiled helper is required.

## Requirements

- KDE Plasma 6
- `apcupsd` / `apcaccess`
- `plasma5support` (already a dependency of Arch's `plasma-desktop`)

Verify this works first:

```bash
/usr/bin/apcaccess status
```

## Install

From the directory containing `RemoteUPS.plasmoid`:

```bash
kpackagetool6 -t Plasma/Applet -i ./RemoteUPS.plasmoid
```

Then right-click the Plasma panel, choose **Enter Edit Mode**, open **Add Widgets**, and add **Remote UPS Monitor** to the panel.

If it does not appear immediately, log out/in, or restart Plasma with:

```bash
systemctl --user restart plasma-plasmashell.service
```

If your Plasma session does not provide that user unit, use:

```bash
plasmashell --replace &
```

## Update after editing

```bash
kpackagetool6 -t Plasma/Applet -u ./RemoteUPS.plasmoid
```

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r local.remoteups.monitor
```

## Behavior

- Refreshes every 15 seconds.
- Compact panel view uses a horizontal battery gauge with the charge percentage inside it.
- Battery fill shrinks proportionally with `BCHARGE`.
- Gauge color is green above the warning level, orange at/below warning, and red at/below critical.
- Default thresholds are warning `50%` and critical `20%`.
- Right-click the widget and choose **Configure Remote UPS Monitor…** to change the warning and critical levels.
- Tooltip shows charge, UPS status, and remaining runtime.
- Popup shows battery, runtime, load, line voltage, battery voltage, thresholds, and last refresh time.
- The widget does not talk to the UPS itself; it only runs the already-working `apcaccess status` command.
- It is a normal panel widget and is not automatically registered as a System Tray entry.

## License

Remote UPS Monitor is licensed under the GNU General Public License v3.0 or later (`GPL-3.0-or-later`). See `LICENSE`.
