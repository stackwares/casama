// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_skill_update_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApplySkillUpdateRequestCWProxy {
  ApplySkillUpdateRequest commit(String commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApplySkillUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApplySkillUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ApplySkillUpdateRequest call({String commit});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApplySkillUpdateRequest.copyWith(...)` or call `instanceOfApplySkillUpdateRequest.copyWith.fieldName(value)` for a single field.
class _$ApplySkillUpdateRequestCWProxyImpl
    implements _$ApplySkillUpdateRequestCWProxy {
  const _$ApplySkillUpdateRequestCWProxyImpl(this._value);

  final ApplySkillUpdateRequest _value;

  @override
  ApplySkillUpdateRequest commit(String commit) => call(commit: commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApplySkillUpdateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApplySkillUpdateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApplySkillUpdateRequest call({
    Object? commit = const $CopyWithPlaceholder(),
  }) {
    return ApplySkillUpdateRequest(
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
    );
  }
}

extension $ApplySkillUpdateRequestCopyWith on ApplySkillUpdateRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApplySkillUpdateRequest.copyWith(...)` or `instanceOfApplySkillUpdateRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApplySkillUpdateRequestCWProxy get copyWith =>
      _$ApplySkillUpdateRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplySkillUpdateRequest _$ApplySkillUpdateRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApplySkillUpdateRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['commit']);
  final val = ApplySkillUpdateRequest(
    commit: $checkedConvert('commit', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ApplySkillUpdateRequestToJson(
  ApplySkillUpdateRequest instance,
) => <String, dynamic>{'commit': instance.commit};
