import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'settings_page.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'logic/get_grouping_letter.dart';
import 'other/constants.dart';
import 'logic/pinyin_utils.dart'; // <-- Add this
import 'logic/get_grouping_letter.dart'; // <-- Make sure this is here

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'People',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: wpPivotFontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PeoplePage(),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  late Future<({List<Contact> contacts, Contact? meContact})> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchContacts();
  }

  Future<({List<Contact> contacts, Contact? meContact})> _fetchContacts() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );

    if (status != PermissionStatus.granted) {
      debugPrint('Permission denied by user.');
      return (contacts: <Contact>[], meContact: null);
    }

    final rawContacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.photoThumbnail,
      },
    );

    debugPrint('Fetched ${rawContacts.length} contacts from device.');

    final List<Contact> otherContacts = [];
    Contact? meContact;

    for (final c in rawContacts) {
      final name = c.displayName;
      final nickname = c.name?.nickname;
      final isMe =
          nickname != null && meStrings.contains(nickname.trim().toLowerCase());

      final contact = Contact(
        id: c.id ?? '',
        name: (name != null && name.isNotEmpty) ? name : 'Unknown Contact',
        nickname: nickname,
        status: ' ',
        photo: c.photo?.thumbnail,
        isMe: isMe,
      );

      if (isMe) {
        meContact ??= contact;
      } else {
        otherContacts.add(contact);
      }
    }

    return (contacts: otherContacts, meContact: meContact);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _addNewContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('New Contact'),
        content: const Text('Add contact form will go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save', style: TextStyle(color: AccentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WpPivotView(
          title: 'PEOPLE',
          tabTitles: const ['all', 'recent', 'rooms'],
          wrap: true,
          children: [
            FutureBuilder<({List<Contact> contacts, Contact? meContact})>(
              future: _contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Failed to load contacts',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || data.contacts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts found or permission denied.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return _ContactList(
                  contacts: data.contacts,
                  meContact: data.meContact,
                );
              },
            ),
            const _ContactList(contacts: []),
            const _ContactList(contacts: []),
          ],
        ),
      ),
      bottomNavigationBar: WpApplicationBar(
        mode: WpApplicationBarMode.defaultMode,
        actions: [
          WpApplicationBarAction(
            icon: const Icon(Icons.add, size: 20),
            label: 'add',
            onPressed: _addNewContact,
          ),
        ],
        menuItems: [
          WpApplicationBarMenuItem(
            label: 'settings',
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }
}

/// A contact list with tile-based alphabetical grouping and a jump grid.
class _ContactList extends StatefulWidget {
  final List<Contact> contacts;
  final Contact? meContact;

  const _ContactList({required this.contacts, this.meContact});

  @override
  State<_ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<_ContactList> {
  final ItemScrollController _scrollController = ItemScrollController();

  late final List<_ListEntry> _entries;
  late final Map<String, int> _letterToIndex;

  @override
  void initState() {
    super.initState();
    _buildGroupedEntries();
  }

  void _buildGroupedEntries() {
    final sorted = List<Contact>.from(widget.contacts)
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
    _entries = [];
    _letterToIndex = {};

    if (widget.meContact != null) {
      _entries.add(_MeEntry(widget.meContact!));
    }

    for (final letter in letters) {
      _letterToIndex[letter] = _entries.length;
      _entries.add(_HeaderEntry(letter));
      for (final contact in grouped[letter]!) {
        _entries.add(_ContactEntry(contact));
      }
    }
  }

  void _jumpToLetter(String letter) {
    final index = _letterToIndex[letter];
    if (index != null) {
      _scrollController.jumpTo(index: index);
    }
  }

  void _showLetterGrid() {
    final availableLetters = _letterToIndex.keys.toList()..sort();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return _LetterGridOverlay(
          letters: availableLetters,
          onLetterSelected: (letter) {
            Navigator.of(dialogContext).pop();
            _jumpToLetter(letter);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'No contacts in this category.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemCount: _entries.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        if (entry is _MeEntry) {
          return _MeTile(contact: entry.contact);
        }
        if (entry is _HeaderEntry) {
          return _SectionHeaderTile(
            letter: entry.letter,
            onTap: _showLetterGrid,
          );
        }
        return _ContactTile(contact: (entry as _ContactEntry).contact);
      },
    );
  }
}

/// The larger Windows Phone "Me" tile at the top of the list.
class _MeTile extends StatelessWidget {
  final Contact contact;

  const _MeTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final avatarLetter = contact.name.isNotEmpty
        ? contact.name[0].toUpperCase()
        : '#';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AccentColor,
            ),
            child: contact.photo != null
                ? Image.memory(
              contact.photo!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            )
                : Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AccentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The tappable square letter header inside the list.
class _SectionHeaderTile extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;

  const _SectionHeaderTile({required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              color: AccentColor,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-screen overlay grid of letters.
class _LetterGridOverlay extends StatelessWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterSelected;

  const _LetterGridOverlay({
    required this.letters,
    required this.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: letters.length,
              itemBuilder: (context, index) {
                final letter = letters[index];
                return GestureDetector(
                  onTap: () => onLetterSelected(letter),
                  child: Container(
                    color: AccentColor,
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A single contact row with a square avatar (photo or letter), name, and status.
class _ContactTile extends StatelessWidget {
  final Contact contact;

  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final avatarLetter = contact.name.isNotEmpty
        ? contact.name[0].toUpperCase()
        : '#';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.white24,
            ),
            child: contact.photo != null
                ? Image.memory(
              contact.photo!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            )
                : Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                if (contact.displaySubtitle.isNotEmpty)
                  Text(
                    contact.displaySubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flattened list entry types.
abstract class _ListEntry {}

class _MeEntry extends _ListEntry {
  final Contact contact;
  _MeEntry(this.contact);
}

class _HeaderEntry extends _ListEntry {
  final String letter;
  _HeaderEntry(this.letter);
}

class _ContactEntry extends _ListEntry {
  final Contact contact;
  _ContactEntry(this.contact);
}