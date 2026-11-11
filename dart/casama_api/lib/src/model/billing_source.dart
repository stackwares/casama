//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum BillingSource {
      @JsonValue(r'dodo')
      dodo(r'dodo'),
      @JsonValue(r'app_store')
      appStore(r'app_store'),
      @JsonValue(r'google_play')
      googlePlay(r'google_play');

  const BillingSource(this.value);

  final String value;

  @override
  String toString() => value;
}
