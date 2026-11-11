// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'take_lease_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeLeaseRequestCWProxy {
  TakeLeaseRequest allowShell(bool? allowShell);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeLeaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeLeaseRequest call({bool? allowShell});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeLeaseRequest.copyWith(...)` or call `instanceOfTakeLeaseRequest.copyWith.fieldName(value)` for a single field.
class _$TakeLeaseRequestCWProxyImpl implements _$TakeLeaseRequestCWProxy {
  const _$TakeLeaseRequestCWProxyImpl(this._value);

  final TakeLeaseRequest _value;

  @override
  TakeLeaseRequest allowShell(bool? allowShell) => call(allowShell: allowShell);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeLeaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeLeaseRequest call({Object? allowShell = const $CopyWithPlaceholder()}) {
    return TakeLeaseRequest(
      allowShell: allowShell == const $CopyWithPlaceholder()
          ? _value.allowShell
          // ignore: cast_nullable_to_non_nullable
          : allowShell as bool?,
    );
  }
}

extension $TakeLeaseRequestCopyWith on TakeLeaseRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeLeaseRequest.copyWith(...)` or `instanceOfTakeLeaseRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeLeaseRequestCWProxy get copyWith => _$TakeLeaseRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeLeaseRequest _$TakeLeaseRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TakeLeaseRequest', json, ($checkedConvert) {
      final val = TakeLeaseRequest(
        allowShell: $checkedConvert('allow_shell', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'allowShell': 'allow_shell'});

Map<String, dynamic> _$TakeLeaseRequestToJson(TakeLeaseRequest instance) =>
    <String, dynamic>{'allow_shell': ?instance.allowShell};
