//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}}
enum SecretKind {
          /// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}}
      @JsonValue(r'value')
      plain(r'value'),
          /// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}}
      @JsonValue(r'totp')
      totp(r'totp');

  const SecretKind(this.value);

  final String value;

  @override
  String toString() => value;
}
