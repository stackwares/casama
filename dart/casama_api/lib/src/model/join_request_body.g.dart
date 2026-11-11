// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinRequestBodyCWProxy {
  JoinRequestBody invite(String invite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequestBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequestBody(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinRequestBody call({String invite});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinRequestBody.copyWith(...)` or call `instanceOfJoinRequestBody.copyWith.fieldName(value)` for a single field.
class _$JoinRequestBodyCWProxyImpl implements _$JoinRequestBodyCWProxy {
  const _$JoinRequestBodyCWProxyImpl(this._value);

  final JoinRequestBody _value;

  @override
  JoinRequestBody invite(String invite) => call(invite: invite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequestBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequestBody(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinRequestBody call({Object? invite = const $CopyWithPlaceholder()}) {
    return JoinRequestBody(
      invite: invite == const $CopyWithPlaceholder() || invite == null
          ? _value.invite
          // ignore: cast_nullable_to_non_nullable
          : invite as String,
    );
  }
}

extension $JoinRequestBodyCopyWith on JoinRequestBody {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinRequestBody.copyWith(...)` or `instanceOfJoinRequestBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinRequestBodyCWProxy get copyWith => _$JoinRequestBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinRequestBody _$JoinRequestBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinRequestBody', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['invite']);
      final val = JoinRequestBody(
        invite: $checkedConvert('invite', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$JoinRequestBodyToJson(JoinRequestBody instance) =>
    <String, dynamic>{'invite': instance.invite};
