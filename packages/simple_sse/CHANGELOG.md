## 2.0.0

**Breaking**

Removed the `SseClient` implementation and replaced it with an interface. 

Create your own client or use the `simple_sse_http` or `simple_sse_dio` package for an implementation using your chosen transport (`http` or `dio`, respectively).

## 1.0.1

Fix repository URL in pubspec

## 1.0.0

Initial version with fully implemented event transformer and client.
