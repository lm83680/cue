# GitHub Copilot Instructions for Cue Animation Library

This project uses **Cue**, a declarative Flutter animation library. Follow these guidelines when suggesting code.

## Core Principles

1. **Use declarative animations** with Cue widgets instead of imperative AnimationController
2. **Prefer Spring motions** for natural, interactive animations
3. **Compose Acts** within Actor widgets for complex animations
4. **One Act type per Actor** - don't duplicate transform types

## Quick Reference

### Basic Toggle Animation

```dart
Cue.onToggle(
  toggled: isExpanded,
  motion: Spring.smooth(damping: 23),
  child: Actor(
    acts: [
      .scale(from: 1.0, to: 1.05),
      .fadeIn(),
      .rotate(to: 180),
    ],
    child: MyWidget(),
  ),
)
```

### Entrance Animation

```dart
Cue.onMount(
  motion: Spring.smooth(damping: 23),
  child: Actor(
    acts: [
      .slideY(from: 0.5, to: 0),
      .fadeIn(),
      .blur(from: 8, to: 0),
    ],
    child: MyWidget(),
  ),
)
```

### Size Animation with Clipping

```dart
Actor(
  acts: [
    .sizedClip(
      from: NSize.width(100),
      to: NSize.width(300),
      alignment: Alignment.centerLeft,
    ),
  ],
  child: MyWidget(),
)
```

## Common Acts

### Transform
- `.scale(from: 1.0, to: 1.2)` - Scale widget
- `.rotate(to: 180)` - Rotate (degrees by default)
- `.translate(to: Offset(100, 50))` - Move by pixels
- `.slide(to: Offset(1, 0))` - Move by widget size
- `.slideY(from: 0.5)` - Vertical slide

### Visual Effects
- `.fadeIn()` / `.fadeOut()` - Opacity presets
- `.blur(from: 0, to: 10)` - Blur effect
- `.colorTint(from: Colors.transparent, to: Colors.blue.withOpacity(0.5))`

### Layout
- `.sizedClip(from: NSize, to: NSize)` - Animate size with clipping
- `.clipHeight(fromFactor: 0.3)` - Clip height 0-1
- `.padding(from: EdgeInsets, to: EdgeInsets)` - Animate padding
- `.align(from: Alignment, to: Alignment)` - Change alignment

### Decoration
- `.decorate(color: .tween(from: Colors.red, to: Colors.blue))`

## Motion Types

```dart
// Recommended: Spring physics for natural motion
Spring.smooth(damping: 23)
Spring.bouncy()
Spring.gentle()

// Timed motions
CueMotion.linear(Duration(milliseconds: 300))
CueMotion.curved(Duration(milliseconds: 400), curve: Curves.easeOut)
```

## Patterns to Follow

### ✅ DO: Single Act per type
```dart
Actor(
  acts: [
    .scale(from: 1.0, to: 1.1),
    .rotate(to: 180),
    .fadeIn(),
  ],
  child: widget,
)
```

### ❌ DON'T: Multiple Acts of same type
```dart
Actor(
  acts: [
    .scale(from: 1.0, to: 1.1),
    .scale(from: 0.5, to: 1.0), // ❌ Conflict!
  ],
  child: widget,
)
```

### ✅ DO: Use separate Actors for different timing
```dart
Column(
  children: [
    Actor(
      acts: [.fadeIn()],
      delay: Duration.zero,
      child: Item1(),
    ),
    Actor(
      acts: [.fadeIn()],
      delay: Duration(milliseconds: 100),
      child: Item2(),
    ),
  ],
)
```

### ✅ DO: Use NSize for flexible sizing
```dart
.sizedClip(
  from: NSize.width(80),      // Fixed width, child height
  to: NSize.width(200),
  // or
  from: NSize.childSize,      // Both axes follow child
  to: NSize(w: 200, h: 100),  // Both axes fixed
)
```

### ✅ DO: Use keyframes for complex sequences
```dart
ScaleAct.keyframed(
  frames: .fractional([
    .key(1.0, at: 0.0),
    .key(1.2, at: 0.5),
    .key(1.0, at: 1.0),
  ]),
)
```

