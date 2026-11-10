//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}} (D-102)
enum SecretKind {
          /// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}} (D-102)
      @JsonValue(r'value')
      plain(r'value'),
          /// value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}} (D-102)
      @JsonValue(r'totp')
      totp(r'totp');

  const SecretKind(this.value);

  final String value;

  @override
  String toString() => value;
}
