import 'package:cue/src/motion/cue_motion.dart';
import 'package:cue/src/motion/cue_simulation.dart';
import 'package:flutter/widgets.dart';

const Tolerance _kDefaultTolerance = Tolerance(distance: 0.01, velocity: 0.03);

/// A physics-based spring motion that models a damped harmonic oscillator.
///
/// Unlike timed motions, a spring's duration is not set directly — it emerges
/// from the physical properties of mass, stiffness, and damping. The
/// simulation runs until the value settles within [tolerance] of the target.
///
/// Spring motions respond naturally to interruptions: if the underlying value
/// changes mid-animation, the spring inherits the current velocity and
/// continues without a jarring discontinuity.
///
/// ## Presets
///
/// Named constructors cover the most common interaction feels, organized by
/// use case. **For most use cases, prefer the shorthand named constructors**
/// like `.smooth()`, `.bouncy()`, `.snappy()`, etc., which have well-tuned
/// presets:
///
/// **General purpose**
/// - [Spring.smooth] — critically damped, fast and clean; the best default
/// - [Spring.gentle] — slow and slightly bouncy; background or ambient
/// - [Spring.bouncy] — underdamped with visible overshoot; playful feel
/// - [Spring.wobbly] — heavily underdamped; exaggerated oscillation
/// - [Spring.snappy] — near-instant, no overshoot; micro-interactions
/// - [Spring.interactive] — responsive with subtle follow-through; drag/hover
///
/// **Spatial (Material Design layout motion)**
/// - [Spring.spatial] — standard Material container motion
/// - [Spring.spatialSlow] — slower; for large or heavy elements
/// - [Spring.spatialFast] — faster; for navigation and toolbars
///
/// **Effect (Material Design decorative motion)**
/// - [Spring.effect] — smooth decorative changes without overshoot
/// - [Spring.effectSlow] — gradual emphasis effects
/// - [Spring.effectFast] — immediate visual feedback with light bounce
///
/// **Custom**
/// - [Spring] factory — duration + bounce control for precise timing
/// - [Spring.withDampingRatio] — explicit mass and stiffness with ratio
/// - [Spring.custom] — raw [SpringDescription] for full control
///
/// All presets expose their underlying parameters as optional overrides, so
/// you can fine-tune without recreating the full configuration from scratch:
///
/// ```dart
/// // Smooth but slightly more bouncy
/// Spring.smooth(dampingRatio: 0.85)
///
/// // Snappy with a tighter tolerance
/// Spring.snappy(tolerance: Tolerance(distance: 0.001, velocity: 0.001))
/// ```
final class Spring extends SimulationMotion<CueSpringSimulation> {
  /// Spring mass in kilograms — higher values make the spring feel heavier
  /// and slower to start, but maintain the same stiffness pull.
  ///
  /// `null` when using a raw [SpringDescription] via [Spring.custom].
  final double? mass;

  /// Spring stiffness constant — higher values produce a tighter, faster
  /// spring that pulls more aggressively toward the target.
  ///
  /// `null` when using a raw [SpringDescription] via [Spring.custom].
  final double? stiffness;

  /// Damping ratio relative to critical damping:
  /// - `1.0` — critically damped, no overshoot ([smooth], [snappy], [effect] presets)
  /// - `< 1.0` — underdamped, overshoots and oscillates ([bouncy], [wobbly])
  /// - `> 1.0` — overdamped, approaches target asymptotically (very rare)
  ///
  /// `null` when using a raw [SpringDescription] via [Spring.custom].
  final double? dampingRatio;

  /// How close the value and velocity must be to the target before the
  /// simulation is considered complete.
  ///
  /// Defaults to `Tolerance(distance: 0.01, velocity: 0.03)`.
  final Tolerance tolerance;

  /// Whether to snap the value exactly to [SimulationBuildData.endValue] once
  /// the simulation settles within [tolerance].
  ///
  /// Defaults to `true`. Set to `false` for layout springs (e.g., [Spring.spatial])
  /// where snapping can cause layout-reflow artifacts in shared-axis transitions.
  final bool snapToEnd;

