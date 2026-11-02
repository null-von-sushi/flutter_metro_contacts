import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'package:url_launcher/url_launcher.dart';
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';
import 'widgets/bottom_app_bar.dart';
import 'widgets/wp_button.dart';
import 'other/wp_text.dart';

class ContactDetailsPage extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onPopStart;

  const ContactDetailsPage({
    super.key,
    required this.contact,
    this.onPopStart,
  });

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  Uint8List? _fullPhoto;

  @override
  void initState() {
    super.initState();
    _loadFullPhoto();
  }

  Future<void> _loadFullPhoto() async {
    try {
      final full = await FlutterContacts.get(
        widget.contact.id,
        properties: {ContactProperty.photoFullRes},
      );
      final bytes = full?.photo?.fullSize;
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() => _fullPhoto = bytes);
      }
    } catch (_) {}
  }

  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop();
  }

  // ── Launch helpers ────────────────────────────────────────────────

  Future<void> _launchUri(Uri uri, String failureMessage) async {
    HapticFeedback.lightImpact();
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showError(failureMessage);
    } catch (_) {
      _showError(failureMessage);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1F1F),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _internationalise(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return '';
    return cleaned.startsWith('+') ? cleaned : '+$cleaned';
  }

  void _callNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      _showError('No number to call');
      return;
    }
    _launchUri(Uri(scheme: 'tel', path: cleaned), 'No dialer app found');
  }

  void _sendSms(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      _showError('No number to message');
      return;
    }
    _launchUri(Uri(scheme: 'sms', path: cleaned), 'No messaging app found');
  }

  Future<void> _copyAndOpenWeChat(String number) async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: number));
    // Open WeChat to its main screen. If not installed, do nothing extra.
    try {
      await launchUrl(Uri.parse('weixin://'), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1F1F),
        content: const Text(
          'copied — paste in WeChat search',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendEmail(String address) {
    _launchUri(Uri(scheme: 'mailto', path: address), 'No email app found');
  }

  Future<void> _openAddress(String address) async {
    HapticFeedback.lightImpact();
    final encoded = Uri.encodeComponent(address);
    final geoUri = Uri.parse('geo:0,0?q=$encoded');
    try {
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    final fallback = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    try {
      if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    _showError('No maps app found');
  }

  void _openTelegram(String number) {
    final target = _internationalise(number);
    if (target.isEmpty) {
      _showError('No Telegram number');
      return;
    }
    _launchUri(
      Uri.parse('tg://resolve?phone=$target'),
      'Telegram not installed',
    );
  }

  void _openSignal(String number) {
    final target = _internationalise(number);
    if (target.isEmpty) {
      _showError('No Signal number');
      return;
    }
    _launchUri(
      Uri.parse('https://signal.me/#p/$target'),
      'Signal not installed',
    );
  }

  // ── Existing dialogs ──────────────────────────────────────────────

  void _handleEdit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Edit Contact'),
        content: const Text('Edit form will go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save', style: TextStyle(color: AccentColor)),
          ),
        ],
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete ${widget.contact.name}?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WpButton(
                    label: 'cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  WpButton(
                    label: 'delete',
                    pressedColor: Colors.red.shade700,
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: call FlutterContacts.delete(widget.contact.id).
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBirthday(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final month = months[date.month - 1];
    if (date.year < 1900) {
      return '${date.day} $month';
    }
    return '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final maxIndex = c.detailsMaxIndex;
    final isBirthdayToday = c.isBirthdayToday;

    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);

    int next = 2;
    int assign() {
      final i = next;
      if (next < maxIndex) next++;
      return i;
    }

    final infoSections = <Widget>[];

    // Phones: two sections each, "Call X" and "Text X".
    for (final p in c.phones) {
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Call ${p.header} number',
          value: p.number,
          onTap: () => _callNumber(p.number),
        ),
      ));
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Text ${p.header} number',
          value: p.number,
          onTap: () => _sendSms(p.number),
        ),
      ));
    }

    // Signal: one section per contact, using the primary number.
    if (c.hasSignal && c.phones.isNotEmpty) {
      final primary = c.phones.first.number;
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Contact via Signal',
          value: primary,
          onTap: () => _openSignal(primary),
        ),
      ));
    }

    // Telegram: same pattern.
    if (c.hasTelegram && c.phones.isNotEmpty) {
      final primary = c.phones.first.number;
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Contact via Telegram',
          value: primary,
          onTap: () => _openTelegram(primary),
        ),
      ));
    }

    // wechat, nothing we can do because it's cancer
    // for now copy-on-tap because there's no
    // reliable deep link for opening a chat with a specific number...
    if (c.hasWeChat && c.phones.isNotEmpty) {
      final primary = c.phones.first.number;
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Copy WeChat number',
          value: primary,
          onTap: () => _copyAndOpenWeChat(primary),
        ),
      ));
    }

    // Emails: "Email" if unlabeled, "Email Home"/"Email Work" otherwise.
    for (final e in c.emails) {
      final header = e.header == 'Email' ? 'Email' : 'Email ${e.header}';
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: header,
          value: e.address,
          onTap: () => _sendEmail(e.address),
        ),
      ));
    }

    // Addresses: "Show on Map" if unlabeled, "Show Home on Map" otherwise.
    for (final a in c.addresses) {
      final header = a.header == 'Address'
          ? 'Show on Map'
          : 'Show ${a.header} on Map';
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: header,
          value: a.formatted,
          onTap: () => _openAddress(a.formatted),
        ),
      ));
    }

    if (c.birthday != null) {
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Birthday',
          value: _formatBirthday(c.birthday!),
        ),
      ));
    }

    if (c.notes.isNotEmpty) {
      infoSections.add(FeatherLayer(
        index: assign(),
        child: _InfoSection(
          header: 'Notes',
          value: c.notes.join('\n\n'),
        ),
      ));
    }

    final bottomBarIndex = assign();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  final t = (anim.value / 0.4).clamp(0.0, 1.0);
                  return ColoredBox(
                    color: Colors.black.withOpacity(t),
                  );
                },
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeatherLayer(
                    index: 0,
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONTACT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  c.detailsTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isBirthdayToday) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.cake_outlined,
                                  color: AccentColor,
                                  size: 26,
                                  semanticLabel: 'Birthday today',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  FeatherLayer(
                    index: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _ProfilePhoto(
                        name: c.name,
                        photo: _fullPhoto ?? c.photo,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: infoSections,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: FeatherLayer(
          index: bottomBarIndex,
          child: WpBottomAppBar(
            actions: [
              WpApplicationBarAction(
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: 'edit',
                onPressed: _handleEdit,
              ),
            ],
            menuItems: [
              WpApplicationBarMenuItem(
                label: 'delete',
                onPressed: _handleDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final String name;
  final Uint8List? photo;

  const _ProfilePhoto({required this.name, required this.photo});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 160,
        height: 160,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: AccentColor),
        child: photo != null
            ? Image.memory(
          photo!,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          cacheWidth: 480,
          cacheHeight: 480,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        )
            : Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A section with a header (verb + type) and a single value underneath.
class _InfoSection extends StatelessWidget {
  final String header;
  final String value;
  final VoidCallback? onTap;

  const _InfoSection({
    required this.header,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          wpLowercase(header), // ← single point of application,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 0),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: AccentColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.white.withOpacity(0.06),
      child: content,
    );
  }
}