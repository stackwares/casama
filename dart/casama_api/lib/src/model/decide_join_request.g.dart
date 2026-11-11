// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_join_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecideJoinRequestCWProxy {
  DecideJoinRequest approve(bool approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecideJoinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecideJoinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DecideJoinRequest call({bool approve});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecideJoinRequest.copyWith(...)` or call `instanceOfDecideJoinRequest.copyWith.fieldName(value)` for a single field.
class _$DecideJoinRequestCWProxyImpl implements _$DecideJoinRequestCWProxy {
  const _$DecideJoinRequestCWProxyImpl(this._value);

  final DecideJoinRequest _value;

  @override
  DecideJoinRequest approve(bool approve) => call(approve: approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecideJoinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecideJoinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecideJoinRequest call({Object? approve = const $CopyWithPlaceholder()}) {
    return DecideJoinRequest(
      approve: approve == const $CopyWithPlaceholder() || approve == null
          ? _value.approve
          // ignore: cast_nullable_to_non_nullable
          : approve as bool,
    );
  }
}

extension $DecideJoinRequestCopyWith on DecideJoinRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecideJoinRequest.copyWith(...)` or `instanceOfDecideJoinRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecideJoinRequestCWProxy get copyWith =>
      _$DecideJoinRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecideJoinRequest _$DecideJoinRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DecideJoinRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['approve']);
      final val = DecideJoinRequest(
        approve: $checkedConvert('approve', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$DecideJoinRequestToJson(DecideJoinRequest instance) =>
    <String, dynamic>{'approve': instance.approve};