  final SpringDescription? _rawDesc;

  @override
  CueSpringSimulation build(SimulationBuildData data) {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    final refreshRate = view?.display.refreshRate ?? 60.0;
    return CueSpringSimulation(
      springDescription,
      data.startValue,
      data.endValue,
      data.velocity ?? 0.0,
      tolerance: tolerance,
      snapToEnd: snapToEnd,
      samplingStepSize: 1 / refreshRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spring &&
        other.mass == mass &&
        other.stiffness == stiffness &&
        other.dampingRatio == dampingRatio &&
        other.tolerance == tolerance &&
        other._rawDesc == _rawDesc &&
        other.snapToEnd == snapToEnd;
  }

  @override
  int get hashCode {
    return Object.hash(mass, stiffness, dampingRatio, tolerance, snapToEnd, _rawDesc);
  }


  /// Resolves the [SpringDescription] used to build the simulation.
  ///
  /// Returns [_rawDesc] directly if provided via [Spring.custom]; otherwise
  /// constructs one from [mass], [stiffness], and [dampingRatio].
  SpringDescription get springDescription {
    if (_rawDesc != null) {
      return _rawDesc;
    }
    assert(
      mass != null && stiffness != null && dampingRatio != null,
      'Either provide a raw SpringDescription or specify mass, stiffness, and dampingRatio',
    );
    return SpringDescription.withDampingRatio(
      mass: mass!,
      stiffness: stiffness!,
      ratio: dampingRatio!,
    );
  }

  /// Creates a spring motion from a pre-built [SpringDescription].
  ///
  /// Use this when you already have a Flutter [SpringDescription] and want
  /// to wrap it directly. For most cases, prefer the named constructors or
  /// the [Spring] factory.
  const Spring.custom({
    required SpringDescription desc,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = desc,
       mass = null,
       stiffness = null,
       dampingRatio = null;

  /// Creates a spring motion with explicit mass, stiffness, and damping ratio.
  ///
  /// More flexible than the named presets, but lower-level than the [Spring]
  /// factory. The [ratio] parameter maps directly to [dampingRatio].
  const Spring.withDampingRatio({
    this.mass = 1.0,
    required this.stiffness,
    required double ratio,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null,
       dampingRatio = ratio;

  /// {@template cue.motion.smooth}
  /// A fast, critically damped spring — the recommended default for most UI.
  ///
  /// Reaches the target without any overshoot. High stiffness means it starts
  /// quickly and settles cleanly, giving a crisp and professional feel.
  ///
  /// Default parameters: `mass: 1.1`, `stiffness: 522.35`, `dampingRatio: 1.0`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isExpanded,
  ///   motion: .smooth(),
  ///   child: Actor(acts: [.scale(from: 0.95), .fadeIn()], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.smooth({
    double this.mass = 1.1,
    double this.stiffness = 522.35,
    double this.dampingRatio = 1.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.bouncy}
  /// An underdamped spring that overshoots and bounces back.
  ///
  /// The `dampingRatio: 0.7` produces a visible, satisfying bounce — ideal
  /// for emphasis interactions, delight moments, or elements entering the
  /// screen with energy.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 325.0`, `dampingRatio: 0.7`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isVisible,
  ///   motion: .bouncy(),
  ///   child: Actor(acts: [.scale(from: 0.0), .fadeIn()], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.bouncy({
    double this.mass = 1.0,
    double this.stiffness = 325.0,
    double this.dampingRatio = 0.7,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// A responsive spring tuned for interactive gestures like drag and hover.
  ///
  /// Slightly underdamped (`dampingRatio: 0.86`) compared to [Spring.smooth],
  /// giving a subtle follow-through that feels finger-connected while still
  /// settling quickly.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 522.35`, `dampingRatio: 0.86`.
  ///
  /// ```dart
  /// Cue.onHover(
  ///   motion: const Spring.interactive(),
  ///   child: Actor(acts: [.scale(from: 1.0, to: 1.05)], child: MyButton()),
  /// )
  /// ```
  const Spring.interactive({
    double this.mass = 1.0,
    double this.stiffness = 522.35,
    double this.dampingRatio = 0.86,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.snappy}
  /// A near-instant, critically damped spring for tight micro-interactions.
  ///
  /// Extremely high stiffness (`1754.6`) means the value reaches its target
  /// almost immediately — but it is still a continuous physics simulation, so
  /// interruptions and velocity hand-off work naturally.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 1754.6`, `dampingRatio: 1.0`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isActive,
  ///   motion: .snappy(),
  ///   child: Actor(acts: [.scale(from: 0.92), .fadeIn()], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.snappy({
    double this.mass = 1.0,
    double this.stiffness = 1754.6,
    double this.dampingRatio = 1.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.wobbly}
  /// A heavily underdamped spring with exaggerated oscillation.
  ///
  /// Low stiffness (`200.0`) and a low damping ratio (`0.4`) produce multiple
  /// visible bounces before settling. Use sparingly — best for playful,
  /// expressive moments where wobble is part of the design intent.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 200.0`, `dampingRatio: 0.4`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isShaking,
  ///   motion: .wobbly(),
  ///   child: Actor(acts: [.rotate(to: 15)], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.wobbly({
    double this.mass = 1.0,
    double this.stiffness = 200.0,
    double this.dampingRatio = 0.4,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.gentle}
  /// A slow, softly underdamped spring for ambient or background animations.
  ///
  /// Low stiffness (`61.69`) gives it a relaxed pace, while `dampingRatio: 0.7`
  /// adds just a hint of bounce. Good for floating elements, subtle reveals,
  /// or transitions that should not draw too much attention.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 61.69`, `dampingRatio: 0.7`.
  ///
  /// ```dart
  /// Cue.onScrollVisible(
  ///   child: Actor(acts: [.fadeIn(), .slideY(from: 0.1)], child: MyWidget()),
  /// )
  /// // or explicitly:
  /// Cue.onToggle(
  ///   toggled: isVisible,
  ///   motion: .gentle(),
  ///   child: Actor(acts: [.fadeIn()], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.gentle({
    double this.mass = 1.0,
    double this.stiffness = 61.69,
    double this.dampingRatio = 0.7,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  // Material
  /// {@template cue.motion.spatial_fast}
  /// A fast Material Design spatial spring with slight overshoot.
  ///
  /// High stiffness (`1400.0`) and `dampingRatio: 0.7` make this spring fast
  /// and lightly bouncy — suited for navigation bars, tab indicators, and
  /// toolbar transitions where speed communicates responsiveness.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 1400.0`, `dampingRatio: 0.7`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: tabSelected,
  ///   motion: .spatialFast(),
  ///   child: Actor(acts: [.slideX(from: 0.3), .fadeIn()], child: NavIndicator()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.spatialFast({
    double this.mass = 1.0,
    double this.stiffness = 1400.0,
    double this.dampingRatio = 0.7,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.spatial}
  /// The standard Material Design spatial spring for container transitions.
  ///
  /// Balanced stiffness (`700.0`) with `dampingRatio: 0.8` gives a natural
  /// spring feel without excessive overshoot. Note: `snapToEnd` defaults to
  /// `false` to avoid layout-reflow artifacts in shared-axis transitions.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 700.0`, `dampingRatio: 0.8`, `snapToEnd: false`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isExpanded,
  ///   motion: .spatial(),
  ///   child: Actor(
  ///     acts: [.sizedClip(from: NSize.width(80), to: NSize.width(240))],
  ///     child: Card(child: content),
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.spatial({
    double this.mass = 1.0,
    double this.stiffness = 700.0,
    double this.dampingRatio = 0.8,
    this.snapToEnd = false,
    this.tolerance = _kDefaultTolerance,
  }) : _rawDesc = null;

  /// {@template cue.motion.spatial_slow}
  /// A slower Material Design spatial spring for large or heavy elements.
  ///
  /// Lower stiffness (`300.0`) than [Spring.spatial] produces a more
  /// deliberate pace — appropriate for full-screen transitions, bottom
  /// sheets, or any container whose size makes a fast spring feel abrupt.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 300.0`, `dampingRatio: 0.8`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isOpen,
  ///   motion: .spatialSlow(),
  ///   child: Actor(acts: [.slideY(from: 1.0), .fadeIn()], child: BottomSheet()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.spatialSlow({
    double this.mass = 1.0,
    double this.stiffness = 300.0,
    double this.dampingRatio = 0.8,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.effect_fast}
  /// A fast Material Design effect spring with light bounce.
  ///
  /// High stiffness (`1400.0`) and `dampingRatio: 0.7` — use this for
  /// immediate decorative feedback: icon state changes, badge appearances,
  /// and quick color or scale transitions.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 1400.0`, `dampingRatio: 0.7`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isFavorited,
  ///   motion: .effectFast(),
  ///   child: Actor(acts: [.scale(from: 0.6), .fadeIn()], child: FavoriteIcon()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.effectFast({
    double this.mass = 1.0,
    double this.stiffness = 1400.0,
    double this.dampingRatio = 0.7,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.effect}
  /// The standard Material Design effect spring — balanced and without overshoot.
  ///
  /// Stiffness `700.0` with critical damping (`dampingRatio: 1.0`) gives a
  /// clean, smooth decorative motion. Suitable for color transitions, size
  /// changes, and emphasis effects where a precise landing matters more than
  /// energy.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 700.0`, `dampingRatio: 1.0`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isSelected,
  ///   motion: .effect(),
  ///   child: Actor(
  ///     acts: [.decorate(color: .tween(from: Colors.grey, to: Colors.blue))],
  ///     child: MyChip(),
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.effect({
    double this.mass = 1.0,
    double this.stiffness = 700.0,
    double this.dampingRatio = 1.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.effect_slow}
  /// A slow, critically damped Material Design effect spring.
  ///
  /// Low stiffness (`300.0`) and no overshoot (`dampingRatio: 1.0`) — use
  /// for gradual emphasis animations like a pulsing highlight, a slow color
  /// wash, or a gently expanding focus ring.
  ///
  /// Default parameters: `mass: 1.0`, `stiffness: 300.0`, `dampingRatio: 1.0`.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isFocused,
  ///   motion: .effectSlow(),
  ///   child: Actor(acts: [.scale(from: 0.97)], child: FocusRing()),
  /// )
  /// ```
  /// {@endtemplate}
  const Spring.effectSlow({
    double this.mass = 1.0,
    double this.stiffness = 300.0,
    double this.dampingRatio = 1.0,
    this.tolerance = _kDefaultTolerance,
    this.snapToEnd = true,
  }) : _rawDesc = null;

  /// {@template cue.motion.spring}
  /// A spring defined by its settling duration and bounce amount.
  ///
  /// Converts human-friendly parameters into a [SpringDescription] via
  /// [SpringDescription.withDurationAndBounce], making it easy to dial in
  /// timing without thinking about mass and stiffness.
  ///
  /// - [duration]: Approximate time for the spring to settle. Defaults to 500 ms.
  /// - [bounce]: Controls overshoot — `0` is no bounce (critically damped),
  ///   positive values increase oscillation, negative values overdamp.
  ///
  /// ```dart
  /// Cue.onToggle(
  ///   toggled: isVisible,
  ///   motion: .spring(duration: 400.ms, bounce: 0.2),
  ///   child: Actor(acts: [.scale(from: 0.8), .fadeIn()], child: MyWidget()),
  /// )
  /// ```
  /// {@endtemplate}
  factory Spring({
    Duration duration = const Duration(milliseconds: 500),
    double bounce = 0,
    bool snapToEnd = true,
  }) {
    return Spring.custom(
      desc: SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: bounce,
      ),
      snapToEnd: snapToEnd,
    );
  }
  /// The nominal 0→1 settling duration, derived by running a fresh simulation.
  ///
  /// This is the reference duration for a full journey from 0 to 1 (or 1 to 0).
  /// Computed once via [buildBase] and rounded to the nearest millisecond.
  @override
  Duration get baseDuration {
    final milliseconds = (buildBase().duration * Duration.millisecondsPerSecond).round();
    return Duration(milliseconds: milliseconds);
  }
}
