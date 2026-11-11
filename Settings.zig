//! GTK's settings, the ones nwg-look and GNOME's settings set: theme, icons, font, cursor,
//! sounds and font rendering. Each is named as in GTK's settings.ini; null is not written.

const Settings = @This();

const std = @import("std");
const kosm = @import("kosm");

/// The GTK theme. Default: `adw-gtk3-dark` in dark mode, `adw-gtk3` in light.
gtk_theme_name: ?[]const u8 = null,
/// The icon theme.
gtk_icon_theme_name: ?[]const u8 = null,
/// The interface font as `Family Size` (`Maple Mono 13`). The base sets its main font.
gtk_font_name: ?[]const u8 = null,
/// The cursor theme; also the default cursor of X apps (`index.theme`).
gtk_cursor_theme_name: ?[]const u8 = null,
/// The cursor size in pixels.
gtk_cursor_theme_size: ?u32 = null,
/// Whether apps pick a theme's dark variant; also GNOME's `color-scheme`. Default: true in
/// dark mode, false in light.
gtk_application_prefer_dark_theme: ?bool = null,
/// What toolbars show. GTK 2 and 3 only.
gtk_toolbar_style: ?ToolbarStyle = null,
/// The size of toolbar icons. GTK 2 and 3 only.
gtk_toolbar_icon_size: ?IconSize = null,
/// Whether buttons show icons. GTK 2 and 3 only.
gtk_button_images: ?bool = null,
/// Whether menus show icons. GTK 2 and 3 only.
gtk_menu_images: ?bool = null,
/// The sound theme.
gtk_sound_theme_name: ?[]const u8 = null,
/// Whether events play sounds.
gtk_enable_event_sounds: ?bool = null,
/// Whether input (clicks, keys) plays sounds.
gtk_enable_input_feedback_sounds: ?bool = null,
/// Whether errors ring the bell.
gtk_error_bell: ?bool = null,
/// Whether fonts are antialiased.
gtk_xft_antialias: ?bool = null,
/// Whether fonts are hinted.
gtk_xft_hinting: ?bool = null,
/// How strongly fonts are hinted.
gtk_xft_hintstyle: ?HintStyle = null,
/// The subpixel order of the screen; `none` antialiases in grayscale.
gtk_xft_rgba: ?Rgba = null,
/// GNOME's monospace font as `Family Size`; gsettings only. The base sets its main font.
monospace_font_name: ?[]const u8 = null,
/// GNOME's document font as `Family Size`; gsettings only. The base sets its main font.
document_font_name: ?[]const u8 = null,

/// `gtk-toolbar-style`'s values.
pub const ToolbarStyle = enum { icons, text, both, both_horiz };
/// `gtk-toolbar-icon-size`'s values.
pub const IconSize = enum { menu, small_toolbar, large_toolbar, button, dnd, dialog };
/// `gtk-xft-hintstyle`'s values.
pub const HintStyle = enum { hintnone, hintslight, hintmedium, hintfull };
/// `gtk-xft-rgba`'s values.
pub const Rgba = enum { none, rgb, bgr, vrgb, vbgr };

/// Which GTK a settings.ini is for.
pub const Version = enum { gtk3, gtk4 };

/// The set settings as a settings.ini's `[Settings]` section; GTK 4 skips those it lacks.
pub fn keyfile(settings: Settings, allocator: std.mem.Allocator, version: Version) ![]const kosm.Value.Entry {
    var entries: Entries = .{ .allocator = allocator };
    try settings.common(&entries);
    if (version == .gtk3) try settings.toolbars(&entries, .string);
    try entries.boolean("gtk-application-prefer-dark-theme", settings.gtk_application_prefer_dark_theme);
    return entries.section("Settings");
}

/// The set settings as `~/.gtkrc-2.0` lines.
pub fn gtkrc(settings: Settings, allocator: std.mem.Allocator) ![]const kosm.Value.Entry {
    var entries: Entries = .{ .allocator = allocator };
    try settings.common(&entries);
    try settings.toolbars(&entries, .raw);
    return entries.list.items;
}

