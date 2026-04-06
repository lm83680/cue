# Cue - Declarative Flutter Animation Package

Cue is a declarative Flutter animation package that lets you animate widgets using simple, composable building blocks.

## Quick Start

```dart
import 'package:cue/cue.dart';

Cue.onMount(
  motion: .smooth(),
  child: Actor(
    acts: [.fadeIn(), .slideY(from: 0.3)],
    child: MyWidget(),
  ),
)
```

---

## Public APIs

### Core Widgets

| API | Description |
|-----|-------------|
| `Cue` | Base class for all animation triggers |
| `CueScope` | InheritedWidget that exposes controller to subtree |
| `Actor` | Applies acts to its child |
| `CueController` | Drives animations (extends AnimationController) |
| `CueValueAnimator` | Helper for building typed value animations |

### Cue Variants (Triggers)

```dart
// Triggered when widget enters the tree
Cue.onMount(motion: .smooth(), child: ...)

// Triggered when boolean changes
Cue.onToggle(toggled: isExpanded, motion: .smooth(), child: ...)

// Triggered when any value changes
Cue.onChange(value: someValue, motion: .smooth(), child: ...)

// Triggered on mouse enter/exit
Cue.onHover(motion: .snappy(), child: ...)

// Triggered on focus changes
Cue.onFocus(focusNode: focusNode, motion: .smooth(), child: ...)

// Triggered by scroll position
Cue.onScroll(child: ...)

// Triggered when widget enters viewport
Cue.onScrollVisible(enabled: true, child: ...)

// Triggered by external Listenable
Cue.onProgress(listenable: scrollController, progress: () => ..., child: ...)

// Staggered animations for lists
Cue.indexed(controller: listController, index: i, child: ...)

// Fully imperative control
Cue(controller: myController, child: ...)
```

### Actor

```dart
Actor(
  acts: [.fadeIn(), .scale(from: 0.5, to: 1.0)],
  motion: .smooth(),        // Override motion for all acts
  reverseMotion: .linear(), // Reverse motion override
  delay: 100.ms,            // Base delay for all acts
  child: widget,
)

// Or use the .act() extension
widget.act([.fadeIn(), .slideUp()])
```

### Acts (Animation Descriptions)

**Transform:**
- `.scale(from, to)` — Scale (presets: `.zoomIn()`, `.zoomOut()`)
- `.rotate(from, to)` — Rotate in degrees
- `.rotate3D(from, to)` — 3D rotation
- `.flipX()`, `.flipY()` — Flip transforms
- `.translate(from, to)` — Pixel translation
- `.translateX()`, `.translateY()` — Axis-specific
- `.slide(from, to)` — Fraction-based slide
- `.slideUp()`, `.slideDown()`, `.slideFromLeading()`, `.slideFromTrailing()` — Presets

**Visual Effects:**
- `.opacity(from, to)` — Opacity
- `.fadeIn()`, `.fadeOut()` — Presets
- `.blur(from, to)` — Gaussian blur
- `.focus()`, `.unfocus()` — Presets
- `.backdropBlur(from, to)` — Background blur
- `.colorTint(from, to)` — Color overlay

**Layout:**
- `.sizedBox(width, height)` — Size animation
- `.sizedClip(from, to)` — Clip to size
- `.fractionalSize(widthFactor, heightFactor)` — Parent-relative size
- `.clip(borderRadius)` — Clip with border radius
- `.circularClip()` — Circular reveal
- `.padding(from, to)` — Padding animation
- `.align(from, to)` — Alignment change

**Decoration:**
- `.decorate(color, borderRadius, boxShadow, gradient)` — Box decoration
- `.textStyle(from, to)` — Text style
- `.iconTheme(from, to)` — Icon theme

### Motion Presets

