import '../data/class_contact.dart';
import '../data/list_entry.dart';
import 'get_grouping_letter.dart';
import 'pinyin_utils.dart';

/// Takes raw contacts and prepares them for the UI:
/// 1. Sorts them alphabetically (with pinyin support).
/// 2. Groups them by letter.
/// 3. Flattens them into a single list of ListEntry objects.
/// 4. Builds the letter-to-index map for the jump grid.
({List<ListEntry> entries, Map<String, int> letterToIndex}) groupContacts(
    List<Contact> contacts,
    Contact? meContact,
    ) {
  final sorted = List<Contact>.from(contacts)
    ..sort((a, b) {
      final keyA = getGroupingLetter(a.name);
      final keyB = getGroupingLetter(b.name);

      if (keyA == '#' && keyB != '#') return 1;
      if (keyA != '#' && keyB == '#') return -1;

      if (keyA != keyB) return keyA.compareTo(keyB);

      final pinyinA = PinyinUtils.getFullPinyin(a.name);
      final pinyinB = PinyinUtils.getFullPinyin(b.name);
      return pinyinA.toLowerCase().compareTo(pinyinB.toLowerCase());
    });

  final grouped = <String, List<Contact>>{};
  for (final contact in sorted) {
    final letter = getGroupingLetter(contact.name);
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