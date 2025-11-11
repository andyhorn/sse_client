import 'package:simple_sse/simple_sse.dart';

/// An interface for SSE clients.
abstract class SseClient {
  /// Connects to the SSE endpoint and yields SseEvents.
  ///
  /// [uri] The URI of the SSE endpoint.
  /// [method] The HTTP method to use.
  /// [headers] The headers to send with the request.
  /// [body] The body to send with the request.
  ///
  /// Returns a stream of [SseEvent] objects.
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  });
}