```dart
// Spring physics (recommended for UI)
.smooth()    // Fast, no overshoot — default
.bouncy()    // Underdamped, visible bounce
.snappy()    // Near-instant
.gentle()    // Slow, relaxed
.wobbly()    // Wobbly spring
.spatial()   // Spatial movement
.effect()    // Effect-oriented
.spring(duration: 400.ms, bounce: 0.2)  // Custom

// Timed (curve-based)
.linear(300.ms)
.easeIn(200.ms)
.easeOut(200.ms)
.easeInOut(300.ms)
.easeOutBack(200.ms)
.curved(Duration, curve: Curves.elasticOut)
```

### Keyframes

```dart
// Motion-based keyframes
ScaleAct.keyframed(
  frames: Keyframes([
    .key(0.8),
    .key(1.2, motion: .bouncy()),
    .key(1.0),
  ], motion: .smooth()),
)

// Fractional keyframes
ScaleAct.keyframed(
  frames: Keyframes.fractional([
    .key(1.0, at: 0.0),
    .key(1.2, at: 0.5),
    .key(1.0, at: 1.0),
  ], duration: 600.ms),
)
```

### Controllers

```dart
// Basic controller
CueController(vsync: this, motion: .smooth())

// Page controller for page transitions
CuePageController()

// Tab controller
CueTabController()

// Index controller for lists
CueIndexController()

// Indexed controller for staggered lists
IndexedCueController()

// Self-animated controller
SelfAnimatedCue()
```

### Widgets

- `CueDragScrubber` — Drag to scrub animations
- `CueModalTransition` — Modal transitions
- `CueRouteMixin` — Route transitions mixin
- `CueModelTransition` — Model transitions
- `CueDebugTools` — Debug scrubber overlay

### Value Animator

```dart
// Build typed animations manually
CueAnimation<double> animation = controller.tweenTrack<double>(
  from: 0.0,
  to: 1.0,
  motion: .smooth(),
  tweenBuilder: (from, to) => ColorTween(begin: from, to: to),
);

// Or keyframed
CueAnimation<double> animation = controller.keyframedTrack<double>(
  frames: Keyframes([...], motion: .smooth()),
);
```

### Custom Acts

```dart
// Create custom tween act
class MyCustomAct extends TweenAct<MyType> {
  const MyCustomAct({required super.from, required super.to});
  
  @override
  Widget apply(BuildContext context, Animation<MyType> animation, Widget child) {
    return ...; // Apply the animation
  }
}

// Or use CustomTweenAct for simpler cases
CustomTweenAct(
  tweenBuilder: (from, to) => MyTween(from, to),
  apply: (context, value, child) => ...,
)
```

---

## Usage Patterns

### Basic Fade In

```dart
Cue.onMount(
  motion: .smooth(),
  acts: [.fadeIn()],
  child: widget,
)
```

### Toggle with Rotation

```dart
Cue.onToggle(
  toggled: isExpanded,
  motion: .smooth(),
  child: Column(
    children: [
      Actor(acts: [.rotate(to: 180)], child: Icon(Icons.expand_more)),
      Actor(acts: [.fadeIn(), .slideY(from: 0.3)], delay: 50.ms, child: content),
    ],
  ),
)
```

### Hover Scale

```dart
Cue.onHover(
  motion: .snappy(),
  child: Actor(acts: [.scale(from: 1.0, to: 1.05)], child: button),
)
```

### Controlled Animation

```dart
class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late final controller = CueController(vsync: this, motion: .smooth());

  @override
  Widget build(BuildContext context) {
    return Cue(controller: controller, acts: [.fadeIn()], child: widget);
  }
}
```

### Staggered List

```dart
// In ListView.builder
Cue.indexed(controller: listController, index: index,
  child: Actor(acts: [.fadeIn()], delay: Duration(milliseconds: index * 50), child: item),
)
```

### Modal Transition

```dart
CueModalTransition(
  visible: isVisible,
  child: modal,
)
```

---

## Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  cue:
    path: /path/to/cue
```

---

## DevTools

```dart
MaterialApp(
  builder: (context, child) {
    if (kDebugMode) {
      return CueDebugTools(child: child!);
    }
    return child!;
  },
)
```