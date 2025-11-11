import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:simple_sse/src/core/sse_client.dart';
import 'package:simple_sse/src/core/utils.dart';
import 'package:simple_sse/sse_core.dart';

class SseClient implements ISseClient {
  final Dio _dio;

  SseClient([Dio? dio]) : _dio = dio ?? Dio();

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
      data: methodSupportsBody(method) ? body : null,
    );

    if (!isSuccessStatusCode(response.statusCode ?? 0)) {
      final Response(:statusCode, :statusMessage) = response;

      throw DioException(
        requestOptions: RequestOptions(
          path: uri.toString(),
          method: method,
          headers: headers,
          responseType: ResponseType.stream,
          data: methodSupportsBody(method) ? body : null,
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
}
