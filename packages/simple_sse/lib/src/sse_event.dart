/// Model representing a Server-Sent Event (SSE).
class SseEvent {
  /// The event ID.
  final String? id;

  /// The event type.
  final String? event;

  /// The event data.
  final String data;

  /// The retry time in milliseconds (optional).
  final int? retry;

  /// Creates a new [SseEvent].
  /// [id] The event ID.
  /// [event] The event type.
  /// [data] The event data.
  /// [retry] The retry time in milliseconds (optional).
  SseEvent({this.id, this.event, required this.data, this.retry});

  @override
  String toString() {
    return 'SseEvent(id: $id, event: $event, data: $data, retry: $retry)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SseEvent &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          id == other.id &&
          event == other.event &&
          retry == other.retry;

  @override
  int get hashCode => Object.hash(data, id, event, retry);
}
