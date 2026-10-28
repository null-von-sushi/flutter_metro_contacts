import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';
import 'widgets/bottom_app_bar.dart';
import 'widgets/wp_button.dart';

class ContactDetailsPage extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onPopStart;

  const ContactDetailsPage({
    super.key,
    required this.contact,
    this.onPopStart,
  });

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  Uint8List? _fullPhoto;

  @override
  void initState() {
    super.initState();
    _loadFullPhoto();
  }

  /// Fetch the full-resolution photo in the background. The list-level
  /// thumbnail (widget.contact.photo) is shown until this completes.
  Future<void> _loadFullPhoto() async {
    try {
      final full = await FlutterContacts.get(
        widget.contact.id,
        properties: {ContactProperty.photoFullRes},
      );
      final bytes = full?.photo?.fullSize;
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() => _fullPhoto = bytes);
      }
    } catch (_) {}
  }

  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop();
  }

  void _handleEdit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Edit Contact'),
        content: const Text('Edit form will go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save', style: TextStyle(color: AccentColor)),
          ),
        ],
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        // Sharp corners — WP8.1 had no rounded UI elements.
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete ${widget.contact.name}?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WpButton(
                    label: 'cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  WpButton(
                    label: 'delete',
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: call FlutterContacts.delete(widget.contact.id).
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBirthday(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final month = months[date.month - 1];
    if (date.year < 1900) {
      return '${date.day} $month';
    }
    return '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final maxIndex = c.detailsMaxIndex;
    final isBirthdayToday = c.isBirthdayToday;

    int next = 2;
    int assign() {
      final i = next;
      if (next < maxIndex) next++;
      return i;
    }

    final children = <Widget>[
      FeatherLayer(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTACT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      c.detailsTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isBirthdayToday) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.cake_outlined,
                      color: AccentColor,
                      size: 26,
                      semanticLabel: 'Birthday today',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      FeatherLayer(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _ProfilePhoto(
            name: c.name,
            photo: _fullPhoto ?? c.photo,
          ),
        ),
      ),
    ];

    for (final p in c.phones) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(header: p.header, value: p.number),
      ));
    }

    for (final e in c.emails) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(header: e.header, value: e.address),
      ));
    }

    for (final a in c.addresses) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(header: a.header, value: a.formatted),
      ));
    }

    if (c.birthday != null) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Birthday',
          value: _formatBirthday(c.birthday!),
        ),
      ));
    }

    if (c.notes.isNotEmpty) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Notes',
          value: c.notes.join('\n\n'),
        ),
      ));
    }

    final bottomBarIndex = assign();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: children,
          ),
        ),
        bottomNavigationBar: FeatherLayer(
          index: bottomBarIndex,
          child: WpBottomAppBar(
            actions: [
              WpApplicationBarAction(
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: 'edit',
                onPressed: _handleEdit,
              ),
            ],
            menuItems: [
              WpApplicationBarMenuItem(
                label: 'delete',
                onPressed: _handleDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final String name;
  final Uint8List? photo;

  const _ProfilePhoto({required this.name, required this.photo});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 160,
        height: 160,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: AccentColor),
        child: photo != null
            ? Image.memory(
          photo!,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          // Decode at ~3x display size for retina crispness without
          // the memory cost of a full-resolution decode.
          cacheWidth: 480,
          cacheHeight: 480,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        )
            : Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String header;
  final String value;

  const _InfoSection({required this.header, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 0),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: AccentColor,
            ),
          ),
        ],
      ),
    );
  }
}