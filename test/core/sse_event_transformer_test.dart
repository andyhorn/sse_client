import 'dart:async';

import 'package:sse_client/sse_client.dart';
import 'package:test/test.dart';

void main() {
  group('SseEventTransformer', () {
    late SseEventTransformer transformer;

    setUp(() {
      transformer = const SseEventTransformer();
    });

    test('transforms simple data event', () async {
      final stream = Stream.fromIterable(['data: hello', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals('hello'));
      expect(events[0].id, isNull);
      expect(events[0].event, isNull);
      expect(events[0].retry, isNull);
    });

    test('transforms event with all fields', () async {
      final stream = Stream.fromIterable([
        'id: 123',
        'event: message',
        'data: hello world',
        'retry: 5000',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].id, equals('123'));
      expect(events[0].event, equals('message'));
      expect(events[0].data, equals('hello world'));
      expect(events[0].retry, equals(5000));
    });

    test('joins multiple data fields with newline', () async {
      final stream = Stream.fromIterable([
        'data: line1',
        'data: line2',
        'data: line3',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals('line1\nline2\nline3'));
    });

    test('ignores comment lines', () async {
      final stream = Stream.fromIterable([
        ': this is a comment',
        'data: hello',
        ': another comment',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals('hello'));
    });

    test('handles field without value', () async {
      final stream = Stream.fromIterable(['data', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals(''));
    });

    test('handles field with whitespace-only value', () async {
      final stream = Stream.fromIterable(['data:   ', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals('  '));
    });

    test('does not dispatch event without data', () async {
      final stream = Stream.fromIterable(['id: 123', 'event: test', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, isEmpty);
    });

    test('handles multiple events in sequence', () async {
      final stream = Stream.fromIterable([
        'data: event1',
        '',
        'data: event2',
        '',
        'data: event3',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(3));
      expect(events[0].data, equals('event1'));
      expect(events[1].data, equals('event2'));
      expect(events[2].data, equals('event3'));
    });

    test('resets event type and data between events', () async {
      final stream = Stream.fromIterable([
        'event: type1',
        'data: data1',
        '',
        'event: type2',
        'data: data2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].event, equals('type1'));
      expect(events[0].data, equals('data1'));
      expect(events[1].event, equals('type2'));
      expect(events[1].data, equals('data2'));
    });

    test('persists id across events', () async {
      final stream = Stream.fromIterable([
        'id: 123',
        'data: event1',
        '',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].id, equals('123'));
      expect(events[1].id, equals('123')); // Persisted
    });

    test('persists retry across events', () async {
      final stream = Stream.fromIterable([
        'retry: 5000',
        'data: event1',
        '',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].retry, equals(5000));
      expect(events[1].retry, equals(5000)); // Persisted
    });

    test('updates id in subsequent events', () async {
      final stream = Stream.fromIterable([
        'id: 123',
        'data: event1',
        '',
        'id: 456',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].id, equals('123'));
      expect(events[1].id, equals('456')); // Updated
    });

    test('ignores id with null indicator', () async {
      final stream = Stream.fromIterable([
        'id: 123',
        'data: event1',
        '',
        'id: \u0000',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].id, equals('123'));
      expect(events[1].id, equals('123')); // Still previous value
    });

    test('ignores negative retry values', () async {
      final stream = Stream.fromIterable([
        'retry: 5000',
        'data: event1',
        '',
        'retry: -1000',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].retry, equals(5000));
      expect(events[1].retry, equals(5000)); // Still previous value
    });

    test('ignores invalid retry values', () async {
      final stream = Stream.fromIterable([
        'retry: 5000',
        'data: event1',
        '',
        'retry: invalid',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].retry, equals(5000));
      expect(events[1].retry, equals(5000)); // Still previous value
    });

    test('accepts retry value of zero', () async {
      final stream = Stream.fromIterable(['retry: 0', 'data: event1', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].retry, equals(0));
    });

    test('handles empty stream', () async {
      final stream = Stream<String>.empty();
      final events = await transformer.bind(stream).toList();

      expect(events, isEmpty);
    });

    test('handles stream with only comments', () async {
      final stream = Stream.fromIterable([
        ': comment1',
        ': comment2',
        ': comment3',
      ]);
      final events = await transformer.bind(stream).toList();

      expect(events, isEmpty);
    });

    test('handles stream with only empty lines', () async {
      final stream = Stream.fromIterable(['', '', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, isEmpty);
    });

    test('handles field with leading space after colon', () async {
      final stream = Stream.fromIterable(['data:  hello', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals(' hello'));
    });

    test('handles event with trailing newline in data', () async {
      final stream = Stream.fromIterable(['data: hello', 'data:', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      // According to SSE spec, trailing newlines are removed
      expect(events[0].data, equals('hello'));
    });

    test('removes multiple trailing newlines from data', () async {
      final stream = Stream.fromIterable(['data: line1', 'data:', 'data:', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      // Multiple trailing newlines should all be removed
      expect(events[0].data, equals('line1'));
    });

    test('handles unknown fields', () async {
      final stream = Stream.fromIterable(['unknown: value', 'data: hello', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      expect(events[0].data, equals('hello'));
    });

    test('handles multiple empty lines between events', () async {
      final stream = Stream.fromIterable([
        'data: event1',
        '',
        '',
        '',
        'data: event2',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].data, equals('event1'));
      expect(events[1].data, equals('event2'));
    });

    test('propagates errors from source stream', () async {
      final error = Exception('Test error');
      final stream = Stream<String>.error(error);

      expect(transformer.bind(stream).toList(), throwsA(isA<Exception>()));
    });

    test('handles complex real-world SSE format', () async {
      final stream = Stream.fromIterable([
        ': ping',
        'id: 12345',
        'event: message',
        'data: {"type":"greeting"}',
        'data: {"text":"hello"}',
        'retry: 3000',
        '',
        'data: another event',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(2));
      expect(events[0].id, equals('12345'));
      expect(events[0].event, equals('message'));
      expect(events[0].data, equals('{"type":"greeting"}\n{"text":"hello"}'));
      expect(events[0].retry, equals(3000));
      expect(events[1].data, equals('another event'));
      expect(events[1].id, equals('12345')); // Persisted
      expect(events[1].retry, equals(3000)); // Persisted
    });

    test('handles event with colon in data value', () async {
      final stream = Stream.fromIterable(['data: time: 12:34:56', '']);
      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      // First space after colon is removed, but colons in value are preserved
      expect(events[0].data, equals('time: 12:34:56'));
    });

    test('handles multiple colons in data value', () async {
      final stream = Stream.fromIterable([
        'data: http://example.com:8080/path',
        '',
      ]);

      final events = await transformer.bind(stream).toList();

      expect(events, hasLength(1));
      // First space after colon is removed, but URL with multiple colons is preserved
      expect(events[0].data, equals('http://example.com:8080/path'));
    });

    test('handles field name with leading/trailing whitespace', () async {
      final stream = Stream.fromIterable([' data: hello', '']);
      final events = await transformer.bind(stream).toList();

      // The field name is " data" (with leading space), not "data", so it's treated as unknown
      expect(events, isEmpty);
    });
  });
}
