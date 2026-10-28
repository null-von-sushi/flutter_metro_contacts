import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import '../other/constants.dart';
import 'class_contact.dart';

class ContactRepository {
  Future<({List<Contact> contacts, Contact? meContact})> fetchContacts() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );

    if (status != PermissionStatus.granted) {
      return (contacts: <Contact>[], meContact: null);
    }

    final rawContacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.photoThumbnail,
        ContactProperty.phone,
        ContactProperty.email,
        ContactProperty.address,
        ContactProperty.note,
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
        phones: _mapPhones(c),
        emails: _mapEmails(c),
        addresses: _mapAddresses(c),
        notes: _mapNotes(c),
      );

      if (isMe) {
        meContact ??= contact;
      } else {
        otherContacts.add(contact);
      }
    }

    return (contacts: otherContacts, meContact: meContact);
  }

  List<ContactPhone> _mapPhones(dynamic c) {
    final result = <ContactPhone>[];
    try {
      for (final p in c.phones as List) {
        final number = (p.number as String?) ?? '';
        if (number.isEmpty) continue;
        result.add(ContactPhone(
          number: number,
          header: _phoneHeader(p),
        ));
      }
    } catch (_) {}
    return result;
  }

  List<ContactEmail> _mapEmails(dynamic c) {
    final result = <ContactEmail>[];
    try {
      for (final e in c.emails as List) {
        final addr = (e.address as String?) ?? '';
        if (addr.isEmpty) continue;
        result.add(ContactEmail(
          address: addr,
          header: _labeledHeader(e, 'Email'),
        ));
      }
    } catch (_) {}
    return result;
  }

  List<ContactAddress> _mapAddresses(dynamic c) {
    final result = <ContactAddress>[];
    try {
      for (final a in c.addresses as List) {
        final formatted = _addressToString(a);
        if (formatted.isEmpty) continue;
        result.add(ContactAddress(
          formatted: formatted,
          header: _labeledHeader(a, 'Address'),
        ));
      }
    } catch (_) {}
    return result;
  }

  List<String> _mapNotes(dynamic c) {
    final result = <String>[];
    try {
      final notes = c.notes;
      if (notes is List) {
        for (final n in notes) {
          try {
            final text = n.note;
            if (text is String && text.isNotEmpty) result.add(text);
          } catch (_) {}
        }
      } else if (notes is String && notes.isNotEmpty) {
        result.add(notes);
      }
    } catch (_) {}
    return result;
  }

  String _phoneHeader(dynamic p) {
    // Custom label takes precedence.
    final custom = _tryRead(p, 'customLabel');
    if (custom is String && custom.isNotEmpty) {
      return 'Phone ($custom)';
    }
    final label = _tryRead(p, 'label');
    final name = _labelName(label);
    if (name == null) return 'Phone';
    // If the enum value is literally "custom" but we didn't get a customLabel,
    // fall back to generic "Phone".
    if (name.toLowerCase() == 'custom') return 'Phone';
    return name;
  }

  String _labeledHeader(dynamic item, String defaultType) {
    final custom = _tryRead(item, 'customLabel');
    if (custom is String && custom.isNotEmpty) {
      return '$defaultType ($custom)';
    }
    final label = _tryRead(item, 'label');
    final name = _labelName(label);
    if (name == null || name.toLowerCase() == 'custom') {
      return defaultType;
    }
    return name;
  }

  /// Reads a field from a dynamic object, returning null on NoSuchMethodError.
  dynamic _tryRead(dynamic item, String field) {
    try {
      switch (field) {
        case 'customLabel':
          return item.customLabel;
        case 'label':
          return item.label;
        case 'note':
          return item.note;
      }
    } catch (_) {}
    return null;
  }

  /// Turns a PhoneLabel/EmailLabel/AddressLabel enum into a display name,
  /// e.g. PhoneLabel.mobile → "Mobile".
  String? _labelName(dynamic label) {
    if (label == null) return null;
    if (label is String) {
      return label.isEmpty ? null : label;
    }
    final s = label.toString();
    final parts = s.split('.');
    final name = parts.last;
    if (name.isEmpty) return null;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _addressToString(dynamic a) {
    try {
      final formatted = a.formatted;
      if (formatted is String && formatted.isNotEmpty) return formatted;
    } catch (_) {}
    try {
      final parts = <String>[];
      final fields = ['street', 'city', 'region', 'postcode', 'country'];
      for (final field in fields) {
        String? v;
        try {
          switch (field) {
            case 'street':
              v = a.street as String?;
              break;
            case 'city':
              v = a.city as String?;
              break;
            case 'region':
              v = a.region as String?;
              break;
            case 'postcode':
              v = a.postcode as String?;
              break;
            case 'country':
              v = a.country as String?;
              break;
          }
        } catch (_) {}
        if (v != null && v.isNotEmpty) parts.add(v);
      }
      if (parts.isNotEmpty) return parts.join(', ');
    } catch (_) {}
    return a.toString();
  }
}