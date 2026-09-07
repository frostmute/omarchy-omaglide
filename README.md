# Omaglide for Omarchy

![Omaglide preview](preview.png)

**Omaglide** is a large, touch-first relative pointer pad for Omarchy tablets. It is part of the optional **Omablet** tablet suite, but installs and works independently.

Drag on the pad to move the pointer. Double-tap the pad or use **Left click** to click; use **Right click** for context menus. The panel supports both touchscreen input and ordinary mouse input.

## Install

```sh
omarchy plugin add https://github.com/frostmute/omarchy-omaglide.git --enable
```

## One-time pointer setup

Omaglide uses `ydotool` for its Wayland virtual pointer. Run the bundled setup script in a visible terminal:

```sh
~/.config/omarchy/plugins/io.github.frostmute.onscreen-trackpad/setup.sh
```

It installs `ydotool` if needed, adds the current user to the `input` group, and enables the `ydotool` user service. Log out and back in after the group change.

## Remove

```sh
omarchy plugin remove io.github.frostmute.onscreen-trackpad
```

This does not remove `ydotool` or revoke the `input` group, as they may be used by other software.

## Security

`ydotool` can inject pointer events via `/dev/uinput`. Review the plugin and setup script before enabling it.

## License

MIT
