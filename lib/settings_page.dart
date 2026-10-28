import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onPopStart;
  const SettingsPage({super.key, this.onPopStart});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _prioritizeNicknames = false;
  bool _parseNotesForAccentColor = false;

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
        // Transparent so PeoplePage shows through during the transition.
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Opaque background fades in over the first 40% of the route
            // animation (~300ms at default speed), so PeoplePage's exit
            // rotation is visible underneath before black covers it.
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
            // Content with per-element stagger.
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
                      padding:
                      const EdgeInsets.symmetric(vertical: 16.0),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            child: WpToggleSwitch(
                              header: 'Parse Notes for Accent Color',
                              accentColor: AccentColor,
                              value: _parseNotesForAccentColor,
                              onChanged: (v) => setState(
                                      () => _parseNotesForAccentColor = v),
                            ),
                          ),
                        ),
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