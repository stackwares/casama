// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_decision_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalDecisionRequestCWProxy {
  ApprovalDecisionRequest decision(
    ApprovalDecisionRequestDecisionEnum decision,
  );

  ApprovalDecisionRequest alwaysAllow(bool? alwaysAllow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalDecisionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalDecisionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ApprovalDecisionRequest call({
    ApprovalDecisionRequestDecisionEnum decision,
    bool? alwaysAllow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApprovalDecisionRequest.copyWith(...)` or call `instanceOfApprovalDecisionRequest.copyWith.fieldName(value)` for a single field.
class _$ApprovalDecisionRequestCWProxyImpl
    implements _$ApprovalDecisionRequestCWProxy {
  const _$ApprovalDecisionRequestCWProxyImpl(this._value);

  final ApprovalDecisionRequest _value;

  @override
  ApprovalDecisionRequest decision(
    ApprovalDecisionRequestDecisionEnum decision,
  ) => call(decision: decision);

  @override
  ApprovalDecisionRequest alwaysAllow(bool? alwaysAllow) =>
      call(alwaysAllow: alwaysAllow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalDecisionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalDecisionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApprovalDecisionRequest call({
    Object? decision = const $CopyWithPlaceholder(),
    Object? alwaysAllow = const $CopyWithPlaceholder(),
  }) {
    return ApprovalDecisionRequest(
      decision: decision == const $CopyWithPlaceholder() || decision == null
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as ApprovalDecisionRequestDecisionEnum,
      alwaysAllow: alwaysAllow == const $CopyWithPlaceholder()
          ? _value.alwaysAllow
          // ignore: cast_nullable_to_non_nullable
          : alwaysAllow as bool?,
    );
  }
}

extension $ApprovalDecisionRequestCopyWith on ApprovalDecisionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApprovalDecisionRequest.copyWith(...)` or `instanceOfApprovalDecisionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalDecisionRequestCWProxy get copyWith =>
      _$ApprovalDecisionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalDecisionRequest _$ApprovalDecisionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApprovalDecisionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['decision']);
  final val = ApprovalDecisionRequest(
    decision: $checkedConvert(
      'decision',
      (v) => $enumDecode(_$ApprovalDecisionRequestDecisionEnumEnumMap, v),
    ),
    alwaysAllow: $checkedConvert('always_allow', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'alwaysAllow': 'always_allow'});

Map<String, dynamic> _$ApprovalDecisionRequestToJson(
  ApprovalDecisionRequest instance,
) => <String, dynamic>{
  'decision': _$ApprovalDecisionRequestDecisionEnumEnumMap[instance.decision]!,
  'always_allow': ?instance.alwaysAllow,
};

const _$ApprovalDecisionRequestDecisionEnumEnumMap = {
  ApprovalDecisionRequestDecisionEnum.approved: 'approved',
  ApprovalDecisionRequestDecisionEnum.denied: 'denied',
};
