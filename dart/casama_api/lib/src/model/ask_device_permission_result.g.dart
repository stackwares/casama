// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_device_permission_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AskDevicePermissionResultCWProxy {
  AskDevicePermissionResult via(AskDevicePermissionResultViaEnum via);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AskDevicePermissionResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AskDevicePermissionResult(...).copyWith(id: 12, name: "My name")
  /// ```
  AskDevicePermissionResult call({AskDevicePermissionResultViaEnum via});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAskDevicePermissionResult.copyWith(...)` or call `instanceOfAskDevicePermissionResult.copyWith.fieldName(value)` for a single field.
class _$AskDevicePermissionResultCWProxyImpl
    implements _$AskDevicePermissionResultCWProxy {
  const _$AskDevicePermissionResultCWProxyImpl(this._value);

  final AskDevicePermissionResult _value;

  @override
  AskDevicePermissionResult via(AskDevicePermissionResultViaEnum via) =>
      call(via: via);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AskDevicePermissionResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AskDevicePermissionResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AskDevicePermissionResult call({Object? via = const $CopyWithPlaceholder()}) {
    return AskDevicePermissionResult(
      via: via == const $CopyWithPlaceholder() || via == null
          ? _value.via
          // ignore: cast_nullable_to_non_nullable
          : via as AskDevicePermissionResultViaEnum,
    );
  }
}

extension $AskDevicePermissionResultCopyWith on AskDevicePermissionResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAskDevicePermissionResult.copyWith(...)` or `instanceOfAskDevicePermissionResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AskDevicePermissionResultCWProxy get copyWith =>
      _$AskDevicePermissionResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AskDevicePermissionResult _$AskDevicePermissionResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AskDevicePermissionResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['via']);
  final val = AskDevicePermissionResult(
    via: $checkedConvert(
      'via',
      (v) => $enumDecode(_$AskDevicePermissionResultViaEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$AskDevicePermissionResultToJson(
  AskDevicePermissionResult instance,
) => <String, dynamic>{
  'via': _$AskDevicePermissionResultViaEnumEnumMap[instance.via]!,
};

const _$AskDevicePermissionResultViaEnumEnumMap = {
  AskDevicePermissionResultViaEnum.socket: 'socket',
  AskDevicePermissionResultViaEnum.notification: 'notification',
};
