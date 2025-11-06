import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sse_client/sse_client.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient httpClient;
  late SseClient sseClient;

  setUp(() {
    httpClient = _MockHttpClient();
    sseClient = SseClient(httpClient);
  });

  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://example.com')));
  });

  group('SseClient', () {
    test('connect yields events on 200 OK', () async {
      // Arrange
      final sseText = 'data: {"message":"hello"}\n\n';
      final stream = Stream.fromIterable([utf8.encode(sseText)]);
      final response = http.StreamedResponse(stream, 200, reasonPhrase: 'OK');

      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, isNotEmpty);
    });

    test('connect throws an exception for non-success status', () async {
      // Arrange
      final response = http.StreamedResponse(
        Stream.fromIterable([]),
        404,
        reasonPhrase: 'Not Found',
      );

      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<Exception>()),
      );
    });

    test('connect throws an exception on request failure', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<Exception>()),
      );
    });

    test('adds headers to the request', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

      final uri = Uri.parse('http://example.com');
      final headers = {'Authorization': 'Bearer token'};

      // Act
      await sseClient.connect(uri, headers: headers).drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(req.headers['Authorization'], equals('Bearer token'));
    });

    test('doesn\'t set headers when none are provided', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri).drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(req.headers.isEmpty, isTrue);
    });

    test('uses provided HTTP method', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri, method: 'POST').drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(req.method, equals('POST'));
    });

    test('uses GET method by default', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri).drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(req.method, equals('GET'));
    });

    test('sends JSON body and sets Content-Type when body is a Map', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));
      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri, method: 'POST', body: {'a': 1}).drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(
        req.headers['Content-Type'],
        equals('application/json; charset=utf-8'),
      );
      expect(req.body, equals(jsonEncode({'a': 1})));
    });

    test('sends JSON body and sets Content-Type when body is a List', () async {
      // Arrange
      when(
        () => httpClient.send(any<http.Request>()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));
      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri, method: 'POST', body: [1, 2, 3]).drain();

      final captured = verify(
        () => httpClient.send(captureAny<http.Request>()),
      ).captured;

      // Assert
      final req = captured.first as http.Request;
      expect(
        req.headers['Content-Type'],
        equals('application/json; charset=utf-8'),
      );
      expect(req.body, equals(jsonEncode([1, 2, 3])));
    });

    test(
      'sends plain text body and sets Content-Type when body is String',
      () async {
        // Arrange
        when(
          () => httpClient.send(any<http.Request>()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));
        final uri = Uri.parse('http://example.com');

        // Act
        await sseClient
            .connect(uri, method: 'POST', body: 'Hello World')
            .drain();

        final captured = verify(
          () => httpClient.send(captureAny<http.Request>()),
        ).captured;

        // Assert
        final req = captured.first as http.Request;
        expect(
          req.headers['Content-Type'],
          equals('text/plain; charset=utf-8'),
        );
        expect(req.body, equals('Hello World'));
      },
    );
  });
}
