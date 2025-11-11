import 'package:simple_sse/simple_sse.dart';
import 'package:simple_sse_dio/simple_sse_dio.dart';

void main() async {
  final client = DioSseClient();
  final events = client.connect(Uri.parse('https://sse.dev/test'));

  await for (final SseEvent event in events) {
    print(event.toString());
  }
}
