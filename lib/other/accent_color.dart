import 'package:flutter/material.dart';
import 'constants.dart';

/// The accent color currently in effect across the app. Updated by
/// `_MyAppState` whenever the effective accent changes (user selection,
/// MetroV toggle, or MetroV theme change).
///
/// Widgets read this global directly. `_MyAppState` wraps `MaterialApp`
/// in a rebuild trigger, so reassigning here causes the whole tree to
/// pick up the new color on the next frame.
Color AccentColor = accentColorFallback;

/// The accent color last reported by MetroV Launcher, or null if MetroV
/// is not installed or the query failed. Set once at app startup by
/// `main()` via `MetrovThemeService.getAccentColor()`.
Color? MetrovAccent;