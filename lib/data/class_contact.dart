import 'dart:typed_data';

/// A single phone number with its display header pre-formatted.
class ContactPhone {
  final String number;
  final String header;
  const ContactPhone({required this.number, required this.header});
}

class ContactEmail {
  final String address;
  final String header;
  const ContactEmail({required this.address, required this.header});
}

class ContactAddress {
  final String formatted;
  final String header;
  const ContactAddress({required this.formatted, required this.header});
}

class Contact {
  final String id;
  final String name;
  final String? nickname;
  final String status;
  final Uint8List? photo;
  final bool isMe;

  final List<ContactPhone> phones;
  final List<ContactEmail> emails;
  final List<ContactAddress> addresses;
  final List<String> notes;
  final DateTime? birthday; // <-- new

  const Contact({
    required this.id,
    required this.name,
    this.nickname,
    required this.status,
    this.photo,
    this.isMe = false,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
    this.notes = const [],
    this.birthday,
  });

  String get displayTitle =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  String get displaySubtitle {
    if (nickname != null && nickname!.isNotEmpty && nickname != name) {
      return name;
    }
    return status;
  }

  String get detailsTitle {
    if (nickname != null && nickname!.isNotEmpty && nickname != name) {
      return '$name ($nickname)';
    }
    return name;
  }

  /// True if today (month + day) matches the stored birthday.
  bool get isBirthdayToday {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month && birthday!.day == now.day;
  }

  /// Highest FeatherLayer index the details page will use.
  int get detailsMaxIndex {
    int count = 2; // header + photo
    count += phones.length;
    count += emails.length;
    count += addresses.length;
    if (birthday != null) count += 1;
    if (notes.isNotEmpty) count += 1;
    count += 1; // <-- new: bottom application bar
    return count - 1;
  }
}