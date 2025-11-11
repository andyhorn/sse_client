import 'package:simple_sse/sse_core.dart';

abstract class ISseClient {
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  });
}
