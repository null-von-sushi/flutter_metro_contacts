import 'package:flutter/material.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';

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
  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final maxIndex = c.detailsMaxIndex;

    int next = 2; // 0 = header, 1 = photo
    int assign() {
      final i = next;
      if (next < maxIndex) next++;
      return i;
    }

    final children = <Widget>[
      // Smallcaps page header + name (index 0)
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
              Text(
                c.detailsTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),

      // Profile photo (index 1)
      FeatherLayer(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _ProfilePhoto(contact: c),
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

    if (c.notes.isNotEmpty) {
      children.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Notes',
          value: c.notes.join('\n\n'),
        ),
      ));
    }

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
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final Contact contact;

  const _ProfilePhoto({required this.contact});

  @override
  Widget build(BuildContext context) {
    final letter = contact.name.isNotEmpty
        ? contact.name[0].toUpperCase()
        : '#';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 160,
        height: 160,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: AccentColor),
        child: contact.photo != null
            ? Image.memory(
          contact.photo!,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
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
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
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