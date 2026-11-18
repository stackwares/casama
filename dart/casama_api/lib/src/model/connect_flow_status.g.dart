// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_flow_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectFlowStatusCWProxy {
  ConnectFlowStatus status(ConnectFlowStatusStatusEnum status);

  ConnectFlowStatus integration(Integration? integration);

  ConnectFlowStatus error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectFlowStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectFlowStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectFlowStatus call({
    ConnectFlowStatusStatusEnum status,
    Integration? integration,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectFlowStatus.copyWith(...)` or call `instanceOfConnectFlowStatus.copyWith.fieldName(value)` for a single field.
class _$ConnectFlowStatusCWProxyImpl implements _$ConnectFlowStatusCWProxy {
  const _$ConnectFlowStatusCWProxyImpl(this._value);

  final ConnectFlowStatus _value;

  @override
  ConnectFlowStatus status(ConnectFlowStatusStatusEnum status) =>
      call(status: status);

  @override
  ConnectFlowStatus integration(Integration? integration) =>
      call(integration: integration);

  @override
  ConnectFlowStatus error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectFlowStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectFlowStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectFlowStatus call({
    Object? status = const $CopyWithPlaceholder(),
    Object? integration = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ConnectFlowStatus(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ConnectFlowStatusStatusEnum,
      integration: integration == const $CopyWithPlaceholder()
          ? _value.integration
          // ignore: cast_nullable_to_non_nullable
          : integration as Integration?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $ConnectFlowStatusCopyWith on ConnectFlowStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectFlowStatus.copyWith(...)` or `instanceOfConnectFlowStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectFlowStatusCWProxy get copyWith =>
      _$ConnectFlowStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectFlowStatus _$ConnectFlowStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConnectFlowStatus', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status']);
      final val = ConnectFlowStatus(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ConnectFlowStatusStatusEnumEnumMap, v),
        ),
        integration: $checkedConvert(
          'integration',
          (v) => v == null
              ? null
              : Integration.fromJson(v as Map<String, dynamic>),
        ),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ConnectFlowStatusToJson(ConnectFlowStatus instance) =>
    <String, dynamic>{
      'status': _$ConnectFlowStatusStatusEnumEnumMap[instance.status]!,
      'integration': ?instance.integration?.toJson(),
      'error': ?instance.error,
    };

const _$ConnectFlowStatusStatusEnumEnumMap = {
  ConnectFlowStatusStatusEnum.pending: 'pending',
  ConnectFlowStatusStatusEnum.connected: 'connected',
  ConnectFlowStatusStatusEnum.error: 'error',
  ConnectFlowStatusStatusEnum.expired: 'expired',
};
