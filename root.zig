//! GTK: the theme's colors for libadwaita apps (GTK 4) and adw-gtk3 (GTK 3) in their gtk.css, and GTK's settings in place of nwg-look.

const std = @import("std");

/// GTK's colors and settings; build one with `from`.
pub const App = @import("App.zig");
/// Colors and the adw-gtk3 theme from the theme.
pub const from = App.from;
/// The adapter the app writes GTK 4's block with, so a config needs only this package.
pub const css_adapter = @import("kosm_css").adapter;
/// The adapter the app writes GTK 3's block with.
pub const gtk3_adapter = @import("gtk3.zig").adapter;
/// The adapter the app writes settings.ini and index.theme with: GLib's key files.
pub const keyfile_adapter = @import("kosm_ini").dialect(.{ .name = "gtk_keyfile", .separator = "=", .nested_headers = false, .top_level_keys = false });
/// The adapter the app writes `~/.gtkrc-2.0` with.
pub const gtkrc_adapter = @import("gtkrc.zig").adapter;
/// The adapter the app writes xsettingsd's config with.
pub const xsettingsd_adapter = @import("xsettingsd.zig").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
    _ = @import("gtk3.zig");
    _ = @import("gtkrc.zig");
    _ = @import("xsettingsd.zig");
    _ = @import("Settings.zig");
}
