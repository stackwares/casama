// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_fact_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateUserFactRequestCWProxy {
  UpdateUserFactRequest content(String? content);

  UpdateUserFactRequest pinned(bool? pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateUserFactRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateUserFactRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateUserFactRequest call({String? content, bool? pinned});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateUserFactRequest.copyWith(...)` or call `instanceOfUpdateUserFactRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateUserFactRequestCWProxyImpl
    implements _$UpdateUserFactRequestCWProxy {
  const _$UpdateUserFactRequestCWProxyImpl(this._value);

  final UpdateUserFactRequest _value;

  @override
  UpdateUserFactRequest content(String? content) => call(content: content);

  @override
  UpdateUserFactRequest pinned(bool? pinned) => call(pinned: pinned);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateUserFactRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateUserFactRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateUserFactRequest call({
    Object? content = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
  }) {
    return UpdateUserFactRequest(
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String?,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool?,
    );
  }
}

extension $UpdateUserFactRequestCopyWith on UpdateUserFactRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateUserFactRequest.copyWith(...)` or `instanceOfUpdateUserFactRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateUserFactRequestCWProxy get copyWith =>
      _$UpdateUserFactRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserFactRequest _$UpdateUserFactRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateUserFactRequest', json, ($checkedConvert) {
  final val = UpdateUserFactRequest(
    content: $checkedConvert('content', (v) => v as String?),
    pinned: $checkedConvert('pinned', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$UpdateUserFactRequestToJson(
  UpdateUserFactRequest instance,
) => <String, dynamic>{
  'content': ?instance.content,
  'pinned': ?instance.pinned,
};
