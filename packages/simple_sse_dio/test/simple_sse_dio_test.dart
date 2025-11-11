import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_sse_dio/simple_sse_dio.dart';
import 'package:test/test.dart';

class _MockDio extends Mock implements Dio {}

class _MockResponseBody extends Mock implements ResponseBody {}

void main() {
  late _MockDio mockDio;
  late DioSseClient sseClient;

  setUp(() {
    mockDio = _MockDio();
    sseClient = DioSseClient(mockDio);
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('DioSseClient', () {
    test('connect yields events on 200 OK', () async {
      // Arrange
      final sseText = 'data: {"message":"hello"}\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, isNotEmpty);
      expect(events.first.data, equals('{"message":"hello"}'));
    });

    test('connect yields multiple events', () async {
      // Arrange
      final sseText = 'data: event1\n\ndata: event2\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, hasLength(2));
      expect(events[0].data, equals('event1'));
      expect(events[1].data, equals('event2'));
    });

    test('connect yields events with all fields', () async {
      // Arrange
      final sseText =
          'id: 123\nevent: message\ndata: hello world\nretry: 5000\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, hasLength(1));
      expect(events[0].id, equals('123'));
      expect(events[0].event, equals('message'));
      expect(events[0].data, equals('hello world'));
      expect(events[0].retry, equals(5000));
    });

    test('connect throws DioException for non-success status', () async {
      // Arrange
      final responseBody = _MockResponseBody();
      when(
        () => responseBody.stream,
      ).thenAnswer((_) => Stream.fromIterable([]));

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 404,
        statusMessage: 'Not Found',
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<DioException>()),
      );
    });

    test('connect throws DioException for 500 status', () async {
      // Arrange
      final responseBody = _MockResponseBody();
      when(
        () => responseBody.stream,
      ).thenAnswer((_) => Stream.fromIterable([]));

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 500,
        statusMessage: 'Internal Server Error',
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<DioException>()),
      );
    });

    test('connect throws DioException for 300 status', () async {
      // Arrange
      final responseBody = _MockResponseBody();
      when(
        () => responseBody.stream,
      ).thenAnswer((_) => Stream.fromIterable([]));

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 300,
        statusMessage: 'Multiple Choices',
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<DioException>()),
      );
    });

    test('connect accepts 200 status', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, isNotEmpty);
    });

    test('connect accepts 299 status', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 299,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, isNotEmpty);
    });

    test('connect throws DioException when request fails', () async {
      // Arrange
      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'http://example.com'),
          error: 'Network error',
        ),
      );

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<DioException>()),
      );
    });

    test('connect throws DioException when statusCode is null', () async {
      // Arrange
      final responseBody = _MockResponseBody();
      when(
        () => responseBody.stream,
      ).thenAnswer((_) => Stream.fromIterable([]));

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: null,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).first,
        throwsA(isA<DioException>()),
      );
    });

    test('adds headers to the request', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final headers = {'Authorization': 'Bearer token'};

      // Act
      await sseClient.connect(uri, headers: headers).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: captureAny(named: 'options'),
          data: any(named: 'data'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.headers?['Authorization'], equals('Bearer token'));
    });

    test('doesn\'t set headers when none are provided', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: captureAny(named: 'options'),
          data: any(named: 'data'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.headers, isNull);
    });

    test('uses provided HTTP method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri, method: 'POST').drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: captureAny(named: 'options'),
          data: any(named: 'data'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.method, equals('POST'));
    });

    test('uses GET method by default', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');

      // Act
      await sseClient.connect(uri).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: captureAny(named: 'options'),
          data: any(named: 'data'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.method, equals('GET'));
    });

    test('sends body for POST method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = {'a': 1};

      // Act
      await sseClient.connect(uri, method: 'POST', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured.first, equals(body));
    });

    test('sends body for PUT method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = {'key': 'value'};

      // Act
      await sseClient.connect(uri, method: 'PUT', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured.first, equals(body));
    });

    test('sends body for PATCH method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = 'patch data';

      // Act
      await sseClient.connect(uri, method: 'PATCH', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured.first, equals(body));
    });

    test('doesn\'t send body for GET method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = {'should': 'not be sent'};

      // Act
      await sseClient.connect(uri, method: 'GET', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured.first, isNull);
    });

    test('doesn\'t send body for DELETE method', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = {'should': 'not be sent'};

      // Act
      await sseClient.connect(uri, method: 'DELETE', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      expect(captured.first, isNull);
    });

    test('handles case-insensitive method names', () async {
      // Arrange
      final sseText = 'data: hello\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final uri = Uri.parse('http://example.com');
      final body = {'test': 'data'};

      // Act - lowercase method
      await sseClient.connect(uri, method: 'post', body: body).drain();

      // Assert
      final captured = verify(
        () => mockDio.request(
          any(),
          options: captureAny(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.method, equals('post'));
      // Body should still be sent because 'post' (uppercase) is in the allowed methods
      expect(captured[1], equals(body));
    });

    test('handles empty stream', () async {
      // Arrange
      final stream = Stream<Uint8List>.empty();
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, isEmpty);
    });

    test('handles stream errors', () async {
      // Arrange
      final error = Exception('Stream error');
      final stream = Stream<Uint8List>.error(error);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => sseClient.connect(Uri.parse('http://example.com')).toList(),
        throwsA(isA<Exception>()),
      );
    });

    test('creates default Dio instance when none provided', () {
      // Act
      final client = DioSseClient();

      // Assert
      expect(client, isA<DioSseClient>());
    });

    test('uses provided Dio instance', () {
      // Arrange
      final customDio = Dio();

      // Act
      final client = DioSseClient(customDio);

      // Assert
      expect(client, isA<DioSseClient>());
    });

    test('handles multiple data lines in single event', () async {
      // Arrange
      final sseText = 'data: line1\ndata: line2\ndata: line3\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, hasLength(1));
      expect(events[0].data, equals('line1\nline2\nline3'));
    });

    test('handles complex SSE format with comments', () async {
      // Arrange
      final sseText =
          ': ping\nid: 12345\nevent: message\ndata: {"type":"greeting"}\nretry: 3000\n\n';
      final stream = Stream.fromIterable([
        Uint8List.fromList(utf8.encode(sseText)),
      ]);
      final responseBody = _MockResponseBody();
      when(() => responseBody.stream).thenAnswer((_) => stream);

      final response = Response(
        requestOptions: RequestOptions(path: 'http://example.com'),
        statusCode: 200,
        data: responseBody,
      );

      when(
        () => mockDio.request(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final events = await sseClient
          .connect(Uri.parse('http://example.com'))
          .toList();

      // Assert
      expect(events, hasLength(1));
      expect(events[0].id, equals('12345'));
      expect(events[0].event, equals('message'));
      expect(events[0].data, equals('{"type":"greeting"}'));
      expect(events[0].retry, equals(3000));
    });
  });
}
