import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:test/test.dart';

void main() {
  DioException failed(Object? data) {
    final req = RequestOptions(path: '/v1/messages/x/speech');
    return DioException(requestOptions: req, response: Response(requestOptions: req, statusCode: 409, data: data));
  }

  const body = {'type': 'about:blank', 'title': 'Conflict', 'status': 409, 'code': 'voice_unavailable', 'detail': 'Add a voice key.'};

  test('reads problem bodies from JSON, text and byte responses', () {
    expect(problemOf(failed(body))?.detail, 'Add a voice key.');
    expect(problemOf(failed(jsonEncode(body)))?.code, 'voice_unavailable');
    expect(problemOf(failed(utf8.encode(jsonEncode(body))))?.detail, 'Add a voice key.');
    expect(problemOf(failed([0xff, 0xd8, 0x00])), isNull);
  });
}
