# kosm_gtk

GTK for kosm: the theme's colors for GTK 4's libadwaita apps and GTK 3's adw-gtk3 theme,
without a generated theme. libadwaita draws every widget from its color variables
(`--window-bg-color`, `--accent-bg-color`, ...), and adw-gtk3 from the matching GTK 3 named
colors (`@window_bg_color`), so setting those recolors the apps.

The app writes a block between `/* kosm:begin kosm */` and `/* kosm:end */` at the end of each
user stylesheet; the rest of the file stays yours:

- `~/.config/gtk-4.0/gtk.css`: `:root { --<name>-color: ...; }`, read by every GTK 4 app.
- `~/.config/gtk-3.0/gtk.css`: `@define-color <name>_color ...;` lines (the package's `gtk3`
  adapter). Only themes built on named colors follow them: set the GTK 3 theme to adw-gtk3
  (`adw-gtk3-dark` in dark mode) to use them. Other themes, such as an Oomox one, draw with
  colors of their own.

Running apps read the stylesheets at start, so restart them after an apply.

`from(theme)` sets windows from black (white in light mode) with its surface steps, text from
white, the accent cyan and the states red, green and yellow, each with readable text from the
theme's `contrast.on`; shadows and the scrollbar outline are the theme's `surface.shadow`.

## Fields

| Field | Default |
|---|---|
| `gtk4` | `~/.config/gtk-4.0/gtk.css`, created when missing; null writes nothing for GTK 4 |
| `gtk3` | `~/.config/gtk-3.0/gtk.css`, created when missing; null writes nothing for GTK 3 |
| `colors` | every libadwaita color without `--` and `-color` (`window_bg`, `accent_bg`, `headerbar_shade`, `error`, ...); `active_toggle_*` and `overview_*` are GTK 4 only; null leaves each to the theme |
