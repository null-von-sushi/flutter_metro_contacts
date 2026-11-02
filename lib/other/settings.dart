import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences.
///
/// Three kinds of state live here:
///
/// * Display toggles: [prioritizeNicknames], [parseNotesForAccentColor].
/// * List filters: [accountFilter] (Account.id) and [groupFilter] (Group.id).
///   `null` means "no restriction".
/// * Persistence: values are loaded on startup and written back whenever
///   a notifier changes.
///
/// Filters only apply to the main "all" pivot in PeoplePage. The favorites
/// and recent pivots intentionally ignore them.
class Settings {
  final ValueNotifier<bool> prioritizeNicknames;
  final ValueNotifier<bool> parseNotesForAccentColor;

  /// Account.id to restrict the list to. `null` = show all accounts.
  final ValueNotifier<String?> accountFilter;

  /// Group.id to restrict the list to. Only meaningful when an account is
  /// selected, since groups are account-scoped on Android.
  final ValueNotifier<String?> groupFilter;

  Settings._({
    required bool prioritizeNicknames,
    required bool parseNotesForAccentColor,
    required String? accountFilter,
    required String? groupFilter,
  })  : prioritizeNicknames = ValueNotifier(prioritizeNicknames),
        parseNotesForAccentColor = ValueNotifier(parseNotesForAccentColor),
        accountFilter = ValueNotifier(accountFilter),
        groupFilter = ValueNotifier(groupFilter) {
    this.prioritizeNicknames.addListener(_save);
    this.parseNotesForAccentColor.addListener(_save);
    this.accountFilter.addListener(_save);
    this.groupFilter.addListener(_save);
  }

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings._(
      prioritizeNicknames: prefs.getBool('prioritizeNicknames') ?? false,
      parseNotesForAccentColor:
      prefs.getBool('parseNotesForAccentColor') ?? false,
      accountFilter: prefs.getString('accountFilter'),
      groupFilter: prefs.getString('groupFilter'),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prioritizeNicknames', prioritizeNicknames.value);
    await prefs.setBool(
        'parseNotesForAccentColor', parseNotesForAccentColor.value);
    final acc = accountFilter.value;
    final grp = groupFilter.value;
    if (acc == null) {
      await prefs.remove('accountFilter');
    } else {
      await prefs.setString('accountFilter', acc);
    }
    if (grp == null) {
      await prefs.remove('groupFilter');
    } else {
      await prefs.setString('groupFilter', grp);
    }
  }

  void dispose() {
    prioritizeNicknames.dispose();
    parseNotesForAccentColor.dispose();
    accountFilter.dispose();
    groupFilter.dispose();
  }
}