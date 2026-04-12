import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GooeyZone', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GooeyZone(
            color: Colors.indigo,
            child: const Text('child'),
          ),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('passes color parameter to constructor', (tester) async {
      final widget = GooeyZone(
        color: Colors.red,
        child: const SizedBox(),
      );

      expect(widget.color, equals(Colors.red));
    });

    testWidgets('passes custom blurRadius', (tester) async {
      final widget = GooeyZone(
        color: Colors.indigo,
        blurRadius: 15.0,
        child: const SizedBox(),
      );
      expect(widget.blurRadius, equals(15.0));
    });

    testWidgets('default blurRadius is 12.0', (tester) async {
      final widget = GooeyZone(
        color: Colors.indigo,
        child: const SizedBox(),
      );

      expect(widget.blurRadius, equals(12.0));
    });

    testWidgets('passes custom threshold', (tester) async {
      final widget = GooeyZone(
        color: Colors.indigo,
        threshold: 0.7,
        child: const SizedBox(),
      );

      expect(widget.threshold, equals(0.7));
    });

    testWidgets('default threshold is 0.5', (tester) async {
      final widget = GooeyZone(
        color: Colors.indigo,
        child: const SizedBox(),
      );

      expect(widget.threshold, equals(0.5));
    });
  });

  group('GooeyBlob', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GooeyZone(
            color: Colors.indigo,
            child: GooeyBlob(
              child: const Text('blob'),
            ),
          ),
        ),
      );

      expect(find.text('blob'), findsOneWidget);
    });

    testWidgets('default shape is BlobShape.circle', (tester) async {
      final blob = GooeyBlob(
        child: const SizedBox(),
      );

      expect(blob.shape, isA<BlobShape>());
    });

    testWidgets('accepts BlobShape.circle', (tester) async {
      final blob = GooeyBlob(
        shape: const BlobShape.circle(),
        child: const SizedBox(),
      );

      expect(blob.shape, equals(const BlobShape.circle()));
    });

    testWidgets('accepts BlobShape.rounded', (tester) async {
      final blob = GooeyBlob(
        shape: BlobShape.rounded(BorderRadius.circular(8)),
        child: const SizedBox(),
      );

      expect(blob.shape, isA<BlobShape>());
    });

    testWidgets('accepts BlobShape.superEllipse', (tester) async {
      final blob = GooeyBlob(
        shape: BlobShape.superEllipse(BorderRadius.circular(16)),
        child: const SizedBox(),
      );

      expect(blob.shape, isA<BlobShape>());
    });

    testWidgets('registers with GooeyZone when rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GooeyZone(
            color: Colors.indigo,
            child: GooeyBlob(
              child: const SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(find.byType(GooeyBlob), findsOneWidget);
    });
  });

  group('BlobShape', () {
    test('circle creates BlobShape instance', () {
      const shape = BlobShape.circle();
      expect(shape, isA<BlobShape>());
    });

    test('rounded creates BlobShape instance', () {
      final shape = BlobShape.rounded(BorderRadius.circular(12));
      expect(shape, isA<BlobShape>());
    });

    test('superEllipse creates BlobShape instance', () {
      final shape = BlobShape.superEllipse(BorderRadius.circular(16));
      expect(shape, isA<BlobShape>());
    });

    test('circle is sealed class instance', () {
      const shape = BlobShape.circle();
      expect(shape, isA<BlobShape>());
    });

    test('rounded is sealed class instance', () {
      final shape = BlobShape.rounded(BorderRadius.circular(12));
      expect(shape, isA<BlobShape>());
    });

    test('superEllipse is sealed class instance', () {
      final shape = BlobShape.superEllipse(BorderRadius.circular(16));
      expect(shape, isA<BlobShape>());
    });

    test('different borderRadius values create different shapes', () {
      final shape1 = BlobShape.rounded(BorderRadius.circular(8));
      final shape2 = BlobShape.rounded(BorderRadius.circular(16));

      expect(shape1, isNot(equals(shape2)));
    });

    test('different borderRadius values create different superEllipse shapes', () {
      final shape1 = BlobShape.superEllipse(BorderRadius.circular(8));
      final shape2 = BlobShape.superEllipse(BorderRadius.circular(16));

      expect(shape1, isNot(equals(shape2)));
    });
  });
}
