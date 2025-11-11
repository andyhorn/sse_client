# Simple SSE HTTP

An implementation of the [`simple_sse`](https://pub.dev/packages/simple_sse) **SseClient** interface using the [`http`](https://pub.dev/packages/http) package.

## Features 

Open an SSE connection and receive a stream of `SseEvent` objects using the `simple_sse` package behind the scenes.

## Usage

Add this package to your app's dependencies:

```bash
dart pub add simple_sse_http
```

Use the `HttpSseClient` to open a connection and receive a stream of `SseEvent` objects.

```dart
final client = HttpSseClient();
final Stream<SseEvent> events = client.connect(Uri.parse('https://sse.dev/test'));

await for (final SseEvent event in events) {
    // SseEvent(id: 123, event: 'event', data: 'data', retry: 123)
    print(event.toString()); 
}
```