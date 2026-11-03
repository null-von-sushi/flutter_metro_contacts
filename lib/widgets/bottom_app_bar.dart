import 'package:flutter/material.dart';

// Re-export the types callers need so pages only import this file.
import 'custom_app_bar.dart';
export 'custom_app_bar.dart' show WpApplicationBarAction, WpApplicationBarMenuItem, WpApplicationBarMode;

/// WP-themed bottom application bar.
///
/// Renders [WpApplicationBar] with the WP8.1 default chrome: dark
/// background, extra padding below the content to clear the Android
/// gesture-navigation pill, and the standard 72px `defaultMode` height.
///
/// Pages supply their own [actions] and [menuItems]; this widget only
/// owns the visual wrapper.
class WpBottomAppBar extends StatelessWidget {
  final List<WpApplicationBarAction> actions;
  final List<WpApplicationBarMenuItem> menuItems;

  const WpBottomAppBar({
    super.key,
    this.actions = const [],
    this.menuItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    // System inset for gesture pill / navigation bar (0 on 3-button nav).
    final systemInset = MediaQuery.of(context).padding.bottom;
    // Negative value pulls the bar up so its visual height matches MetroV's.
    final extraPadding = systemInset > 0 ? -9.0 : 0.0;

    return Container(
      // Match WpApplicationBar's own background to avoid a visible seam.
      color: const Color(0xff1f1f1f),
      padding: EdgeInsets.only(bottom: systemInset + extraPadding),
      child: WpApplicationBar(
        mode: WpApplicationBarMode.defaultMode,
        actions: actions,
        menuItems: menuItems,
      ),
    );
  }
}