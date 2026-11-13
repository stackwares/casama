// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_creation_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCreationRequestCWProxy {
  UpdateCreationRequest title(String? title);

  UpdateCreationRequest label(String? label);

  UpdateCreationRequest pinned(bool? pinned);

  UpdateCreationRequest opened(bool? opened);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCreationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCreationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCreationRequest call({
    String? title,
    String? label,
    bool? pinned,
    bool? opened,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCreationRequest.copyWith(...)` or call `instanceOfUpdateCreationRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateCreationRequestCWProxyImpl
    implements _$UpdateCreationRequestCWProxy {
  const _$UpdateCreationRequestCWProxyImpl(this._value);

  final UpdateCreationRequest _value;

  @override
  UpdateCreationRequest title(String? title) => call(title: title);

  @override
  UpdateCreationRequest label(String? label) => call(label: label);

  @override
  UpdateCreationRequest pinned(bool? pinned) => call(pinned: pinned);

  @override
  UpdateCreationRequest opened(bool? opened) => call(opened: opened);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCreationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCreationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCreationRequest call({
    Object? title = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
    Object? opened = const $CopyWithPlaceholder(),
  }) {
    return UpdateCreationRequest(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool?,
      opened: opened == const $CopyWithPlaceholder()
          ? _value.opened
          // ignore: cast_nullable_to_non_nullable
          : opened as bool?,
    );
  }
}

extension $UpdateCreationRequestCopyWith on UpdateCreationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCreationRequest.copyWith(...)` or `instanceOfUpdateCreationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCreationRequestCWProxy get copyWith =>
      _$UpdateCreationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCreationRequest _$UpdateCreationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateCreationRequest', json, ($checkedConvert) {
  final val = UpdateCreationRequest(
    title: $checkedConvert('title', (v) => v as String?),
    label: $checkedConvert('label', (v) => v as String?),
    pinned: $checkedConvert('pinned', (v) => v as bool?),
    opened: $checkedConvert('opened', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$UpdateCreationRequestToJson(
  UpdateCreationRequest instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'label': ?instance.label,
  'pinned': ?instance.pinned,
  'opened': ?instance.opened,
};
