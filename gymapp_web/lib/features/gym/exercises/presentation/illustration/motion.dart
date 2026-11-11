import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Side view of a person (facing right) drawn from joint angles, in a 100 × 100
/// box with the floor at y = [floorY]. Angles are directions in degrees:
/// 0 = straight down, 90 = forward (right), 180 = straight up, −90 = backward.
///
/// Standing exercises are built from the ankle up (the feet stay planted);
/// lying, hanging and seated ones from the hip.
@immutable
class Pose {
  const Pose({
    required this.root,
    this.fromAnkle = true,
    required this.shin,
    required this.thigh,
    required this.torso,
    required this.upperArm,
    required this.forearm,
    this.shin2,
    this.thigh2,
    this.upperArm2,
    this.forearm2,
    this.head = 0,
  });

  /// Ankle position when [fromAnkle], otherwise hip position.
  final Offset root;
  final bool fromAnkle;

  /// With [fromAnkle]: ankle→knee and knee→hip. Otherwise: hip→knee and knee→ankle.
  final double shin, thigh;

  /// Hip → shoulder.
  final double torso;

  /// Shoulder → elbow, elbow → hand.
  final double upperArm, forearm;

  /// Far-side limbs (drawn fainter), when they differ — lunges, running, one-arm rows.
  /// Leg: hip→knee, knee→ankle. Arm: shoulder→elbow, elbow→hand.
  final double? shin2, thigh2, upperArm2, forearm2;

  /// Head tilt relative to the torso.
  final double head;

  static double _l(double a, double b, double t) => lerpDouble(a, b, t)!;
  static double? _ln(double? a, double? b, double t) => a == null || b == null ? a ?? b : _l(a, b, t);

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        root: Offset.lerp(a.root, b.root, t)!,
        fromAnkle: a.fromAnkle,
        shin: _l(a.shin, b.shin, t),
        thigh: _l(a.thigh, b.thigh, t),
        torso: _l(a.torso, b.torso, t),
        upperArm: _l(a.upperArm, b.upperArm, t),
        forearm: _l(a.forearm, b.forearm, t),
        shin2: _ln(a.shin2, b.shin2, t),
        thigh2: _ln(a.thigh2, b.thigh2, t),
        upperArm2: _ln(a.upperArm2, b.upperArm2, t),
        forearm2: _ln(a.forearm2, b.forearm2, t),
        head: _l(a.head, b.head, t),
      );
}

const floorY = 92.0;
const _shinLen = 20.0, _thighLen = 20.0, _torsoLen = 28.0, _neck = 4.0, _headR = 6.0;
const _upperArmLen = 15.0, _forearmLen = 14.0, _footLen = 7.0;

Offset _dir(double deg, double len) {
  final r = deg * math.pi / 180;
  return Offset(math.sin(r) * len, math.cos(r) * len);
}

/// Joint positions of a pose.
class Skeleton {
  Skeleton._(this.pose, this.ankle, this.knee, this.hip, this.shoulder, this.elbow, this.hand, this.headCenter,
      this.knee2, this.ankle2, this.elbow2, this.hand2);

  factory Skeleton.of(Pose p) {
    late Offset ankle, knee, hip;
    if (p.fromAnkle) {
      ankle = p.root;
      knee = ankle + _dir(p.shin, _shinLen);
      hip = knee + _dir(p.thigh, _thighLen);
    } else {
      hip = p.root;
      knee = hip + _dir(p.thigh, _thighLen);
      ankle = knee + _dir(p.shin, _shinLen);
    }
    final shoulder = hip + _dir(p.torso, _torsoLen);
    final elbow = shoulder + _dir(p.upperArm, _upperArmLen);
    final hand = elbow + _dir(p.forearm, _forearmLen);
    final headCenter = shoulder + _dir(p.torso + p.head, _neck + _headR);
    Offset? knee2, ankle2, elbow2, hand2;
    if (p.thigh2 != null && p.shin2 != null) {
      knee2 = hip + _dir(p.thigh2!, _thighLen);
      ankle2 = knee2 + _dir(p.shin2!, _shinLen);
    }
    if (p.upperArm2 != null && p.forearm2 != null) {
      elbow2 = shoulder + _dir(p.upperArm2!, _upperArmLen);
      hand2 = elbow2 + _dir(p.forearm2!, _forearmLen);
    }
    return Skeleton._(p, ankle, knee, hip, shoulder, elbow, hand, headCenter, knee2, ankle2, elbow2, hand2);
  }

  final Pose pose;
  final Offset ankle, knee, hip, shoulder, elbow, hand, headCenter;
  final Offset? knee2, ankle2, elbow2, hand2;
}

/// What the person holds or uses. Static parts (bench, bars, machines) are in
/// box coordinates; held weights follow the hands.
enum Held { none, barbell, dumbbell, kettlebell, wheel }

