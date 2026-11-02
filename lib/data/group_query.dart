import 'package:flutter/services.dart';

/// A lightweight group descriptor returned by the native query.
/// We don't reuse flutter_contacts' `Group` class because we're
/// bypassing its API entirely.
class NativeGroup {
  final String id;
  final String title;
  final String accountType;
  final String accountName;

  const NativeGroup({
    required this.id,
    required this.title,
    required this.accountType,
    required this.accountName,
  });

  /// Composite account key matching `ContactRepository.accountKey`:
  /// `type|name`.
  String get accountKey => '$accountType|$accountName';
}

/// MethodChannel wrapper for querying Android's ContactsContract.Groups
/// table directly. This exists because `flutter_contacts.groups.getAll()`
/// returns an empty list on some devices and account types.
class GroupQuery {
  static const _channel = MethodChannel(
    'com.example.flutter_metro_contacts/groups',
  );

  static Future<List<NativeGroup>> fetchAll() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getGroups');
      if (raw == null) return const [];
      return raw
          .whereType<Map>()
          .map((m) => NativeGroup(
        id: (m['id'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        accountType: (m['accountType'] as String?) ?? '',
        accountName: (m['accountName'] as String?) ?? '',
      ))
          .where((g) => g.id.isNotEmpty && g.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}