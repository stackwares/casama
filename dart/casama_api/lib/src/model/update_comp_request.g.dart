// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_comp_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCompRequestCWProxy {
  UpdateCompRequest extendMonths(int? extendMonths);

  UpdateCompRequest revoke(bool? revoke);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCompRequest call({int? extendMonths, bool? revoke});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCompRequest.copyWith(...)` or call `instanceOfUpdateCompRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateCompRequestCWProxyImpl implements _$UpdateCompRequestCWProxy {
  const _$UpdateCompRequestCWProxyImpl(this._value);

  final UpdateCompRequest _value;

  @override
  UpdateCompRequest extendMonths(int? extendMonths) =>
      call(extendMonths: extendMonths);

  @override
  UpdateCompRequest revoke(bool? revoke) => call(revoke: revoke);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCompRequest call({
    Object? extendMonths = const $CopyWithPlaceholder(),
    Object? revoke = const $CopyWithPlaceholder(),
  }) {
    return UpdateCompRequest(
      extendMonths: extendMonths == const $CopyWithPlaceholder()
          ? _value.extendMonths
          // ignore: cast_nullable_to_non_nullable
          : extendMonths as int?,
      revoke: revoke == const $CopyWithPlaceholder()
          ? _value.revoke
          // ignore: cast_nullable_to_non_nullable
          : revoke as bool?,
    );
  }
}

extension $UpdateCompRequestCopyWith on UpdateCompRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCompRequest.copyWith(...)` or `instanceOfUpdateCompRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCompRequestCWProxy get copyWith =>
      _$UpdateCompRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCompRequest _$UpdateCompRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateCompRequest', json, ($checkedConvert) {
      final val = UpdateCompRequest(
        extendMonths: $checkedConvert(
          'extend_months',
          (v) => (v as num?)?.toInt(),
        ),
        revoke: $checkedConvert('revoke', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'extendMonths': 'extend_months'});

Map<String, dynamic> _$UpdateCompRequestToJson(UpdateCompRequest instance) =>
    <String, dynamic>{
      'extend_months': ?instance.extendMonths,
      'revoke': ?instance.revoke,
    };
