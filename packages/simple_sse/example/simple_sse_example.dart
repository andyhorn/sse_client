import 'package:simple_sse/simple_sse.dart';

void main() async {
  final sseStream = Stream.fromIterable([
    'id: 1',
    'event: test',
    'data: hello',
    'retry: 1000',
    '',
    'id: 2',
    'event: test2',
    'data: world',
    'retry: 2000',
    '',
  ]);

  final events = await sseStream
      .transform(const SseEventTransformer())
      .toList();

  for (final event in events) {
    print('Event: $event');
  }
}
