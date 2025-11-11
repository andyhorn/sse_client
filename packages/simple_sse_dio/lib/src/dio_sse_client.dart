import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:simple_sse/simple_sse.dart';

/// An implementation of the `SseClient` interface using the `dio` package.
class DioSseClient implements SseClient {
  final Dio _dio;

  /// Creates a new [DioSseClient].
  ///
  /// [dio] The Dio client to use. Defaults to [Dio].
  DioSseClient([Dio? dio]) : _dio = dio ?? Dio();

  @override
  Stream<SseEvent> connect(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  }) async* {
    final response = await _dio.request(
      uri.toString(),
      options: Options(
        method: method,
        headers: headers,
        responseType: ResponseType.stream,
      ),
      data: _methodSupportsBody(method) ? body : null,
    );

    if (!_isSuccessStatusCode(response.statusCode ?? 0)) {
      final Response(:statusCode, :statusMessage) = response;

      throw DioException(
        requestOptions: RequestOptions(
          path: uri.toString(),
          method: method,
          headers: headers,
          responseType: ResponseType.stream,
          data: _methodSupportsBody(method) ? body : null,
        ),
        response: response,
        error: 'Failed to connect: $statusCode ${statusMessage ?? ''}'.trim(),
      );
    }

    final stream = (response.data as ResponseBody).stream
        .map(utf8.decode)
        .transform(const LineSplitter())
        .transform(const SseEventTransformer());

    yield* stream;
  }

  bool _methodSupportsBody(String method) {
    const methods = {'POST', 'PUT', 'PATCH'};
    return methods.contains(method.toUpperCase());
  }

  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
