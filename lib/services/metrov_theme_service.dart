import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reads MetroV Launcher's accent color via its ContentProvider.
///
/// Requires:
/// - `<uses-permission android:name="com.tuzkituan.metrov.permission.READ_THEME"/>`
///   in AndroidManifest.xml
/// - `<provider android:authorities="com.tuzkituan.metrov.theme"/>` in the
///   `<queries>` block
/// - MetroV installed before this app (otherwise permission is not granted;
///   reinstall fixes it)
class MetrovThemeService {
  static const _channel = MethodChannel(
    'com.example.flutter_metro_contacts/metrov_theme',
  );

  /// Returns the MetroV accent color, or null if MetroV is not installed,
  /// the permission isn't granted, or the query failed.
  static Future<Color?> getAccentColor() async {
    try {
      final raw = await _channel.invokeMethod<int>('getAccentArgb');
      if (raw == null) return null;
      return Color(raw);
    } catch (_) {
      return null;
    }
  }
}