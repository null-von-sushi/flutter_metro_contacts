import 'dart:typed_data';

/// Data model for a contact, including a photo, nickname, and "Me" flag.
class Contact {
  final String id;
  final String name;
  final String? nickname;
  final String status;
  final Uint8List? photo;
  final bool isMe;

  const Contact({
    required this.id,
    required this.name,
    this.nickname,
    required this.status,
    this.photo,
    this.isMe = false,
  });

  String get displayTitle =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  String get displaySubtitle {
    if (nickname != null && nickname!.isNotEmpty && nickname != name) {
      return name;
    }
    return status;
  }
}