import 'dart:convert';

import 'package:http/http.dart';
import 'package:simple_sse/simple_sse.dart';

/// An implementation of the `SseClient` interface using the `http` package.
class HttpSseClient implements SseClient {
  final Client _client;

  /// Creates a new [HttpSseClient].
  ///
  /// [client] The HTTP client to use. Defaults to [Client].
  HttpSseClient([Client? client]) : _client = client ?? Client();

  /// Connects to the SSE endpoint and yields SseEvents.
  ///
  /// [uri] The URI of the SSE endpoint.
  /// [method] The HTTP method to use.
  /// [headers] The headers to send with the request.
  /// [body] The body to send with the request.
  ///
  /// Returns a stream of [SseEvent] objects.
  /// Throws a [http.ClientException] if the response is not successful.
  @override
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  }) async* {
    final request = Request(method, uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (body != null && _methodSupportsBody(method)) {
      if (body is Map || body is List) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      } else {
        request.body = '$body';
        request.headers['Content-Type'] = 'text/plain; charset=utf-8';
      }
    }

    final response = await _client.send(request);

    if (!_isSuccessStatusCode(response.statusCode)) {
      final StreamedResponse(:statusCode, :reasonPhrase) = response;

      throw ClientException(
        'Failed to connect: $statusCode ${reasonPhrase ?? ''}'.trim(),
        uri,
      );
    }

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const SseEventTransformer());

    yield* stream;
  }

  bool _methodSupportsBody(String method) {
    const methods = {'POST', 'PUT', 'PATCH'};
    return methods.contains(method.toUpperCase());
  }

  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
