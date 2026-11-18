// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_page_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePageRequestCWProxy {
  UpdatePageRequest visibility(UpdatePageRequestVisibilityEnum visibility);

  UpdatePageRequest expiresInDays(int? expiresInDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePageRequest call({
    UpdatePageRequestVisibilityEnum visibility,
    int? expiresInDays,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePageRequest.copyWith(...)` or call `instanceOfUpdatePageRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePageRequestCWProxyImpl implements _$UpdatePageRequestCWProxy {
  const _$UpdatePageRequestCWProxyImpl(this._value);

  final UpdatePageRequest _value;

  @override
  UpdatePageRequest visibility(UpdatePageRequestVisibilityEnum visibility) =>
      call(visibility: visibility);

  @override
  UpdatePageRequest expiresInDays(int? expiresInDays) =>
      call(expiresInDays: expiresInDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePageRequest call({
    Object? visibility = const $CopyWithPlaceholder(),
    Object? expiresInDays = const $CopyWithPlaceholder(),
  }) {
    return UpdatePageRequest(
      visibility:
          visibility == const $CopyWithPlaceholder() || visibility == null
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as UpdatePageRequestVisibilityEnum,
      expiresInDays: expiresInDays == const $CopyWithPlaceholder()
          ? _value.expiresInDays
          // ignore: cast_nullable_to_non_nullable
          : expiresInDays as int?,
    );
  }
}

extension $UpdatePageRequestCopyWith on UpdatePageRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePageRequest.copyWith(...)` or `instanceOfUpdatePageRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePageRequestCWProxy get copyWith =>
      _$UpdatePageRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePageRequest _$UpdatePageRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdatePageRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['visibility']);
      final val = UpdatePageRequest(
        visibility: $checkedConvert(
          'visibility',
          (v) => $enumDecode(_$UpdatePageRequestVisibilityEnumEnumMap, v),
        ),
        expiresInDays: $checkedConvert(
          'expires_in_days',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresInDays': 'expires_in_days'});

Map<String, dynamic> _$UpdatePageRequestToJson(
  UpdatePageRequest instance,
) => <String, dynamic>{
  'visibility': _$UpdatePageRequestVisibilityEnumEnumMap[instance.visibility]!,
  'expires_in_days': ?instance.expiresInDays,
};

const _$UpdatePageRequestVisibilityEnumEnumMap = {
  UpdatePageRequestVisibilityEnum.private: 'private',
  UpdatePageRequestVisibilityEnum.workspace: 'workspace',
  UpdatePageRequestVisibilityEnum.public: 'public',
};
