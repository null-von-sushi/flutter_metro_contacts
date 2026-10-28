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

  // ── Phones / Emails / Addresses / Notes ──────────────────────────────
  // (unchanged — same as your current version)

  List<ContactPhone> _mapPhones(dynamic c) {
    final result = <ContactPhone>[];
    try {
      for (final p in (c.phones as List)) {
        final number = (p.number as String?) ?? '';
        if (number.isEmpty) continue;
        result.add(ContactPhone(
          number: number,
          header: _headerFor(p, fallback: 'Phone'),
        ));
      }
    } catch (_) {}
    return result;
  }

  List<ContactEmail> _mapEmails(dynamic c) {
    final result = <ContactEmail>[];
    try {
      for (final e in (c.emails as List)) {
        final addr = (e.address as String?) ?? '';
        if (addr.isEmpty) continue;
        result.add(ContactEmail(
          address: addr,
          header: _headerFor(e, fallback: 'Email'),
        ));
      }
    } catch (_) {}
    return result;
  }

  List<ContactAddress> _mapAddresses(dynamic c) {
    final result = <ContactAddress>[];
    try {
      for (final a in (c.addresses as List)) {
        final formatted = _addressToString(a);
        if (formatted.isEmpty) continue;
        result.add(ContactAddress(
          formatted: formatted,
          header: _headerFor(a, fallback: 'Address'),
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

  // ── Header derivation ────────────────────────────────────────────────

  /// Produces the section header for a phone/email/address row.
  ///
  /// Rules:
  /// - **Custom label** (user-typed, e.g. "iPhone", "Mum's work") → verbatim.
  ///   The user chose that casing; don't override it.
  /// - **Standard label** (an enum value like `home`, `work`, `mobile`) →
  ///   capitalized first letter (`Home`, `Work`, `Mobile`).
  /// - **No usable label** → fallback ("Phone" / "Email" / "Address").
  String _headerFor(dynamic item, {required String fallback}) {
    final labelObj = _tryRead(item, 'label');

    // 1. Custom label — try both the wrapper and the parent object.
    final custom = _tryReadString(labelObj, 'customLabel') ??
        _tryReadString(item, 'customLabel');
    if (custom != null && custom.isNotEmpty) {
      return custom; // verbatim
    }

    // 2. Standard label enum.
    final standard = _labelDisplayName(labelObj);
    if (standard != null &&
        standard.isNotEmpty &&
        standard.toLowerCase() != 'custom') {
      return _capitalizeFirst(standard);
    }

    // 3. Nothing usable.
    return fallback;
  }

  /// Extracts a standard label's bare name (e.g. `PhoneLabel.home` → "home").
  /// Does **not** extract custom labels — those are handled by [_headerFor].
  String? _labelDisplayName(dynamic labelObj) {
    if (labelObj == null) return null;
    if (labelObj is String) return labelObj.isEmpty ? null : labelObj;

    // The inner `.label` field (a real enum in most versions).
    try {
      final inner = (labelObj as dynamic).label;
      if (inner != null) {
        final n = _enumName(inner);
        if (n != null && n.isNotEmpty) return n;
      }
    } catch (_) {}

    // `.name` directly (if labelObj IS the enum).
    try {
      final n = (labelObj as dynamic).name;
      if (n is String && n.isNotEmpty) return n;
    } catch (_) {}

    // Parse the stringified form "Label(label: home[, customLabel: x])".
    final s = labelObj.toString();
    final m = RegExp(r'label:\s*([A-Za-z_][A-Za-z0-9_]*)').firstMatch(s);
    if (m != null) return m.group(1);

    // Last resort: "PhoneLabel.home" → "home".
    final parts = s.split('.');
    if (parts.length > 1) return parts.last;

    return null;
  }

  String? _enumName(dynamic e) {
    if (e == null) return null;
    if (e is String) return e.isEmpty ? null : e;
    try {
      final n = (e as dynamic).name;
      if (n is String && n.isNotEmpty) return n;
    } catch (_) {}
    final s = e.toString();
    final parts = s.split('.');
    if (parts.length > 1) return parts.last;
    return s.isEmpty ? null : s;
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  dynamic _tryRead(dynamic item, String field) {
    if (item == null) return null;
    try {
      switch (field) {
        case 'label':
          return item.label;
        case 'customLabel':
          return item.customLabel;
      }
    } catch (_) {}
    return null;
  }

  String? _tryReadString(dynamic item, String field) {
    final v = _tryRead(item, field);
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  String _addressToString(dynamic a) {
    try {
      final formatted = a.formatted;
      if (formatted is String && formatted.isNotEmpty) return formatted;
    } catch (_) {}
    try {
      final parts = <String>[];
      for (final field in const ['street', 'city', 'region', 'postcode', 'country']) {
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