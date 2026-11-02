import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'data/class_contact.dart';
import 'other/accent_color.dart';
import 'other/settings.dart';
import 'other/wp_text.dart';
import 'transitions/wp_phone_transition.dart';
import 'widgets/bottom_app_bar.dart';
import 'widgets/wp_button.dart';

class ContactEditPage extends StatefulWidget {
  /// `null` for new-contact mode; otherwise the contact being edited.
  final Contact? contact;
  final Settings settings;
  final VoidCallback? onPopStart;

  /// Fires after a successful save. The caller is expected to refresh
  /// whatever list/detail view it pushed us from.
  final VoidCallback? onSaved;

  const ContactEditPage({
    super.key,
    this.contact,
    required this.settings,
    this.onPopStart,
    this.onSaved,
  });

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  fc.Contact? _rawContact;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  final _displayNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  List<fc.Phone> _phones = [];
  List<fc.Email> _emails = [];
  List<fc.Website> _websites = [];
  List<fc.Note> _notes = [];

  bool get _isEdit => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final raw = await fc.FlutterContacts.get(
        widget.contact!.id,
        properties: {
          fc.ContactProperty.name,
          fc.ContactProperty.photoThumbnail,
          fc.ContactProperty.phone,
          fc.ContactProperty.email,
          fc.ContactProperty.website,
          fc.ContactProperty.note,
          fc.ContactProperty.identifiers,
        },
      );
      if (!mounted) return;
      if (raw == null) {
        setState(() {
          _loading = false;
          _loadError = 'Contact not found';
        });
        return;
      }
      setState(() {
        _rawContact = raw;
        _displayNameCtrl.text = raw.displayName ?? '';
        _nicknameCtrl.text = raw.name?.nickname ?? '';
        _firstCtrl.text = raw.name?.first ?? '';
        _middleCtrl.text = raw.name?.middle ?? '';
        _lastCtrl.text = raw.name?.last ?? '';
        _phones = List.of(raw.phones);
        _emails = List.of(raw.emails);
        _websites = List.of(raw.websites);
        _notes = List.of(raw.notes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final middle = _middleCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final display = _displayNameCtrl.text.trim();

    if (first.isEmpty && last.isEmpty && display.isEmpty) {
      _showSnack('Enter a display name or a first/last name');
      return;
    }

    setState(() => _saving = true);

    try {
      final name = fc.Name(
        first: first.isEmpty ? null : first,
        middle: middle.isEmpty ? null : middle,
        last: last.isEmpty ? null : last,
        nickname: nickname.isEmpty ? null : nickname,
      );

      if (_isEdit) {
        final updated = _rawContact!.copyWith(
          name: name,
          phones: _phones,
          emails: _emails,
          websites: _websites,
          notes: _notes,
        );
        await fc.FlutterContacts.update(updated);
      } else {
        final newContact = fc.Contact(
          name: name,
          phones: _phones,
          emails: _emails,
          websites: _websites,
          notes: _notes,
        );
        await fc.FlutterContacts.create(newContact);
      }

      if (!mounted) return;
      widget.onSaved?.call();
      widget.onPopStart?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Save failed: $e');
    }
  }

  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1F1F),
        content: Text(message,
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addPhone() async {
    final p = await showDialog<fc.Phone>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _AddPhoneDialog(),
    );
    if (p != null) setState(() => _phones.add(p));
  }

  Future<void> _addEmail() async {
    final e = await showDialog<fc.Email>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _AddEmailDialog(),
    );
    if (e != null) setState(() => _emails.add(e));
  }

