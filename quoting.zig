//! What the `gtkrc` and `xsettingsd` adapters share: setting names, and values with strings
//! in C-style double quotes.

const std = @import("std");
const kosm = @import("kosm");

/// A setting name is letters, digits, `-`, `_` and `/` (`gtk-theme-name`, `Net/ThemeName`).
pub fn checkName(name: []const u8, context: *kosm.Adapter.Context) error{UnsupportedValue}!void {
    const valid = name.len != 0 and for (name) |character| {
        if (!(std.ascii.isAlphanumeric(character) or character == '-' or character == '_' or character == '/')) break false;
    } else true;
    if (!valid) return context.unsupported("'{s}' is not a setting name", .{name});
}

/// Writes a string in `"..."` with `"` and `\` escaped, a raw value bare, and integers and
/// booleans in the file's spelling. `key` names the setting in errors.
pub fn writeValue(writer: *std.Io.Writer, key: []const u8, value: kosm.Value, context: *kosm.Adapter.Context) kosm.Adapter.Error!void {
    switch (value) {
        .string => |text| try writeString(writer, key, text, context),
        .raw => |text| try writer.writeAll(text),
        .integer => |integer| try writer.print("{d}", .{integer}),
        .boolean => |boolean| try context.writeBoolean(writer, boolean),
        else => return context.unsupported("'{s}' is a {s}; settings take text, numbers and booleans", .{ key, @tagName(value) }),
    }
}

fn writeString(writer: *std.Io.Writer, key: []const u8, text: []const u8, context: *kosm.Adapter.Context) kosm.Adapter.Error!void {
    if (std.mem.findAny(u8, text, "\r\n") != null) return context.unsupported("'{s}' holds a line break, which a quoted string can't spell", .{key});
    try writer.writeByte('"');
    for (text) |character| {
        if (character == '"' or character == '\\') try writer.writeByte('\\');
        try writer.writeByte(character);
    }
    try writer.writeByte('"');
}
