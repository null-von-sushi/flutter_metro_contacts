import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// App-wide user preferences.
///
/// Persisted keys:
///   prioritizeNicknames: bool
///   parseNotesForAccentColor: bool
///   surnameFirst: bool
///   accountFilter: String (composite "type|name" key)
///   groupFilter: String (Group.id)
///   selectedAccentArgb: int (ARGB)
///   useLauncherAccent: bool (default true; only meaningful when MetroV
///     Launcher is installed and its theme permission is granted)
class Settings {
  final ValueNotifier<bool> prioritizeNicknames;
  final ValueNotifier<bool> parseNotesForAccentColor;

  /// When true, names are composed from familyName + givenName with the
  /// surname first, regardless of the platform's locale-derived order.
  /// Falls back to the system display name if the structured parts are
  /// empty. See `Contact.nameFor`.
  final ValueNotifier<bool> surnameFirst;

  final ValueNotifier<String?> accountFilter;
  final ValueNotifier<String?> groupFilter;

  final ValueNotifier<int> selectedAccentArgb;
  final ValueNotifier<bool> useLauncherAccent;

  Settings._({
    required bool prioritizeNicknames,
    required bool parseNotesForAccentColor,
    required bool surnameFirst,
    required String? accountFilter,
    required String? groupFilter,
    required int selectedAccentArgb,
    required bool useLauncherAccent,
  })  : prioritizeNicknames = ValueNotifier(prioritizeNicknames),
        parseNotesForAccentColor = ValueNotifier(parseNotesForAccentColor),
        surnameFirst = ValueNotifier(surnameFirst),
        accountFilter = ValueNotifier(accountFilter),
        groupFilter = ValueNotifier(groupFilter),
        selectedAccentArgb = ValueNotifier(selectedAccentArgb),
        useLauncherAccent = ValueNotifier(useLauncherAccent) {
    this.prioritizeNicknames.addListener(_save);
    this.parseNotesForAccentColor.addListener(_save);
    this.surnameFirst.addListener(_save);
    this.accountFilter.addListener(_save);
    this.groupFilter.addListener(_save);
    this.selectedAccentArgb.addListener(_save);
    this.useLauncherAccent.addListener(_save);
  }

  factory Settings.inMemory({
    bool prioritizeNicknames = false,
    bool parseNotesForAccentColor = false,
    bool surnameFirst = false,
    String? accountFilter,
    String? groupFilter,
    int selectedAccentArgb = accentColorFallbackArgb,
    bool useLauncherAccent = true,
  }) =>
      Settings._(
        prioritizeNicknames: prioritizeNicknames,
        parseNotesForAccentColor: parseNotesForAccentColor,
        surnameFirst: surnameFirst,
        accountFilter: accountFilter,
        groupFilter: groupFilter,
        selectedAccentArgb: selectedAccentArgb,
        useLauncherAccent: useLauncherAccent,
      );

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings._(
      prioritizeNicknames: prefs.getBool('prioritizeNicknames') ?? false,
      parseNotesForAccentColor:
      prefs.getBool('parseNotesForAccentColor') ?? false,
      surnameFirst: prefs.getBool('surnameFirst') ?? false,
      accountFilter: prefs.getString('accountFilter'),
      groupFilter: prefs.getString('groupFilter'),
      selectedAccentArgb:
      prefs.getInt('selectedAccentArgb') ?? accentColorFallbackArgb,
      useLauncherAccent: prefs.getBool('useLauncherAccent') ?? true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prioritizeNicknames', prioritizeNicknames.value);
    await prefs.setBool(
        'parseNotesForAccentColor', parseNotesForAccentColor.value);
    await prefs.setBool('surnameFirst', surnameFirst.value);
    await prefs.setInt('selectedAccentArgb', selectedAccentArgb.value);
    await prefs.setBool('useLauncherAccent', useLauncherAccent.value);

    final acc = accountFilter.value;
    if (acc == null) {
      await prefs.remove('accountFilter');
    } else {
      await prefs.setString('accountFilter', acc);
    }
    final grp = groupFilter.value;
    if (grp == null) {
      await prefs.remove('groupFilter');
    } else {
      await prefs.setString('groupFilter', grp);
    }
  }

  void dispose() {
    prioritizeNicknames.dispose();
    parseNotesForAccentColor.dispose();
    surnameFirst.dispose();
    accountFilter.dispose();
    groupFilter.dispose();
    selectedAccentArgb.dispose();
    useLauncherAccent.dispose();
  }
}