/// The set settings as XSETTINGS, for xsettingsd.
pub fn xsettings(settings: Settings, allocator: std.mem.Allocator) ![]const kosm.Value.Entry {
    var entries: Entries = .{ .allocator = allocator };
    try entries.string("Net/ThemeName", settings.gtk_theme_name);
    try entries.string("Net/IconThemeName", settings.gtk_icon_theme_name);
    try entries.string("Gtk/FontName", settings.gtk_font_name);
    try entries.string("Gtk/CursorThemeName", settings.gtk_cursor_theme_name);
    try entries.integer("Gtk/CursorThemeSize", settings.gtk_cursor_theme_size);
    try entries.boolean("Gtk/ButtonImages", settings.gtk_button_images);
    try entries.boolean("Gtk/MenuImages", settings.gtk_menu_images);
    try entries.string("Net/SoundThemeName", settings.gtk_sound_theme_name);
    try entries.boolean("Net/EnableEventSounds", settings.gtk_enable_event_sounds);
    try entries.boolean("Net/EnableInputFeedbackSounds", settings.gtk_enable_input_feedback_sounds);
    try entries.flag("Xft/Antialias", settings.gtk_xft_antialias);
    try entries.flag("Xft/Hinting", settings.gtk_xft_hinting);
    try entries.string("Xft/HintStyle", tagName(settings.gtk_xft_hintstyle));
    try entries.string("Xft/RGBA", tagName(settings.gtk_xft_rgba));
    return entries.list.items;
}

/// The cursor theme as `index.theme`'s `[Icon Theme]`, which X apps inherit their cursor from.
/// Empty when no cursor theme is set.
pub fn cursorTheme(settings: Settings, allocator: std.mem.Allocator) ![]const kosm.Value.Entry {
    const name = settings.gtk_cursor_theme_name orelse return &.{};
    var entries: Entries = .{ .allocator = allocator };
    try entries.string("Name", "Default");
    try entries.string("Comment", "Default Cursor Theme");
    try entries.string("Inherits", name);
    return entries.section("Icon Theme");
}

/// One `gsettings set` command line.
pub const Command = []const []const u8;

/// The `gsettings set` commands for GNOME's matching keys (`org.gnome.desktop.interface`,
/// `org.gnome.desktop.sound`), values in GVariant syntax.
pub fn gsettings(settings: Settings, allocator: std.mem.Allocator) ![]const Command {
    var commands: Commands = .{ .allocator = allocator };
    const interface = "org.gnome.desktop.interface";
    try commands.string(interface, "gtk-theme", settings.gtk_theme_name);
    try commands.string(interface, "icon-theme", settings.gtk_icon_theme_name);
    try commands.string(interface, "font-name", settings.gtk_font_name);
    try commands.string(interface, "monospace-font-name", settings.monospace_font_name);
    try commands.string(interface, "document-font-name", settings.document_font_name);
    try commands.string(interface, "cursor-theme", settings.gtk_cursor_theme_name);
    if (settings.gtk_cursor_theme_size) |size| try commands.add(interface, "cursor-size", try std.fmt.allocPrint(allocator, "{d}", .{size}));
    if (settings.gtk_application_prefer_dark_theme) |dark| try commands.string(interface, "color-scheme", if (dark) "prefer-dark" else "default");
    try commands.string(interface, "font-antialiasing", settings.antialiasing());
    if (settings.gtk_xft_hintstyle) |style| try commands.string(interface, "font-hinting", @tagName(style)["hint".len..]);
    if (settings.gtk_xft_rgba) |rgba| if (rgba != .none) try commands.string(interface, "font-rgba-order", @tagName(rgba));
    const sound = "org.gnome.desktop.sound";
    try commands.string(sound, "theme-name", settings.gtk_sound_theme_name);
    try commands.boolean(sound, "event-sounds", settings.gtk_enable_event_sounds);
    try commands.boolean(sound, "input-feedback-sounds", settings.gtk_enable_input_feedback_sounds);
    return commands.list.items;
}

/// GNOME's `font-antialiasing`: `none` without antialiasing, else `rgba` with a subpixel order
/// and `grayscale` without one.
fn antialiasing(settings: Settings) ?[]const u8 {
    const antialias = settings.gtk_xft_antialias orelse return null;
    if (!antialias) return "none";
    const rgba = settings.gtk_xft_rgba orelse return "grayscale";
    return if (rgba == .none) "grayscale" else "rgba";
}

