import 'package:flutter/foundation.dart';

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
/// Both notifiers are listened to by the widgets that care, so changing
/// them updates the UI immediately without any state plumbing in between.
class Settings {
  final ValueNotifier<bool> prioritizeNicknames;
  final ValueNotifier<bool> parseNotesForAccentColor;

  Settings({
    bool prioritizeNicknames = false,
    bool parseNotesForAccentColor = false,
  })  : prioritizeNicknames = ValueNotifier(prioritizeNicknames),
        parseNotesForAccentColor = ValueNotifier(parseNotesForAccentColor);

  void dispose() {
    prioritizeNicknames.dispose();
    parseNotesForAccentColor.dispose();
  }
}