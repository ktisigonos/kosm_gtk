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
/// GTK's settings (theme, icons, font, cursor, sounds, font rendering), written to every file
/// of `settings_files` and, with `gsettings`, to GNOME's settings.
settings: Settings = .{},
/// Where the settings are written.
settings_files: SettingsFiles = .{},
/// Whether every apply sets GNOME's matching gsettings keys, which GTK reads on Wayland and
/// libadwaita takes its dark mode from. A failure is a warning. Default true.
gsettings: bool = true,

/// libadwaita's colors.
pub const Colors = @import("Colors.zig");
/// GTK's settings.
pub const Settings = @import("Settings.zig");
/// Where GTK's settings are written.
pub const SettingsFiles = @import("SettingsFiles.zig");

/// The GTK 4-only colors, which GTK 3 themes have no name for.
const gtk4_only = [_][]const u8{ "active_toggle_bg", "active_toggle_fg", "overview_bg", "overview_fg" };

/// Colors from the theme: windows from black (white in light mode) with its surface steps,
/// text from white, the accent cyan and the states red, green and yellow, each with readable
/// text from the theme's `contrast.on`; shadows are the theme's `surface.shadow`. Windows,
/// views, header bars, sidebars, cards, thumbnails and the tab overview take the theme's
/// `background_alpha`; popovers, dialogs, the active toggle and borders stay opaque. The GTK
/// theme is adw-gtk3 in the theme's mode, which apps are told to prefer.
pub fn from(theme: kosm.Theme) App {
    const dark = theme.mode == .dark;
    return .{
        .colors = colorsFrom(theme),
        .settings = .{
            .gtk_theme_name = if (dark) "adw-gtk3-dark" else "adw-gtk3",
            .gtk_application_prefer_dark_theme = dark,
        },
    };
}

fn colorsFrom(theme: kosm.Theme) Colors {
    const palette = theme.palette;
    const variations = theme.variations;
    const foreground = if (theme.mode == .dark) palette.white else palette.black;
    // Floating surfaces (popovers, dialogs) and lines stay opaque, so they read over any content.
    const opaque_background = if (theme.mode == .dark) palette.black else palette.white;
    const background = theme.asBackground(opaque_background);
    const raised = variations.surface.raised.apply(background);
    const overlay = variations.surface.overlay.apply(opaque_background);
    const shade = variations.surface.shadow.apply(background);
    const border = variations.line.border.apply(opaque_background);
    const on = variations.contrast.on;
    const bright = variations.lightness.bright;
    return .{
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
    };
}

/// Writes block `kosm` of each set stylesheet (`--<name>-color` properties for GTK 4,
/// `@define-color <name>_color` lines for GTK 3), then every set settings file whole.
pub fn apply(self: App, output: *kosm.Output) !void {
    const allocator = output.allocator;
    if (self.gtk4) |file| try output.block(.{ .file = file, .id = "kosm", .lang = "css" }, kosm.Value{ .table = try self.entries(allocator, .gtk4) });
    if (self.gtk3) |file| try output.block(.{ .file = file, .id = "kosm", .lang = "gtk3" }, kosm.Value{ .table = try self.entries(allocator, .gtk3) });
    const files = self.settings_files;
    const settings = self.settings;
    if (files.gtk3) |file| try output.generate(.{ .file = file, .lang = "gtk_keyfile" }, kosm.Value{ .table = try settings.keyfile(allocator, .gtk3) });
    if (files.gtk4) |file| try output.generate(.{ .file = file, .lang = "gtk_keyfile" }, kosm.Value{ .table = try settings.keyfile(allocator, .gtk4) });
    if (files.gtk2) |file| try output.generate(.{ .file = file, .lang = "gtkrc" }, kosm.Value{ .table = try settings.gtkrc(allocator) });
    if (files.xsettingsd) |file| try output.generate(.{ .file = file, .lang = "xsettingsd" }, kosm.Value{ .table = try settings.xsettings(allocator) });
    if (files.cursor) |file| {
        const cursor = try settings.cursorTheme(allocator);
        if (cursor.len != 0) try output.generate(.{ .file = file, .lang = "gtk_keyfile" }, kosm.Value{ .table = cursor });
    }
}

/// Sets GNOME's gsettings keys matching the set settings, unless `gsettings` is false. Kosm
/// runs it after every apply; the first command to fail stops it with a warning.
pub fn reload(self: App, reloader: *kosm.Reloader) !void {
    if (!self.gsettings) return;
    // A reload gets no allocator; the commands live only as long as this call.
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    for (try self.settings.gsettings(arena.allocator())) |command| try reloader.run(command);
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
            .adapters = &.{ root.css_adapter, root.gtk3_adapter, root.keyfile_adapter, root.gtkrc_adapter, root.xsettingsd_adapter },
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
    app.settings_files = .{ .gtk3 = null, .gtk4 = null, .gtk2 = null, .xsettingsd = null, .cursor = null };
    try app.apply(&fixture.output);
    try testing.expectEqual(1, fixture.plan.files.items.len);
}

