import 'dart:typed_data';

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
  final Uint8List? photoFull;
  final bool isMe;

  final List<ContactPhone> phones;
  final List<ContactEmail> emails;
  final List<ContactAddress> addresses;
  final List<String> notes;
  final DateTime? birthday;

  final bool hasTelegram;
  final bool hasSignal;
  final bool hasWeChat;

  // Optional identifiers extracted from a phone label or URL.
  // null when the contact has the messenger (via account) but no
  // specific handle was found.
  final String? signalId;
  final String? telegramId;
  final String? weChatId;

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
    this.hasWeChat = false,
    this.signalId,
    this.telegramId,
    this.weChatId,
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
    bool? hasWeChat,
    String? signalId,
    String? telegramId,
    String? weChatId,
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
      hasWeChat: hasWeChat ?? this.hasWeChat,
      signalId: signalId ?? this.signalId,
      telegramId: telegramId ?? this.telegramId,
      weChatId: weChatId ?? this.weChatId,
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

  int get detailsMaxIndex {
    int count = 2;
    count += phones.length * 2;
    // Signal section shows if hasSignal AND we have either a specific
    // ID or at least one phone to fall back to.
    if (hasSignal && (signalId != null || phones.isNotEmpty)) count += 1;
    if (hasTelegram && (telegramId != null || phones.isNotEmpty)) count += 1;
    if (hasWeChat && (weChatId != null || phones.isNotEmpty)) count += 1;
    count += emails.length;
    count += addresses.length;
    if (birthday != null) count += 1;
    if (notes.isNotEmpty) count += 1;
    count += 1;
    return count - 1;
  }
}