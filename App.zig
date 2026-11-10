//! GTK's colors: libadwaita's color variables in a block of GTK 4's gtk.css, and the same
//! colors as GTK 3 named colors in GTK 3's, for libadwaita apps and the adw-gtk3 theme. The rest
//! of each file stays the user's.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// GTK 4's user stylesheet, holding the block; created when missing. null: not written.
/// Default: `~/.config/gtk-4.0/gtk.css`.
gtk4: ?[]const u8 = "~/.config/gtk-4.0/gtk.css",
/// GTK 3's user stylesheet, holding the block; created when missing. Only themes built on
/// named colors, such as adw-gtk3, follow it. null: not written.
/// Default: `~/.config/gtk-3.0/gtk.css`.
gtk3: ?[]const u8 = "~/.config/gtk-3.0/gtk.css",
/// The colors. null: the theme's own.
colors: Colors = .{},

/// libadwaita's colors.
pub const Colors = @import("Colors.zig");

/// The GTK 4-only colors, which GTK 3 themes have no name for.
const gtk4_only = [_][]const u8{ "active_toggle_bg", "active_toggle_fg", "overview_bg", "overview_fg" };

/// Colors from the theme: windows from black (white in light mode) with its surface steps,
/// text from white, the accent cyan and the states red, green and yellow, each with readable
/// text from the theme's `contrast.on`; shadows are the theme's `surface.shadow`.
pub fn from(theme: kosm.Theme) App {
    const palette = theme.palette;
    const variations = theme.variations;
    const foreground = if (theme.mode == .dark) palette.white else palette.black;
    const background = theme.asBackground(if (theme.mode == .dark) palette.black else palette.white);
    const raised = variations.surface.raised.apply(background);
    const overlay = variations.surface.overlay.apply(background);
    const shade = variations.surface.shadow.apply(background);
    const border = variations.line.border.apply(background);
    const on = variations.contrast.on;
    const bright = variations.lightness.bright;
    return .{ .colors = .{
        .accent_bg = palette.cyan,
        .accent_fg = on.apply(palette.cyan),
        .accent = bright.apply(palette.cyan),
        .destructive_bg = palette.red,
        .destructive_fg = on.apply(palette.red),
        .destructive = bright.apply(palette.red),
        .success_bg = palette.green,
        .success_fg = on.apply(palette.green),
        .success = bright.apply(palette.green),
        .warning_bg = palette.yellow,
        .warning_fg = on.apply(palette.yellow),
        .warning = bright.apply(palette.yellow),
        .error_bg = palette.red,
        .error_fg = on.apply(palette.red),
        .@"error" = bright.apply(palette.red),
        .window_bg = background,
        .window_fg = foreground,
        .view_bg = variations.surface.sunken.apply(background),
        .view_fg = foreground,
        .headerbar_bg = raised,
        .headerbar_fg = foreground,
        .headerbar_border = border,
        .headerbar_backdrop = background,
        .headerbar_shade = shade,
        .headerbar_darker_shade = shade,
        .sidebar_bg = raised,
        .sidebar_fg = foreground,
        .sidebar_backdrop = background,
        .sidebar_shade = shade,
        .sidebar_border = border,
        .secondary_sidebar_bg = raised,
        .secondary_sidebar_fg = foreground,
        .secondary_sidebar_backdrop = background,
        .secondary_sidebar_shade = shade,
        .secondary_sidebar_border = border,
        .card_bg = raised,
        .card_fg = foreground,
        .card_shade = shade,
        .dialog_bg = overlay,
        .dialog_fg = foreground,
        .popover_bg = overlay,
        .popover_fg = foreground,
        .popover_shade = shade,
        .thumbnail_bg = raised,
        .thumbnail_fg = foreground,
        .shade = shade,
        .active_toggle_bg = overlay,
        .active_toggle_fg = foreground,
        .overview_bg = background,
        .overview_fg = foreground,
        .scrollbar_outline = shade,
    } };
}

