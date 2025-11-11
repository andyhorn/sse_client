import 'package:simple_sse/simple_sse.dart';
import 'package:simple_sse_http/simple_sse_http.dart';

void main() async {
  final client = HttpSseClient();
  final events = client.connect(Uri.parse('https://sse.dev/test'));

  await for (final SseEvent event in events) {
    print(event.toString());
  }
}
