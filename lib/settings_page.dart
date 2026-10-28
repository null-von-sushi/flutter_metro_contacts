import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'other/accent_color.dart';
import 'transitions/wp_phone_transition.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _prioritizeNicknames = false;
  bool _parseNotesForAccentColor = false;

  @override
  Widget build(BuildContext context) {
    // Wrap the whole scaffold in a FeatherLayer so the black background
    // rotates in along with the toggles (instead of flashing instantly).
    return FeatherLayer(
      index: 0,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: WpToggleSwitch(
                  header: 'Prioritize Nicknames instead of legal names',
                  value: _prioritizeNicknames,
                  accentColor: AccentColor,
                  onChanged: (value) =>
                      setState(() => _prioritizeNicknames = value),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: WpToggleSwitch(
                  header: 'Parse Notes for Accent Color',
                  accentColor: AccentColor,
                  value: _parseNotesForAccentColor,
                  onChanged: (value) =>
                      setState(() => _parseNotesForAccentColor = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}