test "the window's surfaces take the background alpha, popovers, dialogs and borders stay opaque" {
    var theme = kosm.Theme.from(.{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc") }, .dark);
    theme.background_alpha = 0.5;
    const colors = from(theme).colors;
    const translucent = [_]?kosm.Color{
        colors.window_bg,            colors.view_bg,                    colors.headerbar_bg,
        colors.headerbar_backdrop,   colors.sidebar_bg,                 colors.sidebar_backdrop,
        colors.secondary_sidebar_bg, colors.secondary_sidebar_backdrop, colors.card_bg,
        colors.thumbnail_bg,         colors.overview_bg,
    };
    for (translucent) |color| try testing.expectEqual(0.5, color.?.alpha);
    const solid = [_]?kosm.Color{
        colors.popover_bg,       colors.dialog_bg,      colors.active_toggle_bg,
        colors.headerbar_border, colors.sidebar_border, colors.secondary_sidebar_border,
        colors.window_fg,        colors.accent_bg,
    };
    for (solid) |color| try testing.expectEqual(1, color.?.alpha);
    // The surfaces differ from the window by lightness only, so the alpha changes nothing else.
    var opaque_theme = theme;
    opaque_theme.background_alpha = 1;
    const opaque_colors = from(opaque_theme).colors;
    try testing.expectEqual(opaque_colors.view_bg.?.lightness, colors.view_bg.?.lightness);
    try testing.expectEqual(opaque_colors.popover_bg.?, colors.popover_bg.?);
}

test "settings are written whole to every settings file, each with the keys its GTK reads" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    var app = from(kosm.Theme.from(.{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc") }, .light));
    app.gtk4 = null;
    app.gtk3 = null;
    app.settings.gtk_font_name = "Maple Mono 13";
    app.settings.gtk_cursor_theme_name = "Bibata";
    app.settings.gtk_cursor_theme_size = 24;
    app.settings.gtk_toolbar_style = .icons;
    app.settings.gtk_menu_images = false;
    app.settings.gtk_xft_antialias = true;
    app.settings.gtk_xft_hintstyle = .hintslight;
    try app.apply(&fixture.output);
    try testing.expectEqualStrings(
        \\[Settings]
        \\gtk-theme-name=adw-gtk3
        \\gtk-font-name=Maple Mono 13
        \\gtk-cursor-theme-name=Bibata
        \\gtk-cursor-theme-size=24
        \\gtk-xft-antialias=1
        \\gtk-xft-hintstyle=hintslight
        \\gtk-toolbar-style=GTK_TOOLBAR_ICONS
        \\gtk-menu-images=false
        \\gtk-application-prefer-dark-theme=false
        \\
    , fixture.planned("~/.config/gtk-3.0/settings.ini"));
    try testing.expectEqualStrings(
        \\[Settings]
        \\gtk-theme-name=adw-gtk3
        \\gtk-font-name=Maple Mono 13
        \\gtk-cursor-theme-name=Bibata
        \\gtk-cursor-theme-size=24
        \\gtk-xft-antialias=1
        \\gtk-xft-hintstyle=hintslight
        \\gtk-application-prefer-dark-theme=false
        \\
    , fixture.planned("~/.config/gtk-4.0/settings.ini"));
    try testing.expectEqualStrings(
        \\gtk-theme-name="adw-gtk3"
        \\gtk-font-name="Maple Mono 13"
        \\gtk-cursor-theme-name="Bibata"
        \\gtk-cursor-theme-size=24
        \\gtk-xft-antialias=1
        \\gtk-xft-hintstyle="hintslight"
        \\gtk-toolbar-style=GTK_TOOLBAR_ICONS
        \\gtk-menu-images=0
        \\
    , fixture.planned("~/.gtkrc-2.0"));
    try testing.expectEqualStrings(
        \\Net/ThemeName "adw-gtk3"
        \\Gtk/FontName "Maple Mono 13"
        \\Gtk/CursorThemeName "Bibata"
        \\Gtk/CursorThemeSize 24
        \\Gtk/MenuImages 0
        \\Xft/Antialias 1
        \\Xft/HintStyle "hintslight"
        \\
    , fixture.planned("~/.config/xsettingsd/xsettingsd.conf"));
    try testing.expectEqualStrings(
        \\[Icon Theme]
        \\Name=Default
        \\Comment=Default Cursor Theme
        \\Inherits=Bibata
        \\
    , fixture.planned("~/.icons/default/index.theme"));
}
