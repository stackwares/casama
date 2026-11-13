// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_conversation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateConversationRequestCWProxy {
  UpdateConversationRequest title(String? title);

  UpdateConversationRequest pinned(bool? pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateConversationRequest call({String? title, bool? pinned});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateConversationRequest.copyWith(...)` or call `instanceOfUpdateConversationRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateConversationRequestCWProxyImpl
    implements _$UpdateConversationRequestCWProxy {
  const _$UpdateConversationRequestCWProxyImpl(this._value);

  final UpdateConversationRequest _value;

  @override
  UpdateConversationRequest title(String? title) => call(title: title);

  @override
  UpdateConversationRequest pinned(bool? pinned) => call(pinned: pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateConversationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateConversationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateConversationRequest call({
    Object? title = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
  }) {
    return UpdateConversationRequest(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool?,
    );
  }
}

extension $UpdateConversationRequestCopyWith on UpdateConversationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateConversationRequest.copyWith(...)` or `instanceOfUpdateConversationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateConversationRequestCWProxy get copyWith =>
      _$UpdateConversationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateConversationRequest _$UpdateConversationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateConversationRequest', json, ($checkedConvert) {
  final val = UpdateConversationRequest(
    title: $checkedConvert('title', (v) => v as String?),
    pinned: $checkedConvert('pinned', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$UpdateConversationRequestToJson(
  UpdateConversationRequest instance,
) => <String, dynamic>{'title': ?instance.title, 'pinned': ?instance.pinned};
