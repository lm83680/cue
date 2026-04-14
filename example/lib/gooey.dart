import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A zone that renders gooey blobs behind its registered [GooeyBlob] children.
///
/// [GooeyZone] manages a collection of gooey blobs that automatically register
/// themselves when they attach to the render tree.
///
/// ```dart
/// GooeyZone(
///   color: Colors.indigo,
///   child: Column(
///     children: [
///       GooeyBlob(shape: const BlobShape.circle(), child: Icon(Icons.add)),
///       GooeyBlob(shape: const BlobShape.circle(), child: Icon(Icons.share)),
///       GooeyBlob(shape: const BlobShape.circle(), child: Icon(Icons.edit)),
///     ],
///   ),
/// )
/// ```
class GooeyZone extends SingleChildRenderObjectWidget {
  /// Creates a [GooeyZone] with the given parameters.
  const GooeyZone({
    super.key,
    required this.color,
    this.blurRadius = 12.0,
    this.threshold = 0.5,
    required super.child,
  }) : blobOpacity = null,
       gradient = null;

  const GooeyZone.withGradient({
    super.key,
    required Gradient this.gradient,
    this.blobOpacity,
    this.blurRadius = 12.0,
    this.threshold = 0.5,
    required super.child,
  }) : color = Colors.white;

  /// Optional gradient to fill the blobs. If null, [color] is used as a solid fill.
  final Gradient? gradient;

  /// Fill color of all blobs.
  final Color color;

  /// Gaussian blur radius applied to the blob layer before thresholding.
  /// Higher values = wider merge distance between blobs.
  /// Defaults to 12.0.
  final double blurRadius;

  /// Alpha threshold for the goo snap effect (0.0–1.0).
  /// Higher values = sharper, more aggressive merge snap.
  /// Defaults to 0.5.
  final double threshold;

  /// Opacity applied to the blob layer only (not the child content).
  /// At 1.0 (default) no extra layer is pushed. At 0.0 blobs are skipped entirely.
  final double? blobOpacity;

  @override
  RenderGooeyZone createRenderObject(BuildContext context) {
    return RenderGooeyZone(
      color: color,
      blurRadius: blurRadius,
      threshold: threshold,
      gradient: gradient,
      blobOpacity: blobOpacity,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGooeyZone renderObject) {
    renderObject
      ..color = color
      ..blurRadius = blurRadius
      ..threshold = threshold
      ..gradient = gradient
      ..blobOpacity = blobOpacity;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(DoubleProperty('blurRadius', blurRadius));
    properties.add(DoubleProperty('threshold', threshold));
    properties.add(DoubleProperty('blobOpacity', blobOpacity));
  }
}

/// Defines the shape of a [GooeyBlob]'s painted background.
///
/// ```dart
/// GooeyBlob(shape: const BlobShape.circle(), child: ...)
/// GooeyBlob(shape: BlobShape.rounded(BorderRadius.circular(12)), child: ...)
/// GooeyBlob(shape: BlobShape.superEllipse(BorderRadius.circular(16)), child: ...)
/// ```
sealed class BlobShape {
  const BlobShape();

  /// Circular blob — radius = shortestSide / 2.
  const factory BlobShape.circle() = _CircleBlob;

  /// Rounded rect blob with the given [borderRadius].
  const factory BlobShape.rounded(BorderRadiusGeometry borderRadius) = _RoundedRectBlob;

  /// Super-ellipse (squircle-like) blob with the given [borderRadius].
  const factory BlobShape.superEllipse(BorderRadiusGeometry borderRadius) = _SuperEllipseBlob;
}

class _CircleBlob extends BlobShape {
  const _CircleBlob();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is _CircleBlob && runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => 0;
}

class _RoundedRectBlob extends BlobShape {
  const _RoundedRectBlob(this.borderRadius);
  final BorderRadiusGeometry borderRadius;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RoundedRectBlob && runtimeType == other.runtimeType && borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => borderRadius.hashCode;
}

class _SuperEllipseBlob extends BlobShape {
  const _SuperEllipseBlob(this.borderRadius);
  final BorderRadiusGeometry borderRadius;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _SuperEllipseBlob && runtimeType == other.runtimeType && borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => borderRadius.hashCode;
}

/// A per-child configuration widget for [GooeyZone].
///
/// [GooeyBlob] automatically attaches/detaches from the zone on lifecycle events.
/// It only carries blob shape information.
class GooeyBlob extends SingleChildRenderObjectWidget {
  /// Creates a [GooeyBlob] with the given parameters.
  const GooeyBlob({
    super.key,
    required super.child,
    this.shape = const BlobShape.circle(),
    this.cutout = false,
    this.color,
  });

