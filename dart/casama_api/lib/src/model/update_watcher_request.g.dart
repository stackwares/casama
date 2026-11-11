// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_watcher_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateWatcherRequestCWProxy {
  UpdateWatcherRequest status(UpdateWatcherRequestStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateWatcherRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateWatcherRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateWatcherRequest call({UpdateWatcherRequestStatusEnum status});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateWatcherRequest.copyWith(...)` or call `instanceOfUpdateWatcherRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateWatcherRequestCWProxyImpl
    implements _$UpdateWatcherRequestCWProxy {
  const _$UpdateWatcherRequestCWProxyImpl(this._value);

  final UpdateWatcherRequest _value;

  @override
  UpdateWatcherRequest status(UpdateWatcherRequestStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateWatcherRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateWatcherRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateWatcherRequest call({Object? status = const $CopyWithPlaceholder()}) {
    return UpdateWatcherRequest(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UpdateWatcherRequestStatusEnum,
    );
  }
}

extension $UpdateWatcherRequestCopyWith on UpdateWatcherRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateWatcherRequest.copyWith(...)` or `instanceOfUpdateWatcherRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateWatcherRequestCWProxy get copyWith =>
      _$UpdateWatcherRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateWatcherRequest _$UpdateWatcherRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateWatcherRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = UpdateWatcherRequest(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$UpdateWatcherRequestStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$UpdateWatcherRequestToJson(
  UpdateWatcherRequest instance,
) => <String, dynamic>{
  'status': _$UpdateWatcherRequestStatusEnumEnumMap[instance.status]!,
};

const _$UpdateWatcherRequestStatusEnumEnumMap = {
  UpdateWatcherRequestStatusEnum.active: 'active',
  UpdateWatcherRequestStatusEnum.paused: 'paused',
};