/// Writes block `kosm` of each set file: `--<name>-color` properties for GTK 4,
/// `@define-color <name>_color` lines for GTK 3.
pub fn apply(self: App, output: *kosm.Output) !void {
    if (self.gtk4) |file| try output.block(.{ .file = file, .id = "kosm", .lang = "css" }, kosm.Value{ .table = try self.entries(output.allocator, .gtk4) });
    if (self.gtk3) |file| try output.block(.{ .file = file, .id = "kosm", .lang = "gtk3" }, kosm.Value{ .table = try self.entries(output.allocator, .gtk3) });
}

/// The set colors keyed `<name>_color`, which both GTKs name them.
fn entries(self: App, allocator: std.mem.Allocator, version: enum { gtk3, gtk4 }) ![]const kosm.Value.Entry {
    var list: std.ArrayList(kosm.Value.Entry) = .empty;
    inline for (@typeInfo(Colors).@"struct".field_names) |name| {
        if (@field(self.colors, name)) |color| {
            if (version == .gtk4 or comptime !isGtk4Only(name))
                try list.append(allocator, .{ .key = name ++ "_color", .value = .{ .color = color } });
        }
    }
    return list.items;
}

fn isGtk4Only(comptime name: []const u8) bool {
    for (gtk4_only) |only| {
        if (std.mem.eql(u8, only, name)) return true;
    }
    return false;
}

const testing = std.testing;
const root = @import("root.zig");

const Fixture = struct {
    tmp: testing.TmpDir,
    arena: std.heap.ArenaAllocator,
    plan: kosm.Plan,
    diagnostics: kosm.Diagnostics = .{},
    warnings: kosm.Warnings = undefined,
    home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined,
    output: kosm.Output = undefined,

    fn init(fixture: *Fixture) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
        try fixture.tmp.dir.createDirPath(testing.io, ".config/gtk-4.0");
        try fixture.tmp.dir.writeFile(testing.io, .{ .sub_path = ".config/gtk-4.0/gtk.css", .data = "window { padding: 0; }\n" });
        fixture.warnings = .init(fixture.arena.allocator());
        const length = try fixture.tmp.dir.realPath(testing.io, &fixture.home_buffer);
        fixture.output = .{
            .allocator = fixture.arena.allocator(),
            .home = fixture.home_buffer[0..length],
            .adapters = &.{ root.css_adapter, root.gtk3_adapter },
            .plan = &fixture.plan,
            .diagnostics = &fixture.diagnostics,
            .warnings = &fixture.warnings,
            .app = "gtk",
        };
    }

    fn deinit(fixture: *Fixture) void {
        fixture.plan.deinit();
        fixture.arena.deinit();
        fixture.tmp.cleanup();
    }

    fn planned(fixture: *Fixture, display_path: []const u8) []const u8 {
        for (fixture.plan.files.items) |file| {
            if (std.mem.eql(u8, file.display_path, display_path)) return file.new;
        }
        return "(not planned)";
    }
};

test "GTK 4 gets --name-color properties after the user's CSS, GTK 3 @define-color lines" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    const app: App = .{ .colors = .{ .window_bg = kosm.hex("041c26"), .@"error" = kosm.hex("993d48"), .overview_bg = kosm.hex("000000") } };
    try app.apply(&fixture.output);
    try testing.expectEqualStrings(
        \\window { padding: 0; }
        \\/* kosm:begin kosm */
        \\:root {
        \\  --error-color: #993d48ff;
        \\  --window-bg-color: #041c26ff;
        \\  --overview-bg-color: #000000ff;
        \\}
        \\/* kosm:end */
        \\
    , fixture.planned("~/.config/gtk-4.0/gtk.css"));
    try testing.expectEqualStrings(
        \\/* kosm:begin kosm */
        \\@define-color error_color rgba(153, 61, 72, 1);
        \\@define-color window_bg_color rgba(4, 28, 38, 1);
        \\/* kosm:end */
        \\
    , fixture.planned("~/.config/gtk-3.0/gtk.css"));
}

test "a null file is not written, and from sets every color" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    var app = from(kosm.Theme.from(.{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc") }, .dark));
    inline for (@typeInfo(Colors).@"struct".field_names) |name| try testing.expect(@field(app.colors, name) != null);
    app.gtk4 = null;
    try app.apply(&fixture.output);
    try testing.expectEqual(1, fixture.plan.files.items.len);
}
