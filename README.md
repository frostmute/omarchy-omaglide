# On-Screen Trackpad for Omarchy Quattro

A bar-toggleable, touch-first relative pointer pad for Hyprland. Drag on the
pad to move the cursor, double-tap or use **Left click** to click, and use
**Right click** for context menus. The normal touchscreen remains the best way
to scroll content.

It uses `ydotool` to create a virtual pointer device. The plugin does not run
commands as root or install dependencies itself.

## Install

```sh
omarchy plugin add https://github.com/frostmute/omarchy-onscreen-trackpad.git --enable
```

The bar icon appears in the center section by default. Move it if desired:

```sh
omarchy bar move io.github.frostmute.onscreen-trackpad --section right
```

## One-time virtual-pointer setup

Run the bundled setup script in a visible terminal and enter your password when
prompted:

```sh
~/.config/omarchy/plugins/io.github.frostmute.onscreen-trackpad/setup.sh
```

It installs `ydotool` if necessary, grants your user access to the virtual
input device, and enables its user service. **Log out and back in, or reboot**
after the script finishes. This is required for the new `input` group membership
to take effect.

Verify the backend with:

```sh
systemctl --user status ydotool.service
```

It should report `active (running)`.

## Usage

1. Tap the trackpad icon in the bar.
2. Drag a finger over the large pad to move the cursor.
3. Double-tap the pad or tap **Left click** to click.
4. Tap **Right click** for context menus.

The panel does not steal keyboard focus and can be closed with its **Close**
button.

## Remove

```sh
omarchy plugin remove io.github.frostmute.onscreen-trackpad
```

Removal does not remove `ydotool` or revoke the `input` group membership,
because either may be used by other software. If this plugin is the only user
of the virtual pointer, disable the service with
`systemctl --user disable --now ydotool.service`; remove the package or group
membership only if you no longer need them.

## Security

`ydotool` has access to Linux's virtual-input interface (`/dev/uinput`) and can
inject pointer events. The setup explicitly adds the current user to the
`input` group for that purpose. Review this plugin and its dependencies before
enabling it.

## License

MIT
