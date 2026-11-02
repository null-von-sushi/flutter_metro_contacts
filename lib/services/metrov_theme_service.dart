import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reads MetroV Launcher's accent color via its ContentProvider.
///
/// Requires:
/// - `<uses-permission android:name="com.tuzkituan.metrov.permission.READ_THEME"/>`
///   in AndroidManifest.xml
/// - `<provider android:authorities="com.tuzkituan.metrov.theme"/>` in the
///   `<queries>` block
/// - MetroV installed before this app; otherwise reinstall this app to
///   grant the permission.
class MetrovThemeService {
  static const _channel = MethodChannel(
    'com.example.flutter_metro_contacts/metrov_theme',
  );

  /// Returns the MetroV accent color, or null if MetroV is not installed,
  /// the permission isn't granted, or the query returned an unexpected
  /// value.
  ///
  /// Diagnostic logging is included so `flutter run` shows the reason for
  /// any failure: `PERMISSION_DENIED`, `NULL_CURSOR`, `EMPTY_CURSOR`,
  /// `NO_COLUMN`, `NULL_VALUE`, `ZERO_VALUE`, or `QUERY_ERROR`.
  static Future<Color?> getAccentColor() async {
    try {
      final raw = await _channel.invokeMethod<int>('getAccentArgb');
      if (raw == null) {
        debugPrint('[MetroV] accent query returned null');
        return null;
      }
      if (raw == 0) {
        // Transparent — treat as "not set" so we fall back cleanly.
        debugPrint('[MetroV] accent query returned 0 (transparent)');
        return null;
      }
      final color = Color(raw);
      debugPrint(
        '[MetroV] accent = '
            '#${raw.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      );
      return color;
    } on PlatformException catch (e) {
      debugPrint('[MetroV] accent query failed: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[MetroV] accent query failed: $e');
      return null;
    }
  }
}