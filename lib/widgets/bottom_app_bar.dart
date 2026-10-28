import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

class PeopleBottomBar extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onSettings;

  const PeopleBottomBar({
    super.key,
    required this.onAdd,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    // System inset for gesture pill / navigation bar (0 on 3-button nav).
    final systemInset = MediaQuery.of(context).padding.bottom;
    // Extra breathing room on top of the system inset. Tune to taste.
    const extraPadding = -9.0; //to allign with MetroV's height

    return Container(
      // Must match the bar's own background color to avoid a visible seam.
      // WpApplicationBar defaults to 0xff1f1f1f; if you've overridden it
      // in the WpApplicationBar constructor, use that color here instead.
      color: const Color(0xff1f1f1f),
      padding: EdgeInsets.only(bottom: systemInset + extraPadding),
      child: WpApplicationBar(
        mode: WpApplicationBarMode.defaultMode,
        actions: [
          WpApplicationBarAction(
            icon: const Icon(Icons.add, size: 20),
            label: 'add',
            onPressed: onAdd,
          ),
        ],
        menuItems: [
          WpApplicationBarMenuItem(
            label: 'settings',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}