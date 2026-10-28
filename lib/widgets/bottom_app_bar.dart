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
    return WpApplicationBar(
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
    );
  }
}