/// How a file spells enum values: settings.ini as text, gtkrc bare.
const EnumSpelling = enum { string, raw };

/// The settings every GTK reads.
fn common(settings: Settings, entries: *Entries) !void {
    try entries.string("gtk-theme-name", settings.gtk_theme_name);
    try entries.string("gtk-icon-theme-name", settings.gtk_icon_theme_name);
    try entries.string("gtk-font-name", settings.gtk_font_name);
    try entries.string("gtk-cursor-theme-name", settings.gtk_cursor_theme_name);
    try entries.integer("gtk-cursor-theme-size", settings.gtk_cursor_theme_size);
    try entries.string("gtk-sound-theme-name", settings.gtk_sound_theme_name);
    try entries.boolean("gtk-enable-event-sounds", settings.gtk_enable_event_sounds);
    try entries.boolean("gtk-enable-input-feedback-sounds", settings.gtk_enable_input_feedback_sounds);
    try entries.boolean("gtk-error-bell", settings.gtk_error_bell);
    try entries.flag("gtk-xft-antialias", settings.gtk_xft_antialias);
    try entries.flag("gtk-xft-hinting", settings.gtk_xft_hinting);
    try entries.string("gtk-xft-hintstyle", tagName(settings.gtk_xft_hintstyle));
    try entries.string("gtk-xft-rgba", tagName(settings.gtk_xft_rgba));
}

/// The toolbar and image settings GTK 4 dropped.
fn toolbars(settings: Settings, entries: *Entries, spelling: EnumSpelling) !void {
    if (settings.gtk_toolbar_style) |style| try entries.enumeration("gtk-toolbar-style", toolbarStyleName(style), spelling);
    if (settings.gtk_toolbar_icon_size) |size| try entries.enumeration("gtk-toolbar-icon-size", iconSizeName(size), spelling);
    try entries.boolean("gtk-button-images", settings.gtk_button_images);
    try entries.boolean("gtk-menu-images", settings.gtk_menu_images);
}

fn toolbarStyleName(style: ToolbarStyle) []const u8 {
    return switch (style) {
        .icons => "GTK_TOOLBAR_ICONS",
        .text => "GTK_TOOLBAR_TEXT",
        .both => "GTK_TOOLBAR_BOTH",
        .both_horiz => "GTK_TOOLBAR_BOTH_HORIZ",
    };
}

fn iconSizeName(size: IconSize) []const u8 {
    return switch (size) {
        .menu => "GTK_ICON_SIZE_MENU",
        .small_toolbar => "GTK_ICON_SIZE_SMALL_TOOLBAR",
        .large_toolbar => "GTK_ICON_SIZE_LARGE_TOOLBAR",
        .button => "GTK_ICON_SIZE_BUTTON",
        .dnd => "GTK_ICON_SIZE_DND",
        .dialog => "GTK_ICON_SIZE_DIALOG",
    };
}

fn tagName(value: anytype) ?[]const u8 {
    return if (value) |present| @tagName(present) else null;
}

/// Collects the set settings in order, skipping null ones.
const Entries = struct {
    allocator: std.mem.Allocator,
    list: std.ArrayList(kosm.Value.Entry) = .empty,

    fn add(entries: *Entries, key: []const u8, value: kosm.Value) !void {
        try entries.list.append(entries.allocator, .{ .key = key, .value = value });
    }

    fn string(entries: *Entries, key: []const u8, value: ?[]const u8) !void {
        if (value) |text| try entries.add(key, .{ .string = text });
    }

    fn integer(entries: *Entries, key: []const u8, value: ?u32) !void {
        if (value) |number| try entries.add(key, .{ .integer = number });
    }

    fn boolean(entries: *Entries, key: []const u8, value: ?bool) !void {
        if (value) |flag_value| try entries.add(key, .{ .boolean = flag_value });
    }

    /// GTK's xft settings are integers, `1` or `0`, in every file.
    fn flag(entries: *Entries, key: []const u8, value: ?bool) !void {
        if (value) |on| try entries.add(key, .{ .integer = @intFromBool(on) });
    }

    fn enumeration(entries: *Entries, key: []const u8, name: []const u8, spelling: EnumSpelling) !void {
        try entries.add(key, switch (spelling) {
            .string => .{ .string = name },
            .raw => .{ .raw = name },
        });
    }

    /// The entries as one section, or none when empty.
    fn section(entries: *Entries, name: []const u8) ![]const kosm.Value.Entry {
        if (entries.list.items.len == 0) return &.{};
        const result = try entries.allocator.alloc(kosm.Value.Entry, 1);
        result[0] = .{ .key = name, .value = .{ .table = entries.list.items } };
        return result;
    }
};

