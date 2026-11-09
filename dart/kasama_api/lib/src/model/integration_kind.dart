//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum IntegrationKind {
      @JsonValue(r'mcp')
      mcp(r'mcp'),
      @JsonValue(r'openapi')
      openapi(r'openapi'),
      @JsonValue(r'composio')
      composio(r'composio'),
      @JsonValue(r'pipedream')
      pipedream(r'pipedream');

  const IntegrationKind(this.value);

  final String value;

  @override
  String toString() => value;
}
