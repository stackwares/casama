// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_computer_update_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApplyComputerUpdateRequestCWProxy {
  ApplyComputerUpdateRequest force(bool? force);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApplyComputerUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApplyComputerUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ApplyComputerUpdateRequest call({bool? force});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApplyComputerUpdateRequest.copyWith(...)` or call `instanceOfApplyComputerUpdateRequest.copyWith.fieldName(value)` for a single field.
class _$ApplyComputerUpdateRequestCWProxyImpl
    implements _$ApplyComputerUpdateRequestCWProxy {
  const _$ApplyComputerUpdateRequestCWProxyImpl(this._value);

  final ApplyComputerUpdateRequest _value;

  @override
  ApplyComputerUpdateRequest force(bool? force) => call(force: force);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApplyComputerUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApplyComputerUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApplyComputerUpdateRequest call({
    Object? force = const $CopyWithPlaceholder(),
  }) {
    return ApplyComputerUpdateRequest(
      force: force == const $CopyWithPlaceholder()
          ? _value.force
          // ignore: cast_nullable_to_non_nullable
          : force as bool?,
    );
  }
}

extension $ApplyComputerUpdateRequestCopyWith on ApplyComputerUpdateRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApplyComputerUpdateRequest.copyWith(...)` or `instanceOfApplyComputerUpdateRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApplyComputerUpdateRequestCWProxy get copyWith =>
      _$ApplyComputerUpdateRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplyComputerUpdateRequest _$ApplyComputerUpdateRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApplyComputerUpdateRequest', json, ($checkedConvert) {
  final val = ApplyComputerUpdateRequest(
    force: $checkedConvert('force', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$ApplyComputerUpdateRequestToJson(
  ApplyComputerUpdateRequest instance,
) => <String, dynamic>{'force': ?instance.force};
