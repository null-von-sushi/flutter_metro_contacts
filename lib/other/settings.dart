import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences.
///
/// Two boolean toggles are surfaced so far, both from the Settings page:
///
/// * [prioritizeNicknames]: when true, contacts are shown with their
///   nickname as the title and their legal name as the subtitle. When
///   false, the legal name is the title and the nickname (if any) the
///   subtitle. The detail page is unaffected — it always shows both.
///
/// * [parseNotesForAccentColor]: when true, a "favorite colour" phrase
///   in a contact's notes overrides the global accent colour for that
///   contact's detail page. When false, the global accent is always used.
///
/// Settings are persisted to disk using [SharedPreferences] and loaded
/// automatically via the [load] factory. Toggling a value updates the
/// notifier and triggers an asynchronous save in the background.
class Settings {
  final ValueNotifier<bool> prioritizeNicknames;
  final ValueNotifier<bool> parseNotesForAccentColor;

  Settings._({
    required bool prioritizeNicknames,
    required bool parseNotesForAccentColor,
  })  : prioritizeNicknames = ValueNotifier(prioritizeNicknames),
        parseNotesForAccentColor = ValueNotifier(parseNotesForAccentColor) {
    // Persist whenever either toggle changes.
    this.prioritizeNicknames.addListener(_save);
    this.parseNotesForAccentColor.addListener(_save);
  }

  /// Loads persisted settings from disk. Call this in `main()` before
  /// `runApp` to ensure the UI reflects the saved state on first frame.
  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings._(
      prioritizeNicknames: prefs.getBool('prioritizeNicknames') ?? false,
      parseNotesForAccentColor:
      prefs.getBool('parseNotesForAccentColor') ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prioritizeNicknames', prioritizeNicknames.value);
    await prefs.setBool(
        'parseNotesForAccentColor', parseNotesForAccentColor.value);
  }

  void dispose() {
    prioritizeNicknames.dispose();
    parseNotesForAccentColor.dispose();
  }
}