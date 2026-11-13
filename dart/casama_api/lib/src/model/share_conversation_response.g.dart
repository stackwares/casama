// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_conversation_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShareConversationResponseCWProxy {
  ShareConversationResponse url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShareConversationResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShareConversationResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ShareConversationResponse call({String? url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfShareConversationResponse.copyWith(...)` or call `instanceOfShareConversationResponse.copyWith.fieldName(value)` for a single field.
class _$ShareConversationResponseCWProxyImpl
    implements _$ShareConversationResponseCWProxy {
  const _$ShareConversationResponseCWProxyImpl(this._value);

  final ShareConversationResponse _value;

  @override
  ShareConversationResponse url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShareConversationResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShareConversationResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ShareConversationResponse call({Object? url = const $CopyWithPlaceholder()}) {
    return ShareConversationResponse(
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $ShareConversationResponseCopyWith on ShareConversationResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfShareConversationResponse.copyWith(...)` or `instanceOfShareConversationResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShareConversationResponseCWProxy get copyWith =>
      _$ShareConversationResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareConversationResponse _$ShareConversationResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShareConversationResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['url']);
  final val = ShareConversationResponse(
    url: $checkedConvert('url', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$ShareConversationResponseToJson(
  ShareConversationResponse instance,
) => <String, dynamic>{'url': instance.url};
