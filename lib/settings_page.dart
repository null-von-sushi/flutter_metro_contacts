import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

// Use the same accent color as your main app
const Color wpAccentColor = Color(0xFFA20025);

// ---------------------------------------------------------------------------
// TurnstileFeather timing constants (from component_gallery_shell.dart)
// ---------------------------------------------------------------------------

/// Silverlight `ExponentialEase` used by WPtoolkit TurnstileFeather.
class WpToolkitExponentialEase extends Curve {
  const WpToolkitExponentialEase({this.exponent = 6, this.easeOut = true});
  final double exponent;
  final bool easeOut;

  @override
  double transformInternal(double t) {
    final easeIn = (math.exp(exponent * t) - 1) / (math.exp(exponent) - 1);
    return easeOut
        ? 1 - ((math.exp(exponent * (1 - t)) - 1) / (math.exp(exponent) - 1))
        : easeIn;
  }
}

/// Toolkit `TurnstileFeatherEffect` literals (WP8 DLL).
class WpTurnstileFeather {
  static const double centerOfRotationX = -0.2;
  static const int forwardInDurationMs = 350;
  static const double forwardInAngle = -80;
  static const int forwardInDelayMs = 40;
  static const int forwardOutDurationMs = 250;
  static const double forwardOutAngle = 50;
  static const int forwardOutDelayMs = 50;
  static const int backwardInDurationMs = 350;
  static const double backwardInAngle = 50;
  static const int backwardInDelayMs = 50;
  static const int backwardOutDurationMs = 250;
  static const double backwardOutAngle = -80;
  static const int backwardOutDelayMs = 40;

  static const int detailPageMaxIndex = 2;

  static int forwardOutPhaseMsFor(int maxIndex) =>
      forwardOutDurationMs + forwardOutDelayMs * maxIndex;
  static int forwardInPhaseMsFor(int maxIndex) =>
      forwardInDurationMs + forwardInDelayMs * maxIndex;
  static int backwardOutPhaseMsFor(int maxIndex) =>
      backwardOutDurationMs + backwardOutDelayMs * maxIndex;
  static int backwardInPhaseMsFor(int maxIndex) =>
      backwardInDurationMs + backwardInDelayMs * maxIndex;

  static int routeDurationMsFor({
    required int outgoingMaxIndex,
    required int incomingMaxIndex,
  }) =>
      forwardOutPhaseMsFor(outgoingMaxIndex) +
          forwardInPhaseMsFor(incomingMaxIndex);

  static int reverseRouteDurationMsFor({
    required int leavingMaxIndex,
    required int returningMaxIndex,
  }) =>
      backwardOutPhaseMsFor(leavingMaxIndex) +
          backwardInPhaseMsFor(returningMaxIndex);
}

/// Per-navigation clocks derived from each page's highest FeatheringIndex.
class WpTurnstileFeatherTiming {
  const WpTurnstileFeatherTiming({
    required this.outgoingMaxIndex,
    required this.incomingMaxIndex,
  });

  final int outgoingMaxIndex;
  final int incomingMaxIndex;

  int forwardOutPhaseMs() =>
      WpTurnstileFeather.forwardOutPhaseMsFor(outgoingMaxIndex);
  int forwardInPhaseMs() =>
      WpTurnstileFeather.forwardInPhaseMsFor(incomingMaxIndex);
  int backwardOutPhaseMs() =>
      WpTurnstileFeather.backwardOutPhaseMsFor(incomingMaxIndex);
  int backwardInPhaseMs() =>
      WpTurnstileFeather.backwardInPhaseMsFor(outgoingMaxIndex);

  int routeDurationMs() => forwardOutPhaseMs() + forwardInPhaseMs();
  int reverseRouteDurationMs() => backwardOutPhaseMs() + backwardInPhaseMs();

  Duration routeDuration() => Duration(milliseconds: routeDurationMs());
  Duration reverseRouteDuration() =>
      Duration(milliseconds: reverseRouteDurationMs());
}

