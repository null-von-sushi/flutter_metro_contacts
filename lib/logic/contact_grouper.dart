import '../data/class_contact.dart';
import '../data/list_entry.dart';
import 'get_grouping_letter.dart';
import 'pinyin_utils.dart';

/// Takes raw contacts and prepares them for the UI:
/// 1. Sorts them alphabetically (with pinyin support).
/// 2. Groups them by letter.
/// 3. Flattens them into a single list of ListEntry objects.
/// 4. Builds the letter-to-index map for the jump grid.
///
/// The sort key and grouping letter come from [Contact.displayTitle],
/// which honours both [prioritizeNicknames] and [surnameFirst]. So a
/// contact with the surname-first toggle on groups under their surname
/// letter, and with the nickname-first toggle on groups under their
/// nickname letter.
({List<ListEntry> entries, Map<String, int> letterToIndex}) groupContacts(
    List<Contact> contacts,
    Contact? meContact, {
      required bool prioritizeNicknames,
      required bool surnameFirst,
    }) {
  String sortKey(Contact c) =>
      c.displayTitle(prioritizeNicknames, surnameFirst);

  final sorted = List<Contact>.from(contacts)
    ..sort((a, b) {
      final keyA = getGroupingLetter(sortKey(a));
      final keyB = getGroupingLetter(sortKey(b));

      if (keyA == '#' && keyB != '#') return 1;
      if (keyA != '#' && keyB == '#') return -1;

      if (keyA != keyB) return keyA.compareTo(keyB);

      final pinyinA = PinyinUtils.getFullPinyin(sortKey(a));
      final pinyinB = PinyinUtils.getFullPinyin(sortKey(b));
      return pinyinA.toLowerCase().compareTo(pinyinB.toLowerCase());
    });

  final grouped = <String, List<Contact>>{};
  for (final contact in sorted) {
    final letter = getGroupingLetter(sortKey(contact));
    grouped.putIfAbsent(letter, () => []).add(contact);
  }

  final letters = grouped.keys.toList()..sort();
  final entries = <ListEntry>[];
  final letterToIndex = <String, int>{};

  if (meContact != null) {
    entries.add(MeEntry(meContact));
  }

  for (final letter in letters) {
    letterToIndex[letter] = entries.length;
    entries.add(HeaderEntry(letter));
    for (final contact in grouped[letter]!) {
      entries.add(ContactEntry(contact));
    }
  }

  return (entries: entries, letterToIndex: letterToIndex);
}