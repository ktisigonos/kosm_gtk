//! libadwaita's colors, named without `--` and `-color` (`window_bg` is `--window-bg-color` in
//! GTK 4 and `@window_bg_color` in GTK 3). null: the theme's own.

const kosm = @import("kosm");

/// The background of accented widgets: suggested buttons, selections.
accent_bg: ?kosm.Color = null,
/// Text on `accent_bg`.
accent_fg: ?kosm.Color = null,
/// Accented text and icons on ordinary backgrounds.
accent: ?kosm.Color = null,
/// The background of destructive buttons.
destructive_bg: ?kosm.Color = null,
/// Text on `destructive_bg`.
destructive_fg: ?kosm.Color = null,
/// Destructive text and icons.
destructive: ?kosm.Color = null,
/// The background of success messages and level bars.
success_bg: ?kosm.Color = null,
/// Text on `success_bg`.
success_fg: ?kosm.Color = null,
/// Success text and icons.
success: ?kosm.Color = null,
/// The background of warnings.
warning_bg: ?kosm.Color = null,
/// Text on `warning_bg`.
warning_fg: ?kosm.Color = null,
/// Warning text and icons.
warning: ?kosm.Color = null,
/// The background of errors.
error_bg: ?kosm.Color = null,
/// Text on `error_bg`.
error_fg: ?kosm.Color = null,
/// Error text and icons.
@"error": ?kosm.Color = null,
/// The window background.
window_bg: ?kosm.Color = null,
/// Text on windows.
window_fg: ?kosm.Color = null,
/// The background of views: lists, text views, grids.
view_bg: ?kosm.Color = null,
/// Text in views.
view_fg: ?kosm.Color = null,
/// The header bar, search bar and tab bar.
headerbar_bg: ?kosm.Color = null,
/// Text on the header bar.
headerbar_fg: ?kosm.Color = null,
/// The header bar's border.
headerbar_border: ?kosm.Color = null,
/// The header bar while the window is unfocused.
headerbar_backdrop: ?kosm.Color = null,
/// The header bar's shadow.
headerbar_shade: ?kosm.Color = null,
/// The header bar's darker shadow.
headerbar_darker_shade: ?kosm.Color = null,
/// The sidebar of split views.
sidebar_bg: ?kosm.Color = null,
/// Text on the sidebar.
sidebar_fg: ?kosm.Color = null,
/// The sidebar while the window is unfocused.
sidebar_backdrop: ?kosm.Color = null,
/// The sidebar's shadow.
sidebar_shade: ?kosm.Color = null,
/// The secondary sidebar.
secondary_sidebar_bg: ?kosm.Color = null,
/// Text on the secondary sidebar.
secondary_sidebar_fg: ?kosm.Color = null,
/// The secondary sidebar while the window is unfocused.
secondary_sidebar_backdrop: ?kosm.Color = null,
/// The secondary sidebar's shadow.
secondary_sidebar_shade: ?kosm.Color = null,
/// Cards and boxed lists.
card_bg: ?kosm.Color = null,
/// Text on cards.
card_fg: ?kosm.Color = null,
/// The cards' shadow.
card_shade: ?kosm.Color = null,
/// Dialogs.
dialog_bg: ?kosm.Color = null,
/// Text in dialogs.
dialog_fg: ?kosm.Color = null,
/// Popovers and menus.
popover_bg: ?kosm.Color = null,
/// Text in popovers.
popover_fg: ?kosm.Color = null,
/// The popovers' shadow.
popover_shade: ?kosm.Color = null,
/// Thumbnails.
thumbnail_bg: ?kosm.Color = null,
/// Text on thumbnails.
thumbnail_fg: ?kosm.Color = null,
/// Shadows elsewhere.
shade: ?kosm.Color = null,
/// The sidebar's border.
sidebar_border: ?kosm.Color = null,
/// The secondary sidebar's border.
secondary_sidebar_border: ?kosm.Color = null,
/// The background of a toggle group's active toggle. GTK 4 only.
active_toggle_bg: ?kosm.Color = null,
/// Text on `active_toggle_bg`. GTK 4 only.
active_toggle_fg: ?kosm.Color = null,
/// The tab overview's background. GTK 4 only.
overview_bg: ?kosm.Color = null,
/// Text on the tab overview. GTK 4 only.
overview_fg: ?kosm.Color = null,
/// The outline around scrollbars over content.
scrollbar_outline: ?kosm.Color = null,