  Future<void> _addWebsite() async {
    final url = await showDialog<String>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _AddTextDialog(
        title: 'Add website',
        hint: 'https://example.com',
      ),
    );
    if (url != null && url.isNotEmpty) {
      setState(() => _websites.add(fc.Website(url: url)));
    }
  }

  Future<void> _addNote() async {
    final text = await showDialog<String>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _AddTextDialog(
        title: 'Add note',
        hint: '',
        multiline: true,
      ),
    );
    if (text != null && text.isNotEmpty) {
      setState(() => _notes.add(fc.Note(note: text)));
    }
  }

  Future<void> _confirmRemove({
    required String label,
    required VoidCallback onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ConfirmRemoveDialog(label: label),
    );
    if (ok == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);
    final accent = AccentColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_saving) return;
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
                  return ColoredBox(color: Colors.black.withOpacity(t));
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _isEdit ? 'EDIT CONTACT' : 'NEW CONTACT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  FeatherLayer(
                    index: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _PhotoPlaceholder(
                        photo: _rawContact?.photo?.thumbnail,
                        accent: accent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FeatherLayer(
                      index: 2,
                      child: _loading
                          ? const Center(
                        child: SizedBox(
                          width: 200,
                          height: 4,
                          child: LinearProgressIndicator(
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      )
                          : _loadError != null
                          ? Center(
                        child: Text(
                          'Error: $_loadError',
                          style: const TextStyle(
                              color: Colors.white70),
                        ),
                      )
                          : ListView(
                        padding:
                        const EdgeInsets.only(bottom: 32),
                        children: _buildForm(accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: FeatherLayer(
          index: 3,
          child: WpBottomAppBar(
            actions: [
              WpApplicationBarAction(
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check, size: 20),
                label: 'save',
                onPressed: _saving ? null : _save,
              ),
            ],
            menuItems: [
              WpApplicationBarMenuItem(
                label: 'cancel',
                onPressed: _saving ? null : _handleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm(Color accent) {
    final sections = <Widget>[
      _buildTextField('Display Name', _displayNameCtrl),
      _buildTextField('Nickname', _nicknameCtrl),
      _buildTextField('First Name', _firstCtrl),
      _buildTextField('Middle Name', _middleCtrl),
      _buildTextField('Surname', _lastCtrl),
    ];

    for (var i = 0; i < _phones.length; i++) {
      final p = _phones[i];
      sections.add(_InfoSection(
        header: 'phone (${_labelName(p.label)})',
        value: p.number,
        accentColor: accent,
        onTap: () => _confirmRemove(
          label: p.number,
          onConfirm: () => setState(() => _phones.removeAt(i)),
        ),
      ));
    }
    sections.add(_AddButton(
      label: 'phone',
      onTap: _addPhone,
      accentColor: accent,
    ));

    for (var i = 0; i < _emails.length; i++) {
      final e = _emails[i];
      sections.add(_InfoSection(
        header: 'email (${_labelName(e.label)})',
        value: e.address,
        accentColor: accent,
        onTap: () => _confirmRemove(
          label: e.address,
          onConfirm: () => setState(() => _emails.removeAt(i)),
        ),
      ));
    }
    sections.add(_AddButton(
      label: 'email',
      onTap: _addEmail,
      accentColor: accent,
    ));

    for (var i = 0; i < _websites.length; i++) {
      final w = _websites[i];
      sections.add(_InfoSection(
        header: 'website',
        value: w.url,
        accentColor: accent,
        onTap: () => _confirmRemove(
          label: w.url,
          onConfirm: () => setState(() => _websites.removeAt(i)),
        ),
      ));
    }
    sections.add(_AddButton(
      label: 'website',
      onTap: _addWebsite,
      accentColor: accent,
    ));

    for (var i = 0; i < _notes.length; i++) {
      final n = _notes[i];
      sections.add(_InfoSection(
        header: 'note',
        value: n.note,
        accentColor: accent,
        onTap: () => _confirmRemove(
          label: 'this note',
          onConfirm: () => setState(() => _notes.removeAt(i)),
        ),
      ));
    }
    sections.add(_AddButton(
      label: 'note',
      onTap: _addNote,
      accentColor: accent,
    ));

    return sections;
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wpLowercase(label),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AccentColor, width: 2),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelName(dynamic label) {
    final s = label?.toString() ?? '';
    final parts = s.split('.');
    final name = parts.length > 1 ? parts.last : s;
    return name.isEmpty ? 'phone' : name;
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final Uint8List? photo;
  final Color accent;

  const _PhotoPlaceholder({required this.photo, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 160,
        height: 160,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(color: accent),
        child: photo != null
            ? Image.memory(
          photo!,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          cacheWidth: 480,
          cacheHeight: 480,
        )
            : null,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String header;
  final String value;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _InfoSection({
    required this.header,
    required this.value,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AccentColor;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wpLowercase(header),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            softWrap: true,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: accent,
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

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _AddButton({
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.white.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              wpLowercase(label),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhoneDialog extends StatefulWidget {
  const _AddPhoneDialog();

  @override
  State<_AddPhoneDialog> createState() => _AddPhoneDialogState();
}

class _AddPhoneDialogState extends State<_AddPhoneDialog> {
  final _ctrl = TextEditingController();
  fc.PhoneLabel _label = fc.PhoneLabel.mobile;

  static const _labels = [
    fc.PhoneLabel.mobile,
    fc.PhoneLabel.home,
    fc.PhoneLabel.work,
    fc.PhoneLabel.main,
    fc.PhoneLabel.other,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditDialogScaffold(
      title: 'Add phone',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in _labels)
                _TypeChip(
                  label: _enumName(l),
                  selected: _label == l,
                  onTap: () => setState(() => _label = l),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _ctrl,
            hint: 'Number',
            autofocus: true,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      onCancel: () => Navigator.of(context).pop(),
      onSave: () {
        final n = _ctrl.text.trim();
        if (n.isEmpty) return;
        Navigator.of(context).pop(
          fc.Phone(
            number: n,
            label: fc.Label<fc.PhoneLabel>(_label),
          ),
        );
      },
    );
  }
}

class _AddEmailDialog extends StatefulWidget {
  const _AddEmailDialog();

  @override
  State<_AddEmailDialog> createState() => _AddEmailDialogState();
}

class _AddEmailDialogState extends State<_AddEmailDialog> {
  final _ctrl = TextEditingController();
  fc.EmailLabel _label = fc.EmailLabel.home;

  static const _labels = [
    fc.EmailLabel.home,
    fc.EmailLabel.work,
    fc.EmailLabel.other,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditDialogScaffold(
      title: 'Add email',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in _labels)
                _TypeChip(
                  label: _enumName(l),
                  selected: _label == l,
                  onTap: () => setState(() => _label = l),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _ctrl,
            hint: 'Address',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      onCancel: () => Navigator.of(context).pop(),
      onSave: () {
        final a = _ctrl.text.trim();
        if (a.isEmpty) return;
        Navigator.of(context).pop(
          fc.Email(
            address: a,
            label: fc.Label<fc.EmailLabel>(_label),
          ),
        );
      },
    );
  }
}

class _AddTextDialog extends StatefulWidget {
  final String title;
  final String hint;
  final bool multiline;

  const _AddTextDialog({
    required this.title,
    required this.hint,
    this.multiline = false,
  });

  @override
  State<_AddTextDialog> createState() => _AddTextDialogState();
}

class _AddTextDialogState extends State<_AddTextDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditDialogScaffold(
      title: widget.title,
      content: _DialogTextField(
        controller: _ctrl,
        hint: widget.hint.isEmpty ? 'Value' : widget.hint,
        autofocus: true,
        multiline: widget.multiline,
      ),
      onCancel: () => Navigator.of(context).pop(),
      onSave: () {
        final v = _ctrl.text.trim();
        if (v.isEmpty) return;
        Navigator.of(context).pop(v);
      },
    );
  }
}

class _EditDialogScaffold extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditDialogScaffold({
    required this.title,
    required this.content,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WpButton(label: 'cancel', onPressed: onCancel),
                const SizedBox(width: 12),
                WpButton(label: 'save', onPressed: onSave),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AccentColor : Colors.transparent,
          border: Border.all(
            color: selected ? AccentColor : Colors.white38,
            width: 1.5,
          ),
        ),
        child: Text(
          wpLowercase(label),
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final bool multiline;
  final TextInputType? keyboardType;

  const _DialogTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.multiline = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: multiline ? null : 1,
      minLines: multiline ? 3 : 1,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AccentColor, width: 2),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}

class _ConfirmRemoveDialog extends StatelessWidget {
  final String label;

  const _ConfirmRemoveDialog({required this.label});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove "$label"?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WpButton(
                  label: 'cancel',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 12),
                WpButton(
                  label: 'remove',
                  pressedColor: Colors.red.shade700,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _enumName(dynamic e) {
  final s = e?.toString() ?? '';
  final parts = s.split('.');
  return parts.length > 1 ? parts.last : s;
}