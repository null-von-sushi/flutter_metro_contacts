import 'dart:typed_data';

/// A single phone number with its display header pre-formatted.
class ContactPhone {
  final String number;
  /// "Mobile", "Home", "Work", "Phone (Vodafone)", etc.
  final String header;
  const ContactPhone({required this.number, required this.header});
}

class ContactEmail {
  final String address;
  /// "Email", "Email (Work)", etc.
  final String header;
  const ContactEmail({required this.address, required this.header});
}

class ContactAddress {
  final String formatted;
  /// "Address", "Address (Home)", etc.
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
  });

  String get displayTitle =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  String get displaySubtitle {
    if (nickname != null && nickname!.isNotEmpty && nickname != name) {
      return name;
    }
    return status;
  }

  /// Title for the contact-details page: "Full Name (Nickname)".
  String get detailsTitle {
    if (nickname != null && nickname!.isNotEmpty && nickname != name) {
      return '$name ($nickname)';
    }
    return name;
  }

  /// Highest FeatherLayer index the details page will use.
  int get detailsMaxIndex {
    int count = 2; // header + photo
    count += phones.length;
    count += emails.length;
    count += addresses.length;
    if (notes.isNotEmpty) count += 1;
    return count - 1;
  }
}