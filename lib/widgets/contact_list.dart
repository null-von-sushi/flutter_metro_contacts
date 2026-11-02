import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../data/class_contact.dart';
import '../data/list_entry.dart';
import '../logic/contact_grouper.dart';
import '../other/settings.dart';
import 'contact_widgets.dart';
import 'letter_grid_overlay.dart';

class ContactList extends StatefulWidget {
  final List<Contact> contacts;
  final Contact? meContact;
  final void Function(Contact)? onContactTap;
  final Settings settings;

  const ContactList({
    super.key,
    required this.contacts,
    required this.settings,
    this.meContact,
    this.onContactTap,
  });

  @override
  State<ContactList> createState() => ContactListState();
}

class ContactListState extends State<ContactList> {
  final ItemScrollController _scrollController = ItemScrollController();
  late List<ListEntry> _entries;
  late Map<String, int> _letterToIndex;
  late bool _prioritizeNicknames;
  late bool _surnameFirst;

  @override
  void initState() {
    super.initState();
    _prioritizeNicknames = widget.settings.prioritizeNicknames.value;
    _surnameFirst = widget.settings.surnameFirst.value;
    _rebuild();
    widget.settings.prioritizeNicknames.addListener(_onSettingChanged);
    widget.settings.surnameFirst.addListener(_onSettingChanged);
  }

  @override
  void didUpdateWidget(ContactList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.prioritizeNicknames
          .removeListener(_onSettingChanged);
      oldWidget.settings.surnameFirst.removeListener(_onSettingChanged);
      _prioritizeNicknames = widget.settings.prioritizeNicknames.value;
      _surnameFirst = widget.settings.surnameFirst.value;
      widget.settings.prioritizeNicknames.addListener(_onSettingChanged);
      widget.settings.surnameFirst.addListener(_onSettingChanged);
      _rebuild();
      return;
    }
    if (!identical(oldWidget.contacts, widget.contacts) ||
        !identical(oldWidget.meContact, widget.meContact)) {
      _rebuild();
    }
  }

  @override
  void dispose() {
    widget.settings.prioritizeNicknames.removeListener(_onSettingChanged);
    widget.settings.surnameFirst.removeListener(_onSettingChanged);
    super.dispose();
  }

  void _onSettingChanged() {
    final newPrioritize = widget.settings.prioritizeNicknames.value;
    final newSurnameFirst = widget.settings.surnameFirst.value;
    if (newPrioritize != _prioritizeNicknames ||
        newSurnameFirst != _surnameFirst) {
      setState(() {
        _prioritizeNicknames = newPrioritize;
        _surnameFirst = newSurnameFirst;
        _rebuild();
      });
    }
  }

  void _rebuild() {
    final result = groupContacts(
      widget.contacts,
      widget.meContact,
      prioritizeNicknames: _prioritizeNicknames,
      surnameFirst: _surnameFirst,
    );
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
        if (entry is MeEntry) {
          return MeTile(
            contact: entry.contact,
            surnameFirst: _surnameFirst,
            onTap: () => widget.onContactTap?.call(entry.contact),
          );
        }
        if (entry is HeaderEntry) {
          return SectionHeaderTile(
            letter: entry.letter,
            onTap: _showLetterGrid,
          );
        }
        final contact = (entry as ContactEntry).contact;
        return ContactTile(
          contact: contact,
          prioritizeNicknames: _prioritizeNicknames,
          surnameFirst: _surnameFirst,
          onTap: () => widget.onContactTap?.call(contact),
        );
      },
    );
  }
}