// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'take_lease_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeLeaseRequestCWProxy {
  TakeLeaseRequest allowShell(bool? allowShell);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeLeaseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeLeaseRequest call({bool? allowShell});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeLeaseRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeLeaseRequest.copyWith.fieldName(...)`
class _$TakeLeaseRequestCWProxyImpl implements _$TakeLeaseRequestCWProxy {
  const _$TakeLeaseRequestCWProxyImpl(this._value);

  final TakeLeaseRequest _value;

  @override
  TakeLeaseRequest allowShell(bool? allowShell) => this(allowShell: allowShell);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeLeaseRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeLeaseRequest(...).copyWith(id: 12, name: "My name")
  /// ````
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
  /// Returns a callable class that can be used as follows: `instanceOfTakeLeaseRequest.copyWith(...)` or like so:`instanceOfTakeLeaseRequest.copyWith.fieldName(...)`.
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
