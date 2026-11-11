# kosm_gtk

GTK for kosm: the theme's colors for GTK 4's libadwaita apps and GTK 3's adw-gtk3 theme,
without a generated theme, and GTK's settings (theme, icons, font, cursor), in place of
nwg-look. libadwaita draws every widget from its color variables
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

The settings are written whole, the way nwg-look writes them, to GTK 3's and GTK 4's
`settings.ini`, GTK 2's `~/.gtkrc-2.0`, xsettingsd's config (served to X11 apps when xsettingsd
runs) and `~/.icons/default/index.theme` (the cursor X apps inherit). On Wayland GTK reads
GNOME's settings before `settings.ini`, and libadwaita takes dark mode from them, so after every
apply the app also sets the matching `gsettings` keys of `org.gnome.desktop.interface` and
`org.gnome.desktop.sound`; a failure is a warning, like a reload. The `GTK_THEME` environment
variable overrides the theme everywhere: leave it unset.

`from(theme)` sets the GTK theme to `adw-gtk3-dark` (`adw-gtk3` in light mode) and
`gtk_application_prefer_dark_theme` from the mode. It sets windows from black (white in light mode) with its surface steps, text from
white, the accent cyan and the states red, green and yellow, each with readable text from the
theme's `contrast.on`; shadows and the scrollbar outline are the theme's `surface.shadow`.
Windows, views, header bars, sidebars, cards, thumbnails, the tab overview and the active toggle
take the theme's `background_alpha`, so a translucent kosmos makes GTK apps translucent like its
terminals; popovers, dialogs, borders and the accent and state colors stay opaque so they read
over any content.
Surfaces drawn over the window (views, sidebars, cards) add to its opacity where they cover it.

## Fields

| Field | Default |
|---|---|
| `gtk4` | `~/.config/gtk-4.0/gtk.css`, created when missing; null writes nothing for GTK 4 |
| `gtk3` | `~/.config/gtk-3.0/gtk.css`, created when missing; null writes nothing for GTK 3 |
| `settings` | every setting null but `gtk_theme_name` and `gtk_application_prefer_dark_theme`; named as in `settings.ini` (`gtk_icon_theme_name`, `gtk_font_name`, `gtk_cursor_theme_name`, `gtk_cursor_theme_size`, toolbar, sound and `gtk_xft_*` settings), plus gsettings' `monospace_font_name` and `document_font_name`; null is not written |
| `settings_files` | `gtk3`, `gtk4` (`settings.ini`), `gtk2` (`~/.gtkrc-2.0`), `xsettingsd` (`~/.config/xsettingsd/xsettingsd.conf`), `cursor` (`~/.icons/default/index.theme`, only with a cursor theme); null writes nothing there |
| `gsettings` | true: every apply sets the matching gsettings keys |
| `colors` | every libadwaita color without `--` and `-color` (`window_bg`, `accent_bg`, `headerbar_shade`, `error`, ...); `active_toggle_*` and `overview_*` are GTK 4 only; null leaves each to the theme |
