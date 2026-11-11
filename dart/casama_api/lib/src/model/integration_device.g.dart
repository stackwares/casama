// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_device.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationDeviceCWProxy {
  IntegrationDevice id(String id);

  IntegrationDevice computerId(String? computerId);

  IntegrationDevice ownerUserId(String ownerUserId);

  IntegrationDevice label(String label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  IntegrationDevice call({
    String id,
    String? computerId,
    String ownerUserId,
    String label,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIntegrationDevice.copyWith(...)` or call `instanceOfIntegrationDevice.copyWith.fieldName(value)` for a single field.
class _$IntegrationDeviceCWProxyImpl implements _$IntegrationDeviceCWProxy {
  const _$IntegrationDeviceCWProxyImpl(this._value);

  final IntegrationDevice _value;

  @override
  IntegrationDevice id(String id) => call(id: id);

  @override
  IntegrationDevice computerId(String? computerId) =>
      call(computerId: computerId);

  @override
  IntegrationDevice ownerUserId(String ownerUserId) =>
      call(ownerUserId: ownerUserId);

  @override
  IntegrationDevice label(String label) => call(label: label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IntegrationDevice call({
    Object? id = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? ownerUserId = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return IntegrationDevice(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String?,
      ownerUserId:
          ownerUserId == const $CopyWithPlaceholder() || ownerUserId == null
          ? _value.ownerUserId
          // ignore: cast_nullable_to_non_nullable
          : ownerUserId as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $IntegrationDeviceCopyWith on IntegrationDevice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIntegrationDevice.copyWith(...)` or `instanceOfIntegrationDevice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntegrationDeviceCWProxy get copyWith =>
      _$IntegrationDeviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationDevice _$IntegrationDeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IntegrationDevice',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'computer_id', 'owner_user_id', 'label'],
        );
        final val = IntegrationDevice(
          id: $checkedConvert('id', (v) => v as String),
          computerId: $checkedConvert('computer_id', (v) => v as String?),
          ownerUserId: $checkedConvert('owner_user_id', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'computerId': 'computer_id',
        'ownerUserId': 'owner_user_id',
      },
    );

Map<String, dynamic> _$IntegrationDeviceToJson(IntegrationDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'computer_id': instance.computerId,
      'owner_user_id': instance.ownerUserId,
      'label': instance.label,
    };
