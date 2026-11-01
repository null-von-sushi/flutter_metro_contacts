import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import '../other/constants.dart';
import 'class_contact.dart';

const int _noYearSentinel = 1804;

class ContactRepository {
  Future<({List<Contact> contacts, Contact? meContact})> fetchContacts() async {
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 5));
    }

    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );

    if (status != PermissionStatus.granted) {
      return (contacts: <Contact>[], meContact: null);
    }

    // ── Pass 1: everyone, thumbnails only ────────────────────────────
    final fetchedContacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.photoThumbnail,
        ContactProperty.phone,
        ContactProperty.email,
        ContactProperty.address,
        ContactProperty.note,
        ContactProperty.event,
        ContactProperty.identifiers, // populates c.android.identifiers.rawContacts
      },
    );

    final List<Contact> otherContacts = [];
    Contact? meContact;
    String? meId;

    for (final c in fetchedContacts) {
      final name = c.displayName;
      final nickname = c.name?.nickname;
      final isMe =
          nickname != null && meStrings.contains(nickname.trim().toLowerCase());

      // Correct path: Contact → android → identifiers → rawContacts → account
      final rawRows = c.android?.identifiers?.rawContacts ?? const [];

      // Diagnostic — remove once the messenger detection is confirmed working.
      if (rawRows.isNotEmpty) {
        debugPrint(
          'RAW ${c.displayName}: '
              '${rawRows.map((rc) => rc.account?.toString()).toList()}',
        );
      }

      final hasTelegram = rawRows.any(
            (rc) => rc.account?.type != null &&
            MessagingAccountTypes.telegramMessenger.contains(rc.account!.type),
      );
      final hasSignal = rawRows.any(
            (rc) => rc.account?.type != null &&
            MessagingAccountTypes.signalMessenger.contains(rc.account!.type),
      );

      final contact = Contact(
        id: c.id ?? '',
        name: (name != null && name.isNotEmpty) ? name : 'Unknown Contact',
        nickname: nickname,
        status: ' ',
        photo: c.photo?.thumbnail,
        photoFull: null,
        isMe: isMe,
        phones: _mapPhones(c),
        emails: _mapEmails(c),
        addresses: _mapAddresses(c),
        notes: _mapNotes(c),
        birthday: _extractBirthday(c),
        hasTelegram: hasTelegram,
        hasSignal: hasSignal,
      );

      if (isMe) {
        if (meContact == null) {
          meContact = contact;
          meId = c.id;
        }
      } else {
        otherContacts.add(contact);
      }
    }

    // ── Pass 2: full-res photo for just the Me contact ──────────────
    if (meId != null) {
      try {
        final full = await FlutterContacts.get(
          meId,
          properties: {ContactProperty.photoFullRes},
        );
        final bytes = full?.photo?.fullSize;
        if (bytes != null && bytes.isNotEmpty) {
          meContact = meContact!.copyWith(photoFull: bytes);
        }
      } catch (_) {}
    }

    return (contacts: otherContacts, meContact: meContact);
  }

  // ── Phones / Emails / Addresses / Notes ─────────────────────────────

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

  // ── Birthday extraction ─────────────────────────────────────────────

  DateTime? _extractBirthday(dynamic c) {
    try {
      final events = c.events;
      if (events is! List || events.isEmpty) return null;
      for (final event in events) {
        final labelName = _labelDisplayName(event.label);
        if (labelName?.toLowerCase() != 'birthday') continue;

        final direct = _coerceToDateTime(_readRaw(event, 'date'));
        if (direct != null) return direct;

        final y = _asInt(_readRaw(event, 'year'));
        final m = _asInt(_readRaw(event, 'month'));
        final d = _asInt(_readRaw(event, 'day'));
        if (m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          final year = (y != null && y >= 1900) ? y : _noYearSentinel;
          return DateTime(year, m, d);
        }

        for (final f in const [
          'dateString', 'startDate', 'start_date',
          'formatted', 'formattedDate', 'value',
        ]) {
          final raw = _readRaw(event, f);
          if (raw is String && raw.isNotEmpty) {
            final parsed = _parseEventDateString(raw);
            if (parsed != null) return parsed;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  DateTime? _parseEventDateString(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    final full = DateTime.tryParse(trimmed);
    if (full != null) {
      if (full.year >= 1 && full.year < 1900) {
        return DateTime(_noYearSentinel, full.month, full.day);
      }
      if (full.year >= 1) return full;
    }

    final partial = RegExp(r'^--(\d{1,2})-(\d{1,2})$').firstMatch(trimmed);
    if (partial != null) {
      final m = int.tryParse(partial.group(1)!);
      final d = int.tryParse(partial.group(2)!);
      if (m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(_noYearSentinel, m, d);
      }
    }

    final zeroYear =
    RegExp(r'^0{4}[-/](\d{1,2})[-/](\d{1,2})').firstMatch(trimmed);
    if (zeroYear != null) {
      final m = int.tryParse(zeroYear.group(1)!);
      final d = int.tryParse(zeroYear.group(2)!);
      if (m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(_noYearSentinel, m, d);
      }
    }

    return null;
  }

  DateTime? _coerceToDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      if (raw.year < 1) return null;
      if (raw.year < 1900) return DateTime(_noYearSentinel, raw.month, raw.day);
      return raw;
    }
    if (raw is String) return _parseEventDateString(raw);
    for (final f in const ['date', 'value', 'time']) {
      final inner = _readRaw(raw, f);
      if (inner is DateTime) {
        if (inner.year < 1) return null;
        if (inner.year < 1900) {
          return DateTime(_noYearSentinel, inner.month, inner.day);
        }
        return inner;
      }
      if (inner is String) {
        final p = _parseEventDateString(inner);
        if (p != null) return p;
      }
    }
    return null;
  }

  dynamic _readRaw(dynamic item, String field) {
    if (item == null) return null;
    try {
      switch (field) {
        case 'date':          return item.date;
        case 'label':         return item.label;
        case 'customLabel':   return item.customLabel;
        case 'year':          return item.year;
        case 'month':         return item.month;
        case 'day':           return item.day;
        case 'dateString':    return item.dateString;
        case 'startDate':     return item.startDate;
        case 'start_date':    return item.start_date;
        case 'formattedDate': return item.formattedDate;
        case 'formatted':     return item.formatted;
        case 'value':         return item.value;
        case 'timestamp':     return item.timestamp;
        case 'time':          return item.time;
      }
    } catch (_) {}
    return null;
  }

  // ── Header derivation ───────────────────────────────────────────────

  String _headerFor(dynamic item, {required String fallback}) {
    final labelObj = _tryRead(item, 'label');

    final custom = _tryReadString(labelObj, 'customLabel') ??
        _tryReadString(item, 'customLabel');
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }

    final standard = _labelDisplayName(labelObj);
    if (standard != null &&
        standard.isNotEmpty &&
        standard.toLowerCase() != 'custom') {
      return _capitalizeFirst(standard);
    }

    return fallback;
  }

  String? _labelDisplayName(dynamic labelObj) {
    if (labelObj == null) return null;
    if (labelObj is String) return labelObj.isEmpty ? null : labelObj;

    try {
      final inner = (labelObj as dynamic).label;
      if (inner != null) {
        final n = _enumName(inner);
        if (n != null && n.isNotEmpty) return n;
      }
    } catch (_) {}

    try {
      final n = (labelObj as dynamic).name;
      if (n is String && n.isNotEmpty) return n;
    } catch (_) {}

    final s = labelObj.toString();
    final m = RegExp(r'label:\s*([A-Za-z_][A-Za-z0-9_]*)').firstMatch(s);
    if (m != null) return m.group(1);

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