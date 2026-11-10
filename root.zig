//! GTK: the theme's colors for libadwaita apps (GTK 4) and adw-gtk3 (GTK 3), in their gtk.css.

const std = @import("std");

/// GTK's colors; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme.
pub const from = App.from;
/// The adapter the app writes GTK 4's block with, so a config needs only this package.
pub const css_adapter = @import("kosm_css").adapter;
/// The adapter the app writes GTK 3's block with.
pub const gtk3_adapter = @import("gtk3.zig").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
    _ = @import("gtk3.zig");
}
