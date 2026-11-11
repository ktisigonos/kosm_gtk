//! Where GTK's settings are written, each file generated whole. null: that file is not written.

/// GTK 3's settings. Default: `~/.config/gtk-3.0/settings.ini`.
gtk3: ?[]const u8 = "~/.config/gtk-3.0/settings.ini",
/// GTK 4's settings. Default: `~/.config/gtk-4.0/settings.ini`.
gtk4: ?[]const u8 = "~/.config/gtk-4.0/settings.ini",
/// GTK 2's settings. Default: `~/.gtkrc-2.0`.
gtk2: ?[]const u8 = "~/.gtkrc-2.0",
/// The XSETTINGS xsettingsd serves to X11 apps, when it runs.
/// Default: `~/.config/xsettingsd/xsettingsd.conf`.
xsettingsd: ?[]const u8 = "~/.config/xsettingsd/xsettingsd.conf",
/// The default cursor theme X apps inherit, written only with a cursor theme set.
/// Default: `~/.icons/default/index.theme`.
cursor: ?[]const u8 = "~/.icons/default/index.theme",
