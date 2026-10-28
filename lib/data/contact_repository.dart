import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import '../other/constants.dart'; // For meStrings
import 'class_contact.dart';

class ContactRepository {
  /// Fetches contacts from the device, handles permissions,
  /// and separates the "Me" contact from the rest.
  Future<({List<Contact> contacts, Contact? meContact})> fetchContacts() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );

    if (status != PermissionStatus.granted) {
      // In a real app, you might throw a custom PermissionDeniedException here
      return (contacts: <Contact>[], meContact: null);
    }

    final rawContacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.photoThumbnail,
      },
    );

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
}