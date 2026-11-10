// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_computer_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateComputerRequestCWProxy {
  UpdateComputerRequest name(String? name);

  UpdateComputerRequest profile(UpdateComputerRequestProfileEnum? profile);

  UpdateComputerRequest maxDesktops(int? maxDesktops);

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
    int? maxDesktops,
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

  @override
  UpdateComputerRequest maxDesktops(int? maxDesktops) =>
      call(maxDesktops: maxDesktops);

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
    Object? maxDesktops = const $CopyWithPlaceholder(),
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
      maxDesktops: maxDesktops == const $CopyWithPlaceholder()
          ? _value.maxDesktops
          // ignore: cast_nullable_to_non_nullable
          : maxDesktops as int?,
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
    maxDesktops: $checkedConvert('max_desktops', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'maxDesktops': 'max_desktops'});

Map<String, dynamic> _$UpdateComputerRequestToJson(
  UpdateComputerRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'profile': ?_$UpdateComputerRequestProfileEnumEnumMap[instance.profile],
  'max_desktops': ?instance.maxDesktops,
};

const _$UpdateComputerRequestProfileEnumEnumMap = {
  UpdateComputerRequestProfileEnum.headless: 'headless',
  UpdateComputerRequestProfileEnum.desktop: 'desktop',
};
