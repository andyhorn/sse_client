import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sse_client/src/core/core.dart';

/// The MIME type of the data.
enum _MimeType {
  json('application/json; charset=utf-8'),
  text('text/plain; charset=utf-8');

  final String value;
  const _MimeType(this.value);
}

/// A client for Server-Sent Events (SSE).
class SseClient {
  final http.Client _client;

  /// Creates a new [SseClient].
  SseClient([http.Client? client]) : _client = client ?? http.Client();

  /// Connects to the SSE endpoint and yields SseEvents.
  ///
  /// [uri] The URI of the SSE endpoint.
  /// [method] The HTTP method to use.
  /// [headers] The headers to send with the request.
  /// [body] The body to send with the request.
  ///
  /// Returns a stream of [SseEvent] objects.
  /// Throws an [Exception] if the request fails.
  /// Throws a [http.ClientException] if the response is not successful.
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  }) async* {
    try {
      final request = http.Request(method, uri);

      if (headers != null) {
        request.headers.addAll(headers);
      }

      if (body != null && _methodSupportsBody(method)) {
        if (body is Map || body is List) {
          request.headers['Content-Type'] = _MimeType.json.value;
          request.body = jsonEncode(body);
        } else {
          request.body = '$body';
          request.headers['Content-Type'] = _MimeType.text.value;
        }
      }

      final response = await _client.send(request);

      if (!_isSuccess(response.statusCode)) {
        throw http.ClientException(
          'Failed to connect: ${response.statusCode} ${response.reasonPhrase}',
          uri,
        );
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const SseEventTransformer());

      yield* stream;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  bool _methodSupportsBody(String method) {
    const methods = {'POST', 'PUT', 'PATCH'};
    return methods.contains(method.toUpperCase());
  }

  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
