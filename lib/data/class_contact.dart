import 'dart:typed_data';
import 'package:flutter/material.dart';

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

  /// The system-provided display name from Android's aggregated
  /// `DISPLAY_NAME_PRIMARY`. This is already locale-aware (CJK contacts
  /// come out family-name-first, Western contacts come out
  /// given-name-first) because AOSP's `NameSplitter` composes it.
  final String name;

  /// Structured name parts, if the contact has them. Used by [nameFor]
  /// to compose a custom display order when the user enables the
  /// surname-first setting. Null for contacts that only have a display
  /// name (some vCard 2.1 sources, Exchange imports, etc.).
  final String? familyName;
  final String? givenName;

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

  final String? signalId;
  final String? telegramId;
  final String? weChatId;

  final List<String> websites;

  final Color? accentColor;

  const Contact({
    required this.id,
    required this.name,
    this.familyName,
    this.givenName,
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
    this.websites = const [],
    this.accentColor,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? familyName,
    String? givenName,
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
    List<String>? websites,
    Color? accentColor,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      familyName: familyName ?? this.familyName,
      givenName: givenName ?? this.givenName,
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
      websites: websites ?? this.websites,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  /// The display name for this contact, honouring the surname-first
  /// setting.
  ///
  /// When [surnameFirst] is false, returns the system-provided [name]
  /// verbatim — Android already composes it in the correct order for
  /// the contact's script.
  ///
  /// When [surnameFirst] is true, composes a new string from
  /// [familyName] and [givenName]. If both are empty, falls back to
  /// [name]. Format is script-aware:
  ///   - Both parts CJK (e.g. 張 / 三) → `張三` (no separator)
  ///   - One part CJK, the other not → `張 三` (space)
  ///   - Neither CJK → `Smith, John` (comma + space)
  String nameFor(bool surnameFirst) {
    if (!surnameFirst) return name;

    final family = (familyName ?? '').trim();
    final given = (givenName ?? '').trim();

    if (family.isEmpty && given.isEmpty) return name;
    if (family.isEmpty) return given;
    if (given.isEmpty) return family;

    final familyIsCJK = _containsCJK(family);
    final givenIsCJK = _containsCJK(given);

    if (familyIsCJK && givenIsCJK) {
      // e.g. 張 + 三 → 張三
      return '$family$given';
    }
    if (familyIsCJK || givenIsCJK) {
      // Mixed script — space-separate so the two don't visually glue.
      return '$family $given';
    }
    // Non-CJK — comma format (Western academic style).
    return '$family, $given';
  }

  /// True if [s] contains any character from a CJK script. Checks
  /// Unified Ideographs, Extension A, Hangul, Hiragana/Katakana, and
  /// Bopomofo. Single Hanzi is enough to trigger.
  static bool _containsCJK(String s) {
    for (final r in s.runes) {
      if ((r >= 0x4E00 && r <= 0x9FFF) ||   // CJK Unified Ideographs
          (r >= 0x3400 && r <= 0x4DBF) ||   // CJK Extension A
          (r >= 0xAC00 && r <= 0xD7AF) ||   // Hangul Syllables
          (r >= 0x3040 && r <= 0x30FF) ||   // Hiragana / Katakana
          (r >= 0x3100 && r <= 0x312F)) {   // Bopomofo
        return true;
      }
    }
    return false;
  }

  String displayTitle(bool prioritizeNicknames, bool surnameFirst) {
    final n = nameFor(surnameFirst);
    if (prioritizeNicknames) {
      return (nickname != null && nickname!.isNotEmpty) ? nickname! : n;
    }
    return n;
  }

  String displaySubtitle(bool prioritizeNicknames, bool surnameFirst) {
    final n = nameFor(surnameFirst);
    final hasNickname =
        nickname != null && nickname!.isNotEmpty && nickname != n;
    if (prioritizeNicknames) {
      return hasNickname ? n : status;
    }
    return hasNickname ? nickname! : status;
  }

  String detailsTitle(bool surnameFirst) {
    final n = nameFor(surnameFirst);
    if (nickname != null && nickname!.isNotEmpty && nickname != n) {
      return '$n ($nickname)';
    }
    return n;
  }

  bool get isBirthdayToday {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month && birthday!.day == now.day;
  }

  int get detailsMaxIndex {
    int count = 2;
    count += phones.length * 2;
    if (hasSignal && (signalId != null || phones.isNotEmpty)) count += 1;
    if (hasTelegram && (telegramId != null || phones.isNotEmpty)) count += 1;
    if (hasWeChat && (weChatId != null || phones.isNotEmpty)) count += 1;
    count += emails.length;
    count += addresses.length;
    count += websites.length;
    if (birthday != null) count += 1;
    if (notes.isNotEmpty) count += 1;
    count += 1;
    return count - 1;
  }
}