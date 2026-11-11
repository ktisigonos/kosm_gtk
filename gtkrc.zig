//! GTK 2's rc files: the `gtkrc` adapter, writing `name="text"` and `name=1` lines, as
//! `~/.gtkrc-2.0` holds them.

const std = @import("std");
const kosm = @import("kosm");
const quoting = @import("quoting.zig");

/// Writes a table of settings as `name=value` lines, for a generated `~/.gtkrc-2.0`. Strings
/// are quoted, raw values (`GTK_TOOLBAR_ICONS`) written bare, booleans `1`/`0`.
pub const adapter: kosm.Adapter = .{
    .name = "gtkrc",
    .default_format = .{ .boolean = .one_zero },
    .serialize = serialize,
    .comment = .{ .line = "#" },
};

fn serialize(writer: *std.Io.Writer, root: kosm.Value, context: *kosm.Adapter.Context) kosm.Adapter.Error!void {
    if (root != .table) return context.unsupported("a gtkrc file is a table of settings, not a {s}", .{@tagName(root)});
    for (root.table) |entry| {
        try quoting.checkName(entry.key, context);
        try writer.print("{s}=", .{entry.key});
        try quoting.writeValue(writer, entry.key, entry.value, context);
        try writer.writeByte('\n');
    }
}

const testing = std.testing;

test "settings become name=value lines with strings quoted and escaped" {
    var output: std.Io.Writer.Allocating = .init(testing.allocator);
    defer output.deinit();
    var context: kosm.Adapter.Context = .{ .format = adapter.default_format.resolve() };
    try serialize(&output.writer, .{ .table = &.{
        .{ .key = "gtk-theme-name", .value = .{ .string = "adw-gtk3-dark" } },
        .{ .key = "gtk-font-name", .value = .{ .string = "A \"B\" \\ 13" } },
        .{ .key = "gtk-cursor-theme-size", .value = .{ .integer = 24 } },
        .{ .key = "gtk-button-images", .value = .{ .boolean = false } },
        .{ .key = "gtk-toolbar-style", .value = .{ .raw = "GTK_TOOLBAR_ICONS" } },
    } }, &context);
    try testing.expectEqualStrings(
        \\gtk-theme-name="adw-gtk3-dark"
        \\gtk-font-name="A \"B\" \\ 13"
        \\gtk-cursor-theme-size=24
        \\gtk-button-images=0
        \\gtk-toolbar-style=GTK_TOOLBAR_ICONS
        \\
    , output.written());
}

test "a line break in a string, a bad name and a color are refused" {
    var output: std.Io.Writer.Allocating = .init(testing.allocator);
    defer output.deinit();
    var context: kosm.Adapter.Context = .{ .format = adapter.default_format.resolve() };
    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "gtk-font-name", .value = .{ .string = "a\nb" } }} }, &context));
    try testing.expectEqualStrings("'gtk-font-name' holds a line break, which a quoted string can't spell", context.message());
    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "gtk theme", .value = .{ .integer = 1 } }} }, &context));
    try testing.expectEqualStrings("'gtk theme' is not a setting name", context.message());
    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "a", .value = .{ .color = kosm.hex("000000") } }} }, &context));
    try testing.expectEqualStrings("'a' is a color; settings take text, numbers and booleans", context.message());
}
