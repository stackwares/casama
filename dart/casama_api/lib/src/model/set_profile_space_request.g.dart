// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_profile_space_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetProfileSpaceRequestCWProxy {
  SetProfileSpaceRequest shared(bool shared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetProfileSpaceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetProfileSpaceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetProfileSpaceRequest call({bool shared});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetProfileSpaceRequest.copyWith(...)` or call `instanceOfSetProfileSpaceRequest.copyWith.fieldName(value)` for a single field.
class _$SetProfileSpaceRequestCWProxyImpl
    implements _$SetProfileSpaceRequestCWProxy {
  const _$SetProfileSpaceRequestCWProxyImpl(this._value);

  final SetProfileSpaceRequest _value;

  @override
  SetProfileSpaceRequest shared(bool shared) => call(shared: shared);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetProfileSpaceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetProfileSpaceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetProfileSpaceRequest call({Object? shared = const $CopyWithPlaceholder()}) {
    return SetProfileSpaceRequest(
      shared: shared == const $CopyWithPlaceholder() || shared == null
          ? _value.shared
          // ignore: cast_nullable_to_non_nullable
          : shared as bool,
    );
  }
}

extension $SetProfileSpaceRequestCopyWith on SetProfileSpaceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetProfileSpaceRequest.copyWith(...)` or `instanceOfSetProfileSpaceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetProfileSpaceRequestCWProxy get copyWith =>
      _$SetProfileSpaceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetProfileSpaceRequest _$SetProfileSpaceRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetProfileSpaceRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['shared']);
  final val = SetProfileSpaceRequest(
    shared: $checkedConvert('shared', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$SetProfileSpaceRequestToJson(
  SetProfileSpaceRequest instance,
) => <String, dynamic>{'shared': instance.shared};
