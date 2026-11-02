import 'package:flutter/material.dart';
import '../data/class_contact.dart';
import '../other/accent_color.dart';

class MeTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final bool surnameFirst;

  const MeTile({
    super.key,
    required this.contact,
    this.onTap,
    this.surnameFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = contact.nameFor(surnameFirst);
    final avatarLetter =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : '#';

    final bytes = contact.photoFull ?? contact.photo;

    return InkWell(
      onTap: onTap,
      child: Padding(
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
              child: bytes != null
                  ? Image.memory(
                bytes,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                cacheWidth: 360,
                cacheHeight: 360,
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
                    displayName,
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
  final VoidCallback? onTap;
  final bool prioritizeNicknames;
  final bool surnameFirst;

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.prioritizeNicknames = false,
    this.surnameFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = contact.nameFor(surnameFirst);
    final avatarLetter =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : '#';

    final title = contact.displayTitle(prioritizeNicknames, surnameFirst);
    final subtitle = contact.displaySubtitle(prioritizeNicknames, surnameFirst);

    return InkWell(
      onTap: onTap,
      child: Padding(
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
                cacheWidth: 168,
                cacheHeight: 168,
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
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
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
      ),
    );
  }
}