  /// If true, this blob will punch a hole in the goo instead of adding to it.
  final bool cutout;

  /// Shape of the blob drawn behind this child.
  final BlobShape shape;

  /// Optional fill color for this blob.
  /// If null, inherits the [GooeyZone.color] or uses the zone's gradient.
  final Color? color;

  @override
  RenderGooeyBlob createRenderObject(BuildContext context) {
    return RenderGooeyBlob(shape: shape, cutout: cutout, color: color);
  }

  @override
  void updateRenderObject(BuildContext context, RenderGooeyBlob renderObject) {
    renderObject
      ..shape = shape
      ..cutout = cutout
      ..color = color;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BlobShape>('shape', shape));
    properties.add(FlagProperty('cutout', value: cutout, ifTrue: 'cutout'));
    properties.add(ColorProperty('color', color));
  }
}

/// A simple proxy render object that registers itself with the nearest [RenderGooeyZone].
///
/// it also paints the blob shape on the canvas when requested by the zone.
class RenderGooeyBlob extends RenderProxyBox {
  /// Creates a [RenderGooeyBlob] with the given parameters.
  RenderGooeyBlob({
    required BlobShape shape,
    RenderBox? child,
    bool cutout = false,
    Color? color,
  }) : _shape = shape,
       _cutout = cutout,
       _color = color,
       super(child);

  BlobShape _shape;
  set shape(BlobShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  bool _cutout;

  /// If true, this blob will punch a hole in the goo instead of adding to it.
  bool get cutout => _cutout;

  set cutout(bool value) {
    if (_cutout == value) return;
    _cutout = value;
    markNeedsPaint();
  }

  Color? _color;

  /// Optional fill color for this blob.
  Color? get color => _color;

  set color(Color? value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  RenderGooeyZone? _zone;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // Find the nearest RenderGooeyZone ancestor
    RenderObject? current = parent;
    while (current != null) {
      if (current is RenderGooeyZone) {
        _zone = current;
        _zone!._registerBlob(this);
        break;
      }
      current = current.parent;
    }
    if (_zone == null) {
      throw FlutterError('GooeyBlob must be a descendant of a GooeyZone.');
    }
  }

  @override
  void detach() {
    if (_zone != null) {
      _zone!._unregisterBlob(this);
      _zone = null;
    }
    super.detach();
  }

  /// Paints this blob on the given canvas with the specified parameters.
  void paintBlob(Canvas canvas, RenderGooeyZone zone, double overdraw, Paint paint) {
    final childSize = size;
    if (childSize == Size.zero) return;

    // Get the full transformation matrix (includes rotation, scale, translation, etc.)
    final matrix = getTransformTo(zone);
    canvas.save();
    canvas.transform(matrix.storage);
    Paint blobPaint = paint;
    if (_color != null) {
      blobPaint = Paint()
        ..color = _color!
        ..isAntiAlias = paint.isAntiAlias
        ..maskFilter = paint.maskFilter;
    }
    if (_cutout) {
      blobPaint = Paint()
        ..color = paint.color
        ..blendMode = BlendMode.clear
        ..maskFilter = paint.maskFilter
        ..isAntiAlias = false;
    }

    // Draw blob at local coordinates (already transformed by matrix)
    final blobCenter = childSize.center(Offset.zero);
    final shape = _shape;
    switch (shape) {
      case _CircleBlob():
        final radius = childSize.shortestSide / 2 + overdraw;
        canvas.drawCircle(blobCenter, radius, blobPaint);
      case _RoundedRectBlob():
        final borderRadius = shape.borderRadius.resolve(null);
        final blobRect = Rect.fromCenter(
          center: blobCenter,
          width: childSize.width + overdraw * 2,
          height: childSize.height + overdraw * 2,
        );
        canvas.drawRRect(borderRadius.toRRect(blobRect), blobPaint);
      case _SuperEllipseBlob():
        final borderRadius = shape.borderRadius.resolve(null);
        final blobRect = Rect.fromCenter(
          center: blobCenter,
          width: childSize.width + overdraw * 2,
          height: childSize.height + overdraw * 2,
        );
        canvas.drawRSuperellipse(
          borderRadius.toRSuperellipse(blobRect),
          blobPaint,
        );
    }

    canvas.restore();
  }
}

/// Manages a zone of registered gooey blobs.
class RenderGooeyZone extends RenderProxyBox {
  /// Creates a [RenderGooeyZone] with the given parameters.
  RenderGooeyZone({
    required Color color,
    required double blurRadius,
    required double threshold,
    double? blobOpacity,
    Gradient? gradient,
    RenderBox? child,
  }) : _color = color,
       _blurRadius = blurRadius,
       _threshold = threshold,
       _blobOpacity = blobOpacity,
       _gradient = gradient,
       super(child);