// ---------------------------------------------------------------------------
// Custom PageRoute & Scope
// ---------------------------------------------------------------------------

class WpPhonePageRoute extends PageRoute {
  WpPhonePageRoute({
    required this.builder,
    required this.incomingMaxIndex,
    required this.outgoingMaxIndex,
    super.settings,
    super.requestFocus = false,
  });

  final WidgetBuilder builder;
  final int incomingMaxIndex;
  final int outgoingMaxIndex;

  WpTurnstileFeatherTiming get timing => WpTurnstileFeatherTiming(
    outgoingMaxIndex: outgoingMaxIndex,
    incomingMaxIndex: incomingMaxIndex,
  );

  @override
  Duration get transitionDuration => timing.routeDuration();

  @override
  Duration get reverseTransitionDuration => timing.reverseRouteDuration();

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  bool get opaque => false;
  @override
  bool get offstage => false;
  @override
  set offstage(bool value) {}

  @override
  TickerFuture didPush() {
    assert(controller != null);
    return controller!.forward();
  }

  @override
  void didAdd() {
    assert(controller != null);
    controller!.value = controller!.upperBound;
  }

  @override
  Widget buildPage(
      BuildContext context,
      Animation animation,
      Animation secondaryAnimation,
      ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return WpPhoneFeatherScope(
      timing: timing,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// InheritedWidget that provides the route's animation to individual FeatherLayers.
class WpPhoneFeatherScope extends InheritedWidget {
  const WpPhoneFeatherScope({
    super.key,
    required this.timing,
    required this.animation,
    required this.secondaryAnimation,
    required super.child,
  });

  final WpTurnstileFeatherTiming timing;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  static WpPhoneFeatherScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WpPhoneFeatherScope>();
  }

  @override
  bool updateShouldNotify(WpPhoneFeatherScope oldWidget) {
    return animation != oldWidget.animation ||
        secondaryAnimation != oldWidget.secondaryAnimation;
  }
}

/// A wrapper that provides the secondaryAnimation for the outgoing (current) page.
class WpPhoneFeatherScaffold extends StatelessWidget {
  final Widget child;
  final int maxIndex;

  const WpPhoneFeatherScaffold({
    super.key,
    required this.child,
    required this.maxIndex,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return child;

    return WpPhoneFeatherScope(
      timing: WpTurnstileFeatherTiming(
        outgoingMaxIndex: maxIndex,
        incomingMaxIndex: maxIndex,
      ),
      animation: const AlwaysStoppedAnimation(1.0),
      // The null-safety fix for the outgoing page
      secondaryAnimation: route.secondaryAnimation ?? const AlwaysStoppedAnimation(0.0),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// The Layer Widget (Staggered Animation)
// ---------------------------------------------------------------------------

class _FeatherPose {
  const _FeatherPose({required this.opacity, required this.rotationY});
  final double opacity;
  final double rotationY;
}

class FeatherLayer extends StatelessWidget {
  const FeatherLayer({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const _easeOut = WpToolkitExponentialEase(easeOut: true);
  static const _easeIn = WpToolkitExponentialEase(easeOut: false);

  _FeatherPose _pose(WpTurnstileFeatherTiming timing, Animation<double> animation, Animation<double> secondary) {
    final aStatus = animation.status;
    final sStatus = secondary.status;

    final total = (aStatus == AnimationStatus.reverse)
        ? timing.reverseRouteDurationMs()
        : timing.routeDurationMs();

    final a = animation.value;
    final s = secondary.value;

    final outPhase = timing.forwardOutPhaseMs();
    final backOutPhase = timing.backwardOutPhaseMs();

    if (aStatus == AnimationStatus.completed && sStatus == AnimationStatus.dismissed) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }

    // Incoming (pushed)
    if (aStatus == AnimationStatus.forward) {
      final ms = a * total;
      if (ms < outPhase) {
        return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
      }
      return _forwardIn(ms - outPhase);
    }

    // Outgoing (secondary)
    if (sStatus == AnimationStatus.forward) {
      final ms = s * total;
      if (ms < outPhase) {
        return _forwardOut(ms);
      }
      return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.forwardOutAngle);
    }

    // Popping (reverse)
    if (aStatus == AnimationStatus.reverse) {
      final ms = (1 - a) * total;
      if (ms < backOutPhase) {
        return _backwardOut(ms);
      }
      return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.backwardOutAngle);
    }

    // Returning (secondary reverse)
    if (sStatus == AnimationStatus.reverse) {
      final ms = (1 - s) * total;
      if (ms < backOutPhase) {
        return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
      }
      return _backwardIn(ms - backOutPhase);
    }

    return const _FeatherPose(opacity: 1, rotationY: 0);
  }

  _FeatherPose _forwardIn(double localMs) {
    final begin = WpTurnstileFeather.forwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardInDurationMs).clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(opacity: 1, rotationY: WpTurnstileFeather.forwardInAngle * (1 - e));
  }

  _FeatherPose _forwardOut(double localMs) {
    final begin = WpTurnstileFeather.forwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardOutDurationMs).clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.forwardOutDurationMs;
    return _FeatherPose(opacity: done ? 0 : 1, rotationY: WpTurnstileFeather.forwardOutAngle * e);
  }

  _FeatherPose _backwardIn(double localMs) {
    final begin = WpTurnstileFeather.backwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardInDurationMs).clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(opacity: 1, rotationY: WpTurnstileFeather.backwardInAngle * (1 - e));
  }

  _FeatherPose _backwardOut(double localMs) {
    final begin = WpTurnstileFeather.backwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardOutDurationMs).clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.backwardOutDurationMs;
    return _FeatherPose(opacity: done ? 0 : 1, rotationY: WpTurnstileFeather.backwardOutAngle * e);
  }

  @override
  Widget build(BuildContext context) {
    final scope = WpPhoneFeatherScope.maybeOf(context);
    if (scope == null) return child; // Fallback if not in a transition

    return AnimatedBuilder(
      animation: Listenable.merge([scope.animation, scope.secondaryAnimation]),
      builder: (context, _) {
        final pose = _pose(scope.timing, scope.animation, scope.secondaryAnimation);
        return Opacity(
          opacity: pose.opacity,
          child: Transform(
            alignment: const Alignment(-1.4, 0),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pose.rotationY * math.pi / 180),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper function to push the settings page
// ---------------------------------------------------------------------------

void pushWpPhonePage(
    BuildContext context,
    Widget page, {
      required int incomingMaxIndex,
      required int outgoingMaxIndex,
    }) {
  Navigator.of(context).push(
    WpPhonePageRoute(
      incomingMaxIndex: incomingMaxIndex,
      outgoingMaxIndex: outgoingMaxIndex,
      builder: (_) => page,
    ),
  );
}

// ---------------------------------------------------------------------------
// Settings page
// ---------------------------------------------------------------------------

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
    return Scaffold(
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
            // Index 0: First Header
            const FeatherLayer(
              index: 0,
              child: Padding(
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
            ),
            // Index 1: First Toggle
            FeatherLayer(
              index: 1,
              child: _SettingsToggle(
                title: 'Prioritize Nicknames instead of legal names',
                subtitle: 'hello world',
                value: _prioritizeNicknames,
                onChanged: (value) => setState(() => _prioritizeNicknames = value),
              ),
            ),
            const SizedBox(height: 16),
            // Index 2: Second Header
            const FeatherLayer(
              index: 2,
              child: Padding(
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
            ),
            // Index 3: Second Toggle
            FeatherLayer(
              index: 3,
              child: _SettingsToggle(
                title: 'Parse Notes for Accent Color',
                subtitle: 'hello world',
                value: _parseNotesForAccentColor,
                onChanged: (value) => setState(() => _parseNotesForAccentColor = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single toggle row with title and explanation text.
class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          WpToggleSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}