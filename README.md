# Simple SSE

This is the Melos workspace for the `simple_sse` package and its client implementations: `simple_sse_http` and `simple_sse_dio`.

The `simple_sse` package contains the core components, including the `SseEvent` model, the `SseEventTransformer` stream transformer, and the `SseClient` client interface.

The two client packages implement the `SseClient` interface using the `http` and `dio` transport packages, respectively.