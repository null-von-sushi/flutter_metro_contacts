import 'package:flutter/material.dart';
import '../data/class_contact.dart';
import '../other/accent_color.dart';

class MeTile extends StatelessWidget {
  final Contact contact;
  const MeTile({super.key, required this.contact});

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

class SectionHeaderTile extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  const SectionHeaderTile({super.key, required this.letter, required this.onTap});

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

class ContactTile extends StatelessWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

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
