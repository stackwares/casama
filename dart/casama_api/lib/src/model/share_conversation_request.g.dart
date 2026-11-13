// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_conversation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShareConversationRequestCWProxy {
  ShareConversationRequest public(bool public);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShareConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShareConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ShareConversationRequest call({bool public});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfShareConversationRequest.copyWith(...)` or call `instanceOfShareConversationRequest.copyWith.fieldName(value)` for a single field.
class _$ShareConversationRequestCWProxyImpl
    implements _$ShareConversationRequestCWProxy {
  const _$ShareConversationRequestCWProxyImpl(this._value);

  final ShareConversationRequest _value;

  @override
  ShareConversationRequest public(bool public) => call(public: public);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShareConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShareConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ShareConversationRequest call({
    Object? public = const $CopyWithPlaceholder(),
  }) {
    return ShareConversationRequest(
      public: public == const $CopyWithPlaceholder() || public == null
          ? _value.public
          // ignore: cast_nullable_to_non_nullable
          : public as bool,
    );
  }
}

extension $ShareConversationRequestCopyWith on ShareConversationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfShareConversationRequest.copyWith(...)` or `instanceOfShareConversationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShareConversationRequestCWProxy get copyWith =>
      _$ShareConversationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareConversationRequest _$ShareConversationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShareConversationRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['public']);
  final val = ShareConversationRequest(
    public: $checkedConvert('public', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$ShareConversationRequestToJson(
  ShareConversationRequest instance,
) => <String, dynamic>{'public': instance.public};
