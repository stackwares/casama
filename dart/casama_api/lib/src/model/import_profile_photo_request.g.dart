// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_profile_photo_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportProfilePhotoRequestCWProxy {
  ImportProfilePhotoRequest replace(bool? replace);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportProfilePhotoRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportProfilePhotoRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportProfilePhotoRequest call({bool? replace});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportProfilePhotoRequest.copyWith(...)` or call `instanceOfImportProfilePhotoRequest.copyWith.fieldName(value)` for a single field.
class _$ImportProfilePhotoRequestCWProxyImpl
    implements _$ImportProfilePhotoRequestCWProxy {
  const _$ImportProfilePhotoRequestCWProxyImpl(this._value);

  final ImportProfilePhotoRequest _value;

  @override
  ImportProfilePhotoRequest replace(bool? replace) => call(replace: replace);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportProfilePhotoRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportProfilePhotoRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportProfilePhotoRequest call({
    Object? replace = const $CopyWithPlaceholder(),
  }) {
    return ImportProfilePhotoRequest(
      replace: replace == const $CopyWithPlaceholder()
          ? _value.replace
          // ignore: cast_nullable_to_non_nullable
          : replace as bool?,
    );
  }
}

extension $ImportProfilePhotoRequestCopyWith on ImportProfilePhotoRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportProfilePhotoRequest.copyWith(...)` or `instanceOfImportProfilePhotoRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportProfilePhotoRequestCWProxy get copyWith =>
      _$ImportProfilePhotoRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportProfilePhotoRequest _$ImportProfilePhotoRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ImportProfilePhotoRequest', json, ($checkedConvert) {
  final val = ImportProfilePhotoRequest(
    replace: $checkedConvert('replace', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$ImportProfilePhotoRequestToJson(
  ImportProfilePhotoRequest instance,
) => <String, dynamic>{'replace': ?instance.replace};
