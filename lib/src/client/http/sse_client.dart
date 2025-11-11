import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:simple_sse/src/core/core.dart';
import 'package:simple_sse/src/core/sse_client.dart';
import 'package:simple_sse/src/core/utils.dart';

/// The MIME type of the data.
enum _MimeType {
  json('application/json; charset=utf-8'),
  text('text/plain; charset=utf-8');

  final String value;
  const _MimeType(this.value);
}

/// A client for Server-Sent Events (SSE).
class SseClient implements ISseClient {
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
  /// Throws a [http.ClientException] if the response is not successful.
  @override
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  }) async* {
    final request = http.Request(method, uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (body != null && methodSupportsBody(method)) {
      if (body is Map || body is List) {
        request.headers['Content-Type'] = _MimeType.json.value;
        request.body = jsonEncode(body);
      } else {
        request.body = '$body';
        request.headers['Content-Type'] = _MimeType.text.value;
      }
    }

    final response = await _client.send(request);

    if (!isSuccessStatusCode(response.statusCode)) {
      final http.StreamedResponse(:statusCode, :reasonPhrase) = response;

      throw http.ClientException(
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
}
