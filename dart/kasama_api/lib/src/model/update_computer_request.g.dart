// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_computer_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateComputerRequestCWProxy {
  UpdateComputerRequest name(String? name);

  UpdateComputerRequest profile(UpdateComputerRequestProfileEnum? profile);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateComputerRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdateComputerRequest call({
    String? name,
    UpdateComputerRequestProfileEnum? profile,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpdateComputerRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpdateComputerRequest.copyWith.fieldName(...)`
class _$UpdateComputerRequestCWProxyImpl
    implements _$UpdateComputerRequestCWProxy {
  const _$UpdateComputerRequestCWProxyImpl(this._value);

  final UpdateComputerRequest _value;

  @override
  UpdateComputerRequest name(String? name) => this(name: name);

  @override
  UpdateComputerRequest profile(UpdateComputerRequestProfileEnum? profile) =>
      this(profile: profile);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateComputerRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ````
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
  /// Returns a callable class that can be used as follows: `instanceOfUpdateComputerRequest.copyWith(...)` or like so:`instanceOfUpdateComputerRequest.copyWith.fieldName(...)`.
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
