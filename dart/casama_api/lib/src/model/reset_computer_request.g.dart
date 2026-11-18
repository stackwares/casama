// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_computer_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ResetComputerRequestCWProxy {
  ResetComputerRequest mode(ResetComputerRequestModeEnum mode);

  ResetComputerRequest checkpoint(bool? checkpoint);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ResetComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ResetComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ResetComputerRequest call({
    ResetComputerRequestModeEnum mode,
    bool? checkpoint,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfResetComputerRequest.copyWith(...)` or call `instanceOfResetComputerRequest.copyWith.fieldName(value)` for a single field.
class _$ResetComputerRequestCWProxyImpl
    implements _$ResetComputerRequestCWProxy {
  const _$ResetComputerRequestCWProxyImpl(this._value);

  final ResetComputerRequest _value;

  @override
  ResetComputerRequest mode(ResetComputerRequestModeEnum mode) =>
      call(mode: mode);

  @override
  ResetComputerRequest checkpoint(bool? checkpoint) =>
      call(checkpoint: checkpoint);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ResetComputerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ResetComputerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ResetComputerRequest call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? checkpoint = const $CopyWithPlaceholder(),
  }) {
    return ResetComputerRequest(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as ResetComputerRequestModeEnum,
      checkpoint: checkpoint == const $CopyWithPlaceholder()
          ? _value.checkpoint
          // ignore: cast_nullable_to_non_nullable
          : checkpoint as bool?,
    );
  }
}

extension $ResetComputerRequestCopyWith on ResetComputerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfResetComputerRequest.copyWith(...)` or `instanceOfResetComputerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ResetComputerRequestCWProxy get copyWith =>
      _$ResetComputerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetComputerRequest _$ResetComputerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResetComputerRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode']);
  final val = ResetComputerRequest(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecode(_$ResetComputerRequestModeEnumEnumMap, v),
    ),
    checkpoint: $checkedConvert('checkpoint', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$ResetComputerRequestToJson(
  ResetComputerRequest instance,
) => <String, dynamic>{
  'mode': _$ResetComputerRequestModeEnumEnumMap[instance.mode]!,
  'checkpoint': ?instance.checkpoint,
};

const _$ResetComputerRequestModeEnumEnumMap = {
  ResetComputerRequestModeEnum.system: 'system',
  ResetComputerRequestModeEnum.erase: 'erase',
};
