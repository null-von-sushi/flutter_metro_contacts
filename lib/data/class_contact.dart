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
  final Uint8List? photo;       // thumbnail — used in the list
  final Uint8List? photoFull;   // full-res — used in the Me tile and details
  final bool isMe;

  final List<ContactPhone> phones;
  final List<ContactEmail> emails;
  final List<ContactAddress> addresses;
  final List<String> notes;
  final DateTime? birthday;

  /// True if this contact has a raw entry owned by a Telegram app
  /// (or one of its known forks). See MessagingAccountTypes.
  final bool hasTelegram;

  /// True if this contact has a raw entry owned by Signal or a fork.
  final bool hasSignal;

  const Contact({
    required this.id,
    required this.name,
    this.nickname,
    required this.status,
    this.photo,
    this.photoFull,
    this.isMe = false,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
    this.notes = const [],
    this.birthday,
    this.hasTelegram = false,
    this.hasSignal = false,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? nickname,
    String? status,
    Uint8List? photo,
    Uint8List? photoFull,
    bool? isMe,
    List<ContactPhone>? phones,
    List<ContactEmail>? emails,
    List<ContactAddress>? addresses,
    List<String>? notes,
    DateTime? birthday,
    bool? hasTelegram,
    bool? hasSignal,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      status: status ?? this.status,
      photo: photo ?? this.photo,
      photoFull: photoFull ?? this.photoFull,
      isMe: isMe ?? this.isMe,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      addresses: addresses ?? this.addresses,
      notes: notes ?? this.notes,
      birthday: birthday ?? this.birthday,
      hasTelegram: hasTelegram ?? this.hasTelegram,
      hasSignal: hasSignal ?? this.hasSignal,
    );
  }

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

  bool get isBirthdayToday {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month && birthday!.day == now.day;
  }

  /// Highest FeatherLayer index used by ContactDetailsPage.
  ///
  /// Matches the layout in contact_details.dart:
  /// 0 = header, 1 = photo, then one section per phone, one Telegram
  /// section if present, one Signal section if present, then emails,
  /// addresses, birthday, notes, and finally the bottom app bar.
  int get detailsMaxIndex {
    int count = 2; // header + photo
    count += phones.length;
    if (hasTelegram && phones.isNotEmpty) count += 1;
    if (hasSignal && phones.isNotEmpty) count += 1;
    count += emails.length;
    count += addresses.length;
    if (birthday != null) count += 1;
    if (notes.isNotEmpty) count += 1;
    count += 1; // bottom application bar
    return count - 1;
  }
}