/// Collects `gsettings set` commands, skipping null values.
const Commands = struct {
    allocator: std.mem.Allocator,
    list: std.ArrayList(Command) = .empty,

    fn add(commands: *Commands, schema: []const u8, key: []const u8, value: []const u8) !void {
        const argv = try commands.allocator.dupe([]const u8, &.{ "gsettings", "set", schema, key, value });
        try commands.list.append(commands.allocator, argv);
    }

    /// Adds `value` as a GVariant string: in `'...'` with `'` and `\` escaped.
    fn string(commands: *Commands, schema: []const u8, key: []const u8, value: ?[]const u8) !void {
        const text = value orelse return;
        var quoted: std.ArrayList(u8) = .empty;
        try quoted.append(commands.allocator, '\'');
        for (text) |character| {
            if (character == '\'' or character == '\\') try quoted.append(commands.allocator, '\\');
            try quoted.append(commands.allocator, character);
        }
        try quoted.append(commands.allocator, '\'');
        try commands.add(schema, key, quoted.items);
    }

    fn boolean(commands: *Commands, schema: []const u8, key: []const u8, value: ?bool) !void {
        if (value) |on| try commands.add(schema, key, if (on) "true" else "false");
    }
};

const testing = std.testing;

fn expectCommands(expected: []const []const u8, commands: []const Command) !void {
    try testing.expectEqual(expected.len, commands.len);
    for (expected, commands) |line, command| {
        const joined = try std.mem.join(testing.allocator, " ", command);
        defer testing.allocator.free(joined);
        try testing.expectEqualStrings(line, joined);
    }
}

test "gsettings get GVariant values, GNOME's names and nothing for null settings" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const settings: Settings = .{
        .gtk_font_name = "It's \\ 13",
        .gtk_cursor_theme_size = 24,
        .gtk_application_prefer_dark_theme = false,
        .gtk_xft_antialias = true,
        .gtk_xft_hintstyle = .hintslight,
        .gtk_xft_rgba = .rgb,
        .gtk_enable_event_sounds = false,
    };
    try expectCommands(&.{
        "gsettings set org.gnome.desktop.interface font-name 'It\\'s \\\\ 13'",
        "gsettings set org.gnome.desktop.interface cursor-size 24",
        "gsettings set org.gnome.desktop.interface color-scheme 'default'",
        "gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'",
        "gsettings set org.gnome.desktop.interface font-hinting 'slight'",
        "gsettings set org.gnome.desktop.interface font-rgba-order 'rgb'",
        "gsettings set org.gnome.desktop.sound event-sounds false",
    }, try settings.gsettings(arena.allocator()));
    try testing.expectEqual(0, (try (Settings{}).gsettings(arena.allocator())).len);
}

test "antialiasing is none when off, grayscale without a subpixel order, rgba with one" {
    try testing.expectEqual(null, (Settings{ .gtk_xft_rgba = .rgb }).antialiasing());
    try testing.expectEqualStrings("none", (Settings{ .gtk_xft_antialias = false, .gtk_xft_rgba = .rgb }).antialiasing().?);
    try testing.expectEqualStrings("grayscale", (Settings{ .gtk_xft_antialias = true }).antialiasing().?);
    try testing.expectEqualStrings("grayscale", (Settings{ .gtk_xft_antialias = true, .gtk_xft_rgba = .none }).antialiasing().?);
    try testing.expectEqualStrings("rgba", (Settings{ .gtk_xft_antialias = true, .gtk_xft_rgba = .vbgr }).antialiasing().?);
}

test "no cursor theme writes no index.theme section" {
    try testing.expectEqual(0, (try (Settings{ .gtk_cursor_theme_size = 24 }).cursorTheme(testing.allocator)).len);
}
