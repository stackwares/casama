// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_computer_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateComputerRequestCWProxy {
  UpdateComputerRequest name(String? name);

  UpdateComputerRequest profile(UpdateComputerRequestProfileEnum? profile);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateComputerRequest call({
    String? name,
    UpdateComputerRequestProfileEnum? profile,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateComputerRequest.copyWith(...)` or call `instanceOfUpdateComputerRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateComputerRequestCWProxyImpl
    implements _$UpdateComputerRequestCWProxy {
  const _$UpdateComputerRequestCWProxyImpl(this._value);

  final UpdateComputerRequest _value;

  @override
  UpdateComputerRequest name(String? name) => call(name: name);

  @override
  UpdateComputerRequest profile(UpdateComputerRequestProfileEnum? profile) =>
      call(profile: profile);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateComputerRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
  }) {
    return UpdateComputerRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      profile: profile == const $CopyWithPlaceholder()
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as UpdateComputerRequestProfileEnum?,
    );
  }
}

extension $UpdateComputerRequestCopyWith on UpdateComputerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateComputerRequest.copyWith(...)` or `instanceOfUpdateComputerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateComputerRequestCWProxy get copyWith =>
      _$UpdateComputerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateComputerRequest _$UpdateComputerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateComputerRequest', json, ($checkedConvert) {
  final val = UpdateComputerRequest(
    name: $checkedConvert('name', (v) => v as String?),
    profile: $checkedConvert(
      'profile',
      (v) => $enumDecodeNullable(_$UpdateComputerRequestProfileEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$UpdateComputerRequestToJson(
  UpdateComputerRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'profile': ?_$UpdateComputerRequestProfileEnumEnumMap[instance.profile],
};

const _$UpdateComputerRequestProfileEnumEnumMap = {
  UpdateComputerRequestProfileEnum.headless: 'headless',
  UpdateComputerRequestProfileEnum.desktop: 'desktop',
};
