//! xsettingsd's config: the `xsettingsd` adapter, writing `Name "text"` and `Name 1` lines.
//! The daemon serves them to X11 apps as XSETTINGS.

const std = @import("std");
const kosm = @import("kosm");
const quoting = @import("quoting.zig");

/// Writes a table of XSETTINGS (`Net/ThemeName`) as `Name value` lines, for a generated
/// `xsettingsd.conf`. Strings are quoted, booleans `1`/`0`.
pub const adapter: kosm.Adapter = .{
    .name = "xsettingsd",
    .default_format = .{ .boolean = .one_zero },
    .serialize = serialize,
    .comment = .{ .line = "#" },
};

fn serialize(writer: *std.Io.Writer, root: kosm.Value, context: *kosm.Adapter.Context) kosm.Adapter.Error!void {
    if (root != .table) return context.unsupported("an xsettingsd config is a table of settings, not a {s}", .{@tagName(root)});
    for (root.table) |entry| {
        try quoting.checkName(entry.key, context);
        if (entry.value == .raw) return context.unsupported("'{s}' is raw text; XSETTINGS are text, numbers or booleans", .{entry.key});
        try writer.print("{s} ", .{entry.key});
        try quoting.writeValue(writer, entry.key, entry.value, context);
        try writer.writeByte('\n');
    }
}

const testing = std.testing;

test "settings become Name value lines, and raw text is refused" {
    var output: std.Io.Writer.Allocating = .init(testing.allocator);
    defer output.deinit();
    var context: kosm.Adapter.Context = .{ .format = adapter.default_format.resolve() };
    try serialize(&output.writer, .{ .table = &.{
        .{ .key = "Net/ThemeName", .value = .{ .string = "adw-gtk3-dark" } },
        .{ .key = "Gtk/CursorThemeSize", .value = .{ .integer = 24 } },
        .{ .key = "Xft/Antialias", .value = .{ .boolean = true } },
    } }, &context);
    try testing.expectEqualStrings(
        \\Net/ThemeName "adw-gtk3-dark"
        \\Gtk/CursorThemeSize 24
        \\Xft/Antialias 1
        \\
    , output.written());
    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "Gtk/ToolbarStyle", .value = .{ .raw = "x" } }} }, &context));
    try testing.expectEqualStrings("'Gtk/ToolbarStyle' is raw text; XSETTINGS are text, numbers or booleans", context.message());
}