## Extension Shortcuts

Cue provides shorthand extensions:
```dart
EdgeInsets: .all(16), .symmetric(horizontal: 16), .zero
BorderRadius: .circular(12), .vertical(...)
Alignment: .center, .topLeft, .bottomRight
MainAxisAlignment: .center, .spaceBetween
FontWeight: .bold, .w600
Clip: .antiAlias, .hardEdge
```

## Common Use Cases

### Expandable Card
```dart
Cue.onToggle(
  toggled: isExpanded,
  motion: Spring.smooth(damping: 23),
  child: Column(
    children: [
      // Header with arrow rotation
      Actor(
        acts: [.rotate(to: 180)],
        child: Icon(Icons.expand_more),
      ),
      // Content that clips in
      Actor(
        acts: [
          .clipHeight(fromFactor: 0.3),
          .fadeIn(),
          .slideY(from: 0.5),
        ],
        child: ExpandedContent(),
      ),
    ],
  ),
)
```

### Hover Effect
```dart
Cue.onHover(
  motion: Spring.smooth(damping: 23),
  child: Actor(
    acts: [
      .scale(from: 1.0, to: 1.05),
      .decorate(
        boxShadow: .tween(
          from: [BoxShadow(blurRadius: 4)],
          to: [BoxShadow(blurRadius: 12)],
        ),
      ),
    ],
    child: MyButton(),
  ),
)
```

### Scroll Reveal
```dart
Cue.onScrollVisible(
  enabled: true,
  child: Actor(
    acts: [
      .fadeIn(),
      .slideY(from: 0.2, to: 0),
      .scale(from: 0.9, to: 1.0),
    ],
    child: MyWidget(),
  ),
)
```

### Horizontal Expanding Cards
```dart
Cue.onToggle(
  toggled: isSelected,
  motion: Spring.smooth(damping: 23),
  child: Actor(
    acts: [
      .sizedClip(
        from: NSize.width(80),
        to: NSize.width(240),
        clipGeometry: ClipGeometry.rrect(BorderRadius.circular(20)),
      ),
    ],
    child: Card(child: content),
  ),
)
```

## Performance Tips

1. Use `Spring.smooth()` for most UI interactions
2. Avoid animating expensive filters on large widgets
3. Use `clipBehavior: Clip.none` when clipping isn't needed
4. Prefer `sizedClip` over `sizedBox` when overflow clipping is needed
5. Combine Acts in one Actor rather than nesting multiple Actors

## Debugging

Wrap your app with `CueDebugProvider` to visualize animations:
```dart
CueDebugProvider(
  child: MaterialApp(...),
)
```

## Type Reference

**NSize** - Nullable size for flexible constraints:
- `NSize(w: 200, h: 100)` - Fixed dimensions
- `NSize.width(200)` - Fixed width, child height
- `NSize.height(100)` - Fixed height, child width
- `NSize.childSize` - Both axes follow child
- `NSize.infinity` - Use max constraints

**Rotation3D** - 3D rotation values:
- `Rotation3D(x: 45, y: 90, z: 0)` - Angles in degrees/radians

**Position** - For positioned widgets in Stack:
- `Position.fill(start: 0, top: 0, end: 0, bottom: 0)`
- `Position(start: 10, top: 20, width: 100)`

**ClipGeometry** - Clipping shapes:
- `ClipGeometry.rect()` - Rectangular clip
- `ClipGeometry.rrect(BorderRadius)` - Rounded rectangle
- `ClipGeometry.superEllipse(BorderRadius)` - Super-ellipse shape

## Summary

When suggesting Cue animations:
1. Use `Cue.onToggle` for state-based animations
2. Use `Actor` with `acts: []` to apply animations
3. Prefer `Spring.smooth()` for natural motion
4. One Act type per Actor
5. Use shorthand extensions (`.circular()`, `.all()`, etc.)
6. Follow the patterns shown above

For complete API documentation, see `.kilo/skill/cue-animations.md`.
