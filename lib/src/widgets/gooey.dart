import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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
    this.blobOpacity = 1.0,
    required super.child,
  });

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
  final double blobOpacity;

  @override
  RenderGooeyZone createRenderObject(BuildContext context) {
    return RenderGooeyZone(
      color: color,
      blurRadius: blurRadius,
      threshold: threshold,
      blobOpacity: blobOpacity,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGooeyZone renderObject) {
    renderObject
      ..color = color
      ..blurRadius = blurRadius
      ..threshold = threshold
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
  });

  /// If true, this blob will punch a hole in the goo instead of adding to it.
  final bool cutout;

  /// Shape of the blob drawn behind this child.
  final BlobShape shape;

  @override
  RenderGooeyBlob createRenderObject(BuildContext context) {
    return RenderGooeyBlob(shape: shape, cutout: cutout);
  }

  @override
  void updateRenderObject(BuildContext context, RenderGooeyBlob renderObject) {
    renderObject
      ..shape = shape
      ..cutout = cutout;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BlobShape>('shape', shape));
    properties.add(FlagProperty('cutout', value: cutout, ifTrue: 'cutout'));
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
  }) : _shape = shape,
       _cutout = cutout,
       super(child);

  BlobShape _shape;
  set shape(BlobShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  bool _cutout;
  set cutout(bool value) {
    if (_cutout == value) return;
    _cutout = value;
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

    if (_cutout) {
      paint.blendMode = BlendMode.clear;
    }
    // Draw blob at local coordinates (already transformed by matrix)
    final blobCenter = childSize.center(Offset.zero);
    final shape = _shape;
    switch (shape) {
      case _CircleBlob():
        final radius = childSize.shortestSide / 2 + overdraw;
        canvas.drawCircle(blobCenter, radius, paint);
      case _RoundedRectBlob():
        final borderRadius = shape.borderRadius.resolve(null);
        final blobRect = Rect.fromCenter(
          center: blobCenter,
          width: childSize.width + overdraw * 2,
          height: childSize.height + overdraw * 2,
        );
        canvas.drawRRect(borderRadius.toRRect(blobRect).inflate(overdraw), paint);
      case _SuperEllipseBlob():
        final borderRadius = shape.borderRadius.resolve(null);
        final blobRect = Rect.fromCenter(
          center: blobCenter,
          width: childSize.width + overdraw * 2,
          height: childSize.height + overdraw * 2,
        );
        canvas.drawRSuperellipse(
          borderRadius.toRSuperellipse(blobRect).inflate(overdraw),
          paint,
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
    double blobOpacity = 1.0,
    RenderBox? child,
  }) : _color = color,
       _blurRadius = blurRadius,
       _threshold = threshold,
       _blobOpacity = blobOpacity,
       super(child);

  final List<RenderGooeyBlob> _blobs = [];

  //cache
  Paint? _cachedBlurFilterPaint;
  Paint? _cachedThresholdFilterPaint;
  Paint? _blobPaint;
  final _opacityLayerHandle = LayerHandle<OpacityLayer>();

  void _registerBlob(RenderGooeyBlob blob) {
    _blobs.add(blob);
    markNeedsPaint();
  }

  void _unregisterBlob(RenderGooeyBlob blob) {
    _blobs.remove(blob);
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
    _cachedBlurFilterPaint = null; // Invalidate cache
    markNeedsPaint();
  }

  double _threshold;
  set threshold(double value) {
    if (_threshold == value) return;
    _threshold = value;
    _cachedThresholdFilterPaint = null; // Invalidate cache
    markNeedsPaint();
  }

  double _blobOpacity;
  set blobOpacity(double value) {
    if (_blobOpacity == value) return;
    _blobOpacity = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void dispose() {
    _opacityLayerHandle.layer = null;
    super.dispose();
  }

  void _paintBlobs(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final expand = _blurRadius * 3;
    final layerRect = (offset - Offset(expand, expand)) & Size(size.width + expand * 2, size.height + expand * 2);

    canvas.saveLayer(layerRect, _getThresholdFilterPaint());
    canvas.saveLayer(layerRect, _getBlurFilterPaint());

    final overdraw = _blurRadius * 0.2;
    final paint = _blobPaint ??= Paint()..color = _color;
    for (final blob in _blobs) {
      blob.paintBlob(canvas, this, overdraw, paint);
    }
    canvas.restore(); // apply blur
    canvas.restore(); // apply threshold
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_blobs.isNotEmpty && _blobOpacity > 0.0) {
      if (_blobOpacity < 1.0) {
        _opacityLayerHandle.layer = context.pushOpacity(
          offset,
          (_blobOpacity * 255).round(),
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

  Paint _getBlurFilterPaint() {
    return _cachedBlurFilterPaint ??= Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: _blurRadius,
        sigmaY: _blurRadius,
        tileMode: TileMode.decal,
      );
  }

  Paint _getThresholdFilterPaint() {
    if (_cachedThresholdFilterPaint != null) {
      return _cachedThresholdFilterPaint!;
    }
    final contrast = 40.0 + _threshold * 20.0;
    final biasValue = -contrast * 127.5;
    // dart format off
    final filter = ui.ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, contrast, biasValue,
    ]);
    // dart format on
    return _cachedThresholdFilterPaint = Paint()..colorFilter = filter;
  }
}
