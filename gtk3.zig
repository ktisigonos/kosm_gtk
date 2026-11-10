//! GTK 3's named colors: the `gtk3` adapter, writing `@define-color name value;` lines.
//! Themes built on them (adw-gtk3) take their colors from the last definition, so a block at
//! the end of the user's gtk.css recolors them.

const std = @import("std");
const kosm = @import("kosm");

/// Writes a table of colors as `@define-color` lines, for blocks in GTK 3's gtk.css. Colors
/// default to `rgba(r, g, b, a)`, which every GTK 3 release reads.
pub const adapter: kosm.Adapter = .{
    .name = "gtk3",
    .default_format = .{
        .color = .init("rgba({}, {}, {}, {})", &.{ .red_255, .green_255, .blue_255, .alpha_01 }),
        .float_precision = 3,
    },
    .serialize = serialize,
    .comment = .{ .block = .{ .open = "/*", .close = "*/" } },
};

fn serialize(writer: *std.Io.Writer, root: kosm.Value, context: *kosm.Adapter.Context) kosm.Adapter.Error!void {
    if (root != .table) return context.unsupported("GTK 3 colors are a table of names, not a {s}", .{@tagName(root)});
    for (root.table) |entry| {
        try checkName(entry.key, context);
        if (entry.value != .color) return context.unsupported("color '{s}' is a {s}; @define-color takes colors only", .{ entry.key, @tagName(entry.value) });
        try writer.print("@define-color {s} ", .{entry.key});
        try context.writeColor(writer, entry.value.color);
        try writer.writeAll(";\n");
    }
}

/// GTK reads a color name as letters, digits, `_` and `-`, starting with a letter or `_`.
fn checkName(name: []const u8, context: *kosm.Adapter.Context) error{UnsupportedValue}!void {
    const valid = name.len != 0 and !std.ascii.isDigit(name[0]) and name[0] != '-' and for (name) |character| {
        if (!(std.ascii.isAlphanumeric(character) or character == '_' or character == '-')) break false;
    } else true;
    if (!valid) return context.unsupported("'{s}' is not a GTK color name", .{name});
}

const testing = std.testing;

test "colors become @define-color lines and bad names or values are refused" {
    var output: std.Io.Writer.Allocating = .init(testing.allocator);
    defer output.deinit();
    var context: kosm.Adapter.Context = .{ .format = adapter.default_format.resolve() };
    var shade = kosm.hex("000000");
    shade.alpha = 0.5;
    try serialize(&output.writer, .{ .table = &.{
        .{ .key = "window_bg_color", .value = .{ .color = kosm.hex("041c26") } },
        .{ .key = "shade_color", .value = .{ .color = shade } },
    } }, &context);
    try testing.expectEqualStrings(
        \\@define-color window_bg_color rgba(4, 28, 38, 1);
        \\@define-color shade_color rgba(0, 0, 0, 0.5);
        \\
    , output.written());

    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "a b", .value = .{ .color = shade } }} }, &context));
    try testing.expectEqualStrings("'a b' is not a GTK color name", context.message());
    try testing.expectError(error.UnsupportedValue, serialize(&output.writer, .{ .table = &.{.{ .key = "font", .value = .{ .string = "Sans" } }} }, &context));
    try testing.expectEqualStrings("color 'font' is a string; @define-color takes colors only", context.message());
}
