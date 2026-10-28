import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../data/class_contact.dart';
import '../data/list_entry.dart';
import '../logic/contact_grouper.dart';
import '../transitions/wp_phone_transition.dart';
import 'contact_widgets.dart';
import 'letter_grid_overlay.dart';

class ContactList extends StatefulWidget {
  final List<Contact> contacts;
  final Contact? meContact;

  const ContactList({super.key, required this.contacts, this.meContact});

  @override
  State<ContactList> createState() => ContactListState();
}

class ContactListState extends State<ContactList> {
  final ItemScrollController _scrollController = ItemScrollController();
  late final List<ListEntry> _entries;
  late final Map<String, int> _letterToIndex;

  @override
  void initState() {
    super.initState();
    final result = groupContacts(widget.contacts, widget.meContact);
    _entries = result.entries;
    _letterToIndex = result.letterToIndex;
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
        return LetterGridOverlay(
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
        return FeatherLayer(
          index: index > 12 ? 12 : index,
          child: _buildEntryWidget(entry),
        );
      },
    );
  }

  Widget _buildEntryWidget(ListEntry entry) {
    if (entry is MeEntry) {
      return MeTile(contact: entry.contact);
    }
    if (entry is HeaderEntry) {
      return SectionHeaderTile(
        letter: entry.letter,
        onTap: _showLetterGrid,
      );
    }
    if (entry is ContactEntry) {
      return ContactTile(contact: entry.contact);
    }
    return const SizedBox.shrink();
  }
}