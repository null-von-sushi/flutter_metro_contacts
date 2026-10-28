import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  /// ⚠️ TESTING: set to 10 to slow animation down 10x. Set back to 1 for real speed.
  static const int _slow = 10;

  static const double centerOfRotationX = -0.2;
  static const int forwardInDurationMs = 350 * _slow;
  static const double forwardInAngle = -80;
  static const int forwardInDelayMs = 40 * _slow;
  static const int forwardOutDurationMs = 250 * _slow;
  static const double forwardOutAngle = 50;
  static const int forwardOutDelayMs = 50 * _slow;
  static const int backwardInDurationMs = 350 * _slow;
  static const double backwardInAngle = 50;
  static const int backwardInDelayMs = 50 * _slow;
  static const int backwardOutDurationMs = 250 * _slow;
  static const double backwardOutAngle = -80;
  static const int backwardOutDelayMs = 40 * _slow;

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

class WpPhonePageRoute extends PageRoute {
  WpPhonePageRoute({
    required this.builder,
    required this.incomingMaxIndex,
    required this.outgoingMaxIndex,
    super.settings,
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
  Widget buildPage(
      BuildContext context,
      Animation animation,
      Animation secondaryAnimation,
      ) =>
      builder(context);

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) =>
      WpPhoneFeatherScope(
        timing: timing,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
}

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

  static WpPhoneFeatherScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WpPhoneFeatherScope>();

  @override
  bool updateShouldNotify(WpPhoneFeatherScope oldWidget) =>
      animation != oldWidget.animation ||
          secondaryAnimation != oldWidget.secondaryAnimation;
}

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

  _FeatherPose _pose(WpTurnstileFeatherTiming timing,
      Animation<double> animation, Animation<double> secondary) {
    final aStatus = animation.status;
    final sStatus = secondary.status;
    final a = animation.value;
    final s = secondary.value;

    if (a >= 1.0 && s <= 0.0) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }

    final total = (aStatus == AnimationStatus.reverse)
        ? timing.reverseRouteDurationMs()
        : timing.routeDurationMs();

    final outPhase = timing.forwardOutPhaseMs();
    final backOutPhase = timing.backwardOutPhaseMs();

    if (aStatus == AnimationStatus.forward) {
      final ms = a * total;
      if (ms < outPhase) {
        return const _FeatherPose(
            opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
      }
      return _forwardIn(ms - outPhase);
    }

    if (sStatus == AnimationStatus.forward) {
      final ms = s * total;
      if (ms < outPhase) {
        return _forwardOut(ms);
      }
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.forwardOutAngle);
    }

    if (aStatus == AnimationStatus.reverse) {
      final ms = (1 - a) * total;
      if (ms < backOutPhase) {
        return _backwardOut(ms);
      }
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.backwardOutAngle);
    }

    if (sStatus == AnimationStatus.reverse) {
      final ms = (1 - s) * total;
      if (ms < backOutPhase) {
        return const _FeatherPose(
            opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
      }
      return _backwardIn(ms - backOutPhase);
    }

    return const _FeatherPose(opacity: 1, rotationY: 0);
  }

  _FeatherPose _forwardIn(double localMs) {
    final begin = WpTurnstileFeather.forwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardInDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(
      opacity: 1,
      rotationY: WpTurnstileFeather.forwardInAngle * (1 - e),
    );
  }

  _FeatherPose _forwardOut(double localMs) {
    final begin = WpTurnstileFeather.forwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardOutDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.forwardOutDurationMs;
    return _FeatherPose(
      opacity: done ? 0 : 1,
      rotationY: WpTurnstileFeather.forwardOutAngle * e,
    );
  }

  _FeatherPose _backwardIn(double localMs) {
    final begin = WpTurnstileFeather.backwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardInDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(
        opacity: 1,
        rotationY: WpTurnstileFeather.backwardInAngle * (1 - e));
  }

  _FeatherPose _backwardOut(double localMs) {
    final begin = WpTurnstileFeather.backwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardOutDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.backwardOutDurationMs;
    return _FeatherPose(
        opacity: done ? 0 : 1,
        rotationY: WpTurnstileFeather.backwardOutAngle * e);
  }

  @override
  Widget build(BuildContext context) {
    final scope = WpPhoneFeatherScope.maybeOf(context);
    if (scope == null) return child;

    return AnimatedBuilder(
      animation: Listenable.merge([scope.animation, scope.secondaryAnimation]),
      builder: (context, _) {
        final pose =
        _pose(scope.timing, scope.animation, scope.secondaryAnimation);
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