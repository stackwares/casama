// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_default_invite_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateDefaultInviteRequestCWProxy {
  UpdateDefaultInviteRequest requiresApproval(bool? requiresApproval);

  UpdateDefaultInviteRequest reset(bool? reset);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateDefaultInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateDefaultInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateDefaultInviteRequest call({bool? requiresApproval, bool? reset});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateDefaultInviteRequest.copyWith(...)` or call `instanceOfUpdateDefaultInviteRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateDefaultInviteRequestCWProxyImpl
    implements _$UpdateDefaultInviteRequestCWProxy {
  const _$UpdateDefaultInviteRequestCWProxyImpl(this._value);

  final UpdateDefaultInviteRequest _value;

  @override
  UpdateDefaultInviteRequest requiresApproval(bool? requiresApproval) =>
      call(requiresApproval: requiresApproval);

  @override
  UpdateDefaultInviteRequest reset(bool? reset) => call(reset: reset);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateDefaultInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateDefaultInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateDefaultInviteRequest call({
    Object? requiresApproval = const $CopyWithPlaceholder(),
    Object? reset = const $CopyWithPlaceholder(),
  }) {
    return UpdateDefaultInviteRequest(
      requiresApproval: requiresApproval == const $CopyWithPlaceholder()
          ? _value.requiresApproval
          // ignore: cast_nullable_to_non_nullable
          : requiresApproval as bool?,
      reset: reset == const $CopyWithPlaceholder()
          ? _value.reset
          // ignore: cast_nullable_to_non_nullable
          : reset as bool?,
    );
  }
}

extension $UpdateDefaultInviteRequestCopyWith on UpdateDefaultInviteRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateDefaultInviteRequest.copyWith(...)` or `instanceOfUpdateDefaultInviteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateDefaultInviteRequestCWProxy get copyWith =>
      _$UpdateDefaultInviteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateDefaultInviteRequest _$UpdateDefaultInviteRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateDefaultInviteRequest', json, ($checkedConvert) {
  final val = UpdateDefaultInviteRequest(
    requiresApproval: $checkedConvert('requires_approval', (v) => v as bool?),
    reset: $checkedConvert('reset', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'requiresApproval': 'requires_approval'});

Map<String, dynamic> _$UpdateDefaultInviteRequestToJson(
  UpdateDefaultInviteRequest instance,
) => <String, dynamic>{
  'requires_approval': ?instance.requiresApproval,
  'reset': ?instance.reset,
};