  Paint? _blobPaint;

  Paint get blobPaint {
    if (_blobPaint != null) {
      return _blobPaint!;
    }
    final paint = Paint()
      ..color = _color
      ..isAntiAlias = false;
    if (_gradient != null && hasSize) {
      paint.shader = _gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    if (_blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, _blurRadius);
    }
    return _blobPaint = paint;
  }

  final _opacityLayerHandle = LayerHandle<OpacityLayer>();
  final _filterLayerHandler = LayerHandle<ColorFilterLayer>();
  final List<RenderGooeyBlob> _blobs = [];
  ColorFilter? _filter;

  void _registerBlob(RenderGooeyBlob blob) {
    if (blob.cutout) {
      _blobs.add(blob);
    } else {
      _blobs.insert(0, blob);
    }
    markNeedsPaint();
  }

  void _unregisterBlob(RenderGooeyBlob blob) {
    _blobs.remove(blob);
    markNeedsPaint();
  }

  Gradient? _gradient;
  set gradient(Gradient? value) {
    if (_gradient == value) return;
    _gradient = value;
    _blobPaint = null; // Invalidate blob paint cache
    markNeedsPaint();
  }

  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    _blobPaint = null; // Invalidate blob paint cache
    markNeedsPaint();
  }

  double _blurRadius;
  set blurRadius(double value) {
    if (_blurRadius == value) return;
    _blurRadius = value;
    _blobPaint = null; // Invalidate blob paint cache
    markNeedsPaint();
  }

  double _threshold;
  set threshold(double value) {
    if (_threshold == value) return;
    _threshold = value;
    _filter = null; // Invalidate cache
    markNeedsPaint();
  }

  double? _blobOpacity;
  set blobOpacity(double? value) {
    if (_blobOpacity == value) return;
    _blobOpacity = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void dispose() {
    _opacityLayerHandle.layer = null;
    _filterLayerHandler.layer = null;
    super.dispose();
  }

  void _paintBlobs(PaintingContext context, Offset offset) {
    _filterLayerHandler.layer = context.pushColorFilter(
      offset,
      colorFilter,
      (ctx, offset) {
        final overdraw = _blurRadius * .2;
        for (final blob in _blobs) {
          blob.paintBlob(ctx.canvas, this, overdraw, blobPaint);
        }
      },
      oldLayer: _filterLayerHandler.layer,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final opacity = _blobOpacity ?? _color.a;
    if (_blobs.isNotEmpty && opacity > 0.0) {
      if (opacity < 1.0) {
        _opacityLayerHandle.layer = context.pushOpacity(
          offset,
          (opacity * 255).round(),
          _paintBlobs,
          oldLayer: _opacityLayerHandle.layer,
        );
      } else {
        _opacityLayerHandle.layer = null;
        _paintBlobs(context, offset);
      }
    } else {
      _opacityLayerHandle.layer = null;
    }
    super.paint(context, offset);
  }

  ColorFilter get colorFilter {
    if (_filter != null) {
      return _filter!;
    }
    final contrast = 50.0 + _threshold * 20.0;
    final biasValue = -contrast * 127.5;
    // dart format off
    final filter = ui.ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, contrast, biasValue,
    ]);
    // dart format on
    return _filter = filter;
  }
}