@immutable
class Motion {
  const Motion(this.start, this.end, {this.held = Held.none, this.props = const [], this.cable, this.floor = true});

  final Pose start, end;
  final Held held;

  /// Static equipment drawn behind the person.
  final List<Prop> props;

  /// Cable pulley anchor; a line goes to the hand.
  final Offset? cable;
  final bool floor;
}

/// A static shape in box coordinates: a thick line (bench, bar, platform) or a
/// small circle (pulley, wheel).
@immutable
class Prop {
  const Prop.line(this.a, this.b, {this.width = 4}) : radius = null;
  const Prop.circle(this.a, this.radius) : b = null, width = 3;

  final Offset a;
  final Offset? b;
  final double width;
  final double? radius;
}

class MotionPainter extends CustomPainter {
  MotionPainter({required this.motion, required this.t, required this.body, required this.weight, required this.prop});

  final Motion motion;
  final double t;
  final Color body, weight, prop;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas
      ..save()
      ..translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2)
      ..scale(scale);

    final s = Skeleton.of(Pose.lerp(motion.start, motion.end, t));
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (motion.floor) canvas.drawLine(const Offset(4, floorY + 3), const Offset(96, floorY + 3), stroke(prop, 1.5));
    for (final p in motion.props) {
      if (p.b != null) {
        canvas.drawLine(p.a, p.b!, stroke(prop, p.width));
      } else {
        canvas.drawCircle(p.a, p.radius!, stroke(prop, p.width));
      }
    }
    if (motion.cable != null) {
      canvas
        ..drawLine(motion.cable!, s.hand, stroke(prop, 1.2))
        ..drawCircle(motion.cable!, 2.5, Paint()..color = prop);
    }

    final far = body.withValues(alpha: 0.4);
    // Far-side limbs first.
    if (s.knee2 != null) {
      canvas
        ..drawLine(s.hip, s.knee2!, stroke(far, 5))
        ..drawLine(s.knee2!, s.ankle2!, stroke(far, 5))
        ..drawLine(s.ankle2!, s.ankle2! + _dir(90, _footLen), stroke(far, 4));
    }
    if (s.elbow2 != null) {
      canvas
        ..drawLine(s.shoulder, s.elbow2!, stroke(far, 4.5))
        ..drawLine(s.elbow2!, s.hand2!, stroke(far, 4.5));
    }

    // Body.
    final limb = stroke(body, 5);
    canvas
      ..drawLine(s.ankle, s.knee, limb)
      ..drawLine(s.knee, s.hip, limb)
      ..drawLine(s.ankle, s.ankle + _dir(90, _footLen), stroke(body, 4))
      ..drawLine(s.hip, s.shoulder, stroke(body, 7))
      ..drawCircle(s.headCenter, _headR, Paint()..color = body)
      ..drawLine(s.shoulder, s.elbow, stroke(body, 4.5))
      ..drawLine(s.elbow, s.hand, stroke(body, 4.5));

    // Held weight, on top.
    final fill = Paint()..color = weight;
    for (final hand in [s.hand, ?s.hand2]) {
      switch (motion.held) {
        case Held.barbell:
          canvas
            ..drawCircle(hand, 8, fill)
            ..drawCircle(hand, 2, Paint()..color = body);
        case Held.dumbbell:
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: hand, width: 9, height: 6), const Radius.circular(2)), fill);
        case Held.kettlebell:
          canvas
            ..drawCircle(hand + const Offset(0, 5), 5, fill)
            ..drawLine(hand, hand + const Offset(0, 2), stroke(weight, 2));
        case Held.wheel:
          canvas.drawCircle(hand + const Offset(0, 3), 5, stroke(weight, 2.5));
        case Held.none:
          break;
      }
      if (motion.held == Held.barbell) break; // a bar is one object seen end-on
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MotionPainter old) => old.t != t || old.motion != motion || old.body != body;
}

/// Animated illustration: eases between the start and end pose and back, forever.
/// With reduced motion (system setting) it shows the end pose, still.
class MotionView extends StatefulWidget {
  const MotionView({super.key, required this.motion, this.size = 160, this.period = const Duration(milliseconds: 1800)});

  final Motion motion;
  final double size;
  final Duration period;

  /// Off in widget tests (test/flutter_test_config.dart): an endless animation
  /// would never let pumpAndSettle finish.
  static bool animate = true;

  @override
  State<MotionView> createState() => _MotionViewState();
}

class _MotionViewState extends State<MotionView> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.period);
  late final _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MotionView.animate || MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _curve,
          builder: (_, __) => CustomPaint(
            painter: MotionPainter(
              motion: widget.motion,
              t: _curve.value,
              body: colors.onSurface,
              weight: colors.primary,
              prop: colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}
