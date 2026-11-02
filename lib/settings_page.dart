import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';

/// MethodChannel used to ask Android whether a given package is installed.
/// Must match the channel name declared in MainActivity.kt.
const _packageCheckChannel = MethodChannel(
  'com.example.flutter_metro_contacts/package_check',
);

/// Package ID of MetroV Navbar. If installed, we surface a note telling
/// the user to match its background color to ours.
const _metroVPackage = 'com.tuzkituan.metrov.navbar';

/// Background color of the bottom app bar and everything that should
/// visually align with it.
const _barBackgroundHex = '#1F1F1F';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onPopStart;
  const SettingsPage({super.key, this.onPopStart});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _prioritizeNicknames = false;
  bool _parseNotesForAccentColor = false;

  /// null while the check is in flight, true/false once resolved.
  /// The note is hidden while null so it doesn't flash in and out.
  bool? _metroVInstalled;

  @override
  void initState() {
    super.initState();
    _checkMetroVInstalled();
  }

  Future<void> _checkMetroVInstalled() async {
    try {
      final installed = await _packageCheckChannel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': _metroVPackage},
      );
      if (mounted) setState(() => _metroVInstalled = installed ?? false);
    } catch (_) {
      if (mounted) setState(() => _metroVInstalled = false);
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

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);

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
                        const FeatherLayer(
                          index: 1,
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
                          index: 2,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                            child: WpToggleSwitch(
                              header:
                              'Prioritize Nicknames instead of legal names',
                              value: _prioritizeNicknames,
                              accentColor: AccentColor,
                              onChanged: (v) => setState(
                                      () => _prioritizeNicknames = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const FeatherLayer(
                          index: 3,
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
                          index: 4,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                            child: WpToggleSwitch(
                              header: 'Parse Notes for Accent Color',
                              accentColor: AccentColor,
                              value: _parseNotesForAccentColor,
                              onChanged: (v) => setState(
                                      () => _parseNotesForAccentColor = v),
                            ),
                          ),
                        ),
                        if (_metroVInstalled == true) ...[
                          const SizedBox(height: 24),
                          FeatherLayer(
                            index: 5,
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