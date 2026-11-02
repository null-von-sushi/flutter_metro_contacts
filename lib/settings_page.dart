import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'package:wp_pivot_flutter/wp_components.dart';
import 'data/contact_repository.dart';
import 'data/group_query.dart';
import 'other/accent_color.dart';
import 'other/constants.dart';
import 'other/settings.dart';
import 'transitions/wp_phone_transition.dart';
import 'widgets/wp_button.dart';

const _packageCheckChannel = MethodChannel(
  'com.example.flutter_metro_contacts/package_check',
);

const _metroVNavbarPackage = 'com.tuzkituan.metrov.navbar';
const _metroVLauncherPackage = 'com.tuzkituan.metrov';

const _barBackgroundHex = '#1F1F1F';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onPopStart;
  final Settings settings;

  const SettingsPage({
    super.key,
    this.onPopStart,
    required this.settings,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _metroVNavbarInstalled;
  bool? _metroVLauncherInstalled;

  String? _accountDisplayName;
  String? _groupDisplayName;

  @override
  void initState() {
    super.initState();
    _checkMetroVNavbarInstalled();
    _checkMetroVLauncherInstalled();
    _refreshFilterDisplayNames();
    widget.settings.accountFilter.addListener(_refreshFilterDisplayNames);
    widget.settings.groupFilter.addListener(_refreshFilterDisplayNames);
  }

  @override
  void dispose() {
    widget.settings.accountFilter.removeListener(_refreshFilterDisplayNames);
    widget.settings.groupFilter.removeListener(_refreshFilterDisplayNames);
    super.dispose();
  }

  Future<void> _refreshFilterDisplayNames() async {
    final accountId = widget.settings.accountFilter.value;
    final groupId = widget.settings.groupFilter.value;

    String? accountName;
    String? groupName;

    if (accountId != null) {
      try {
        final accounts = await FlutterContacts.accounts.getAll();
        for (final raw in accounts) {
          final a = raw as Account?;
          if (a == null) continue;
          if (ContactRepository.accountKey(a) == accountId) {
            accountName = (a.name?.isNotEmpty ?? false)
                ? a.name!
                : (a.type ?? accountId);
            break;
          }
        }
      } catch (_) {}
    }

    if (groupId != null) {
      try {
        final groups = await GroupQuery.fetchAll();
        for (final g in groups) {
          if (g.id == groupId) {
            groupName = g.title;
            break;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _accountDisplayName = accountName;
      _groupDisplayName = groupName;
    });
  }

  Future<void> _checkMetroVNavbarInstalled() async {
    try {
      final installed = await _packageCheckChannel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': _metroVNavbarPackage},
      );
      if (mounted) {
        setState(() => _metroVNavbarInstalled = installed ?? false);
      }
    } catch (_) {
      if (mounted) setState(() => _metroVNavbarInstalled = false);
    }
  }

  Future<void> _checkMetroVLauncherInstalled() async {
    try {
      final installed = await _packageCheckChannel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': _metroVLauncherPackage},
      );
      if (mounted) {
        setState(() => _metroVLauncherInstalled = installed ?? false);
      }
    } catch (_) {
      if (mounted) setState(() => _metroVLauncherInstalled = false);
    }
  }

  Future<void> _copyBarColorHex() async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(const ClipboardData(text: _barBackgroundHex));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1F1F1F),
        content: Text(
          'copied — paste into MetroV Navbar settings',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleBack() {
    widget.onPopStart?.call();
    Navigator.of(context).pop();
  }

  // ── Account picker ──────────────────────────────────────────────────

  Future<void> _pickAccount() async {
    final accounts = await _loadAccounts();
    if (!mounted) return;

    final selected = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ChoiceDialog<String>(
        title: 'Account',
        options: [
          const _ChoiceOption<String>(
              id: '__all__', label: 'all accounts', subtitle: ''),
          for (final raw in accounts)
            if (raw != null)
              _ChoiceOption<String>(
                id: ContactRepository.accountKey(raw),
                label: (raw.name?.isNotEmpty ?? false)
                    ? raw.name!
                    : (raw.type ?? 'unknown'),
                subtitle: raw.type ?? '',
              ),
        ],
        currentId: widget.settings.accountFilter.value ?? '__all__',
      ),
    );

    if (!mounted || selected == null) return;

    if (selected == '__all__') {
      widget.settings.accountFilter.value = null;
      widget.settings.groupFilter.value = null;
    } else {
      widget.settings.accountFilter.value = selected;
      widget.settings.groupFilter.value = null;
    }
  }

  // ── Group picker ────────────────────────────────────────────────────

  Future<void> _pickGroup() async {
    final accountKey = widget.settings.accountFilter.value;
    if (accountKey == null) {
      _showSnack('Pick an account first');
      return;
    }
    final groups = await _loadGroups(accountKey);
    if (!mounted) return;

    if (groups.isEmpty) {
      _showSnack('No groups found on this device');
      return;
    }

    final selected = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ChoiceDialog<String>(
        title: 'Group',
        options: [
          const _ChoiceOption<String>(
              id: '__all__', label: 'all groups in account', subtitle: ''),
          for (final g in groups)
            _ChoiceOption<String>(id: g.id, label: g.title),
        ],
        currentId: widget.settings.groupFilter.value ?? '__all__',
      ),
    );

    if (!mounted || selected == null) return;

    widget.settings.groupFilter.value =
    selected == '__all__' ? null : selected;
  }

  // ── Accent color picker ─────────────────────────────────────────────

  Future<void> _pickAccentColor() async {
    final currentArgb = widget.settings.selectedAccentArgb.value;
    final selected = await showDialog<int?>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ChoiceDialog<int>(
        title: 'Accent colour',
        options: [
          for (final entry in wpAccentPalette.entries)
            _ChoiceOption<int>(
              id: entry.value,
              label: entry.key,
              swatch: Color(entry.value),
            ),
        ],
        currentId: currentArgb,
      ),
    );
    if (!mounted || selected == null) return;
    widget.settings.selectedAccentArgb.value = selected;
  }

  Future<List<Account?>> _loadAccounts() async {
    try {
      final list = await FlutterContacts.accounts.getAll();
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<List<NativeGroup>> _loadGroups(String accountKey) async {
    final all = await GroupQuery.fetchAll();
    if (all.isEmpty) return const [];
    final filtered = all.where((g) => g.accountKey == accountKey).toList();
    return filtered.isNotEmpty ? filtered : all;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1F1F),
        content: Text(message,
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);

    final accountLabel = widget.settings.accountFilter.value == null
        ? 'all accounts'
        : (_accountDisplayName ?? widget.settings.accountFilter.value!);
    final groupLabel = widget.settings.groupFilter.value == null
        ? 'all groups'
        : (_groupDisplayName ?? widget.settings.groupFilter.value!);
    final selectedArgb = widget.settings.selectedAccentArgb.value;
    final accentName = wpAccentPalette.entries
        .firstWhere(
          (e) => e.value == selectedArgb,
      orElse: () => MapEntry(
        'custom (#${selectedArgb.toRadixString(16).padLeft(8, '0').toUpperCase()})',
        selectedArgb,
      ),
    )
        .key;

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
                children: [
                  FeatherLayer(
                    index: 0,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: _handleBack,
                          ),
                          const Text(
                            'settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      children: [
                        // ── SHOWING ─────────────────────────────────
                        const FeatherLayer(
                          index: 1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'SHOWING',
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
                          index: 2,
                          child: _FilterRow(
                            label: 'account',
                            value: accountLabel,
                            onTap: _pickAccount,
                          ),
                        ),
                        FeatherLayer(
                          index: 3,
                          child: _FilterRow(
                            label: 'group',
                            value: groupLabel,
                            onTap: widget.settings.accountFilter.value != null
                                ? _pickGroup
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── CONTACT DISPLAY ─────────────────────────
                        const FeatherLayer(
                          index: 4,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'CONTACT DISPLAY',
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
                          index: 5,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ValueListenableBuilder<bool>(
                              valueListenable:
                              widget.settings.prioritizeNicknames,
                              builder: (context, value, _) => WpToggleSwitch(
                                header:
                                'Prioritize Nicknames instead of legal names',
                                value: value,
                                accentColor: AccentColor,
                                onChanged: (v) =>
                                widget.settings.prioritizeNicknames.value =
                                    v,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── THEMING ─────────────────────────────────
                        const FeatherLayer(
                          index: 6,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'THEMING',
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
                          index: 7,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ValueListenableBuilder<bool>(
                              valueListenable:
                              widget.settings.parseNotesForAccentColor,
                              builder: (context, value, _) => WpToggleSwitch(
                                header: 'Parse Notes for Accent Color',
                                accentColor: AccentColor,
                                value: value,
                                onChanged: (v) => widget
                                    .settings.parseNotesForAccentColor.value = v,
                              ),
                            ),
                          ),
                        ),
                        // Accent colour row — tap to pick from the WP palette.
                        FeatherLayer(
                          index: 8,
                          child: _FilterRow(
                            label: 'accent colour',
                            value: accentName,
                            leadingSwatch: Color(selectedArgb),
                            onTap: _pickAccentColor,
                          ),
                        ),
                        // Use launcher accent — only when MetroV launcher
                        // is installed.
                        if (_metroVLauncherInstalled == true)
                          FeatherLayer(
                            index: 9,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: ValueListenableBuilder<bool>(
                                valueListenable:
                                widget.settings.useLauncherAccent,
                                builder: (context, value, _) => WpToggleSwitch(
                                  header: 'Use MetroV launcher accent',
                                  value: value,
                                  accentColor: AccentColor,
                                  onChanged: (v) => widget
                                      .settings.useLauncherAccent.value = v,
                                ),
                              ),
                            ),
                          ),
                        if (_metroVNavbarInstalled == true) ...[
                          const SizedBox(height: 24),
                          FeatherLayer(
                            index: 10,
                            child: InkWell(
                              onTap: _copyBarColorHex,
                              splashFactory: NoSplash.splashFactory,
                              highlightColor:
                              Colors.white.withOpacity(0.06),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  'MetroV Navbar detected. To make its bar '
                                      'match this app\'s, set its background '
                                      'color to #1F1F1F (tap to copy).',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white38,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? leadingSwatch;

  const _FilterRow({
    required this.label,
    required this.value,
    this.onTap,
    this.leadingSwatch,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.white.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            SizedBox(
              width: 116,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white54,
                ),
              ),
            ),
            if (leadingSwatch != null) ...[
              Container(
                width: 16,
                height: 16,
                color: leadingSwatch,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w300,
                  color: enabled ? Colors.white : Colors.white30,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled ? Colors.white38 : Colors.white12,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceOption<T> {
  final T id;
  final String label;
  final String subtitle;
  final Color? swatch;

  const _ChoiceOption({
    required this.id,
    required this.label,
    this.subtitle = '',
    this.swatch,
  });
}

class _ChoiceDialog<T> extends StatelessWidget {
  final String title;
  final List<_ChoiceOption<T>> options;
  final T currentId;

  const _ChoiceDialog({
    required this.title,
    required this.options,
    required this.currentId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final selected = opt.id == currentId;
                return InkWell(
                  onTap: () => Navigator.pop<T>(context, opt.id),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.white.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: selected ? AccentColor : Colors.white38,
                        ),
                        const SizedBox(width: 12),
                        if (opt.swatch != null) ...[
                          Container(
                            width: 20,
                            height: 20,
                            color: opt.swatch,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              if (opt.subtitle.isNotEmpty)
                                Text(
                                  opt.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WpButton(
                  label: 'cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}