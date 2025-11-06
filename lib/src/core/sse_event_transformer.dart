import 'dart:async';

import 'package:sse_client/src/core/core.dart';

/// Transforms a stream of SSE lines into a stream of [SseEvent] objects.
class SseEventTransformer extends StreamTransformerBase<String, SseEvent> {
  /// Creates a new [SseEventTransformer].
  const SseEventTransformer();

  @override
  Stream<SseEvent> bind(Stream<String> stream) {
    return Stream.eventTransformed(stream, (sink) => _SseEventSink(sink));
  }
}

/// Internal sink to process SSE lines and emit SseEvent objects.
/// Each event is separated by an empty line.
/// Lines starting with ':' are comments and ignored.
/// Fields are parsed according to the SSE specification.
/// See https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
class _SseEventSink implements EventSink<String> {
  _SseEventSink(this._sink);

  static const _nullIndicator = '\u0000';
  static final _trailingNewlines = RegExp(r'\n+$');

  final EventSink<SseEvent> _sink;

  List<String> _data = [];
  String? _id;
  String? _event;
  int? _retry;

  @override
  void add(String event) {
    if (event.startsWith(':')) {
      // Comment line, ignore
      return;
    }

    if (event.isEmpty) {
      // Empty lines indicate dispatching the event
      _dispatch();

      // Reset the event and data, but persist the last event ID and retry
      _event = null;
      _data = [];
      return;
    }

    final index = event.indexOf(':');

    if (index == -1) {
      // Field with no value, use empty string as value
      _processField(event.trim(), '');
      return;
    }

    final field = event.substring(0, index);
    var value = event.substring(index + 1);

    // If value starts with a space, remove only the first space
    if (value.isNotEmpty && value[0] == ' ') {
      value = value.substring(1);
    }

    _processField(field, value);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _sink.close();
  }

  void _processField(String field, String value) {
    switch (field) {
      case 'id':
        if (!value.contains(_nullIndicator)) {
          _id = value;
        }

        break;
      case 'event':
        _event = value;
        break;
      case 'data':
        _data.add(value);
        break;
      case 'retry':
        final retry = int.tryParse(value);

        if (retry != null && retry >= 0) {
          _retry = retry;
        }

        break;
    }
  }

  void _dispatch() {
    if (_data.isNotEmpty) {
      final data = _data.join('\n').replaceAll(_trailingNewlines, '');
      final sse = SseEvent(data: data, id: _id, event: _event, retry: _retry);
      _sink.add(sse);
    }
  }
}
