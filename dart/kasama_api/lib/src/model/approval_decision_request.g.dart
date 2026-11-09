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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalDecisionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalDecisionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalDecisionRequest call({
    ApprovalDecisionRequestDecisionEnum decision,
    bool? alwaysAllow,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfApprovalDecisionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfApprovalDecisionRequest.copyWith.fieldName(...)`
class _$ApprovalDecisionRequestCWProxyImpl
    implements _$ApprovalDecisionRequestCWProxy {
  const _$ApprovalDecisionRequestCWProxyImpl(this._value);

  final ApprovalDecisionRequest _value;

  @override
  ApprovalDecisionRequest decision(
    ApprovalDecisionRequestDecisionEnum decision,
  ) => this(decision: decision);

  @override
  ApprovalDecisionRequest alwaysAllow(bool? alwaysAllow) =>
      this(alwaysAllow: alwaysAllow);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalDecisionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalDecisionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalDecisionRequest call({
    Object? decision = const $CopyWithPlaceholder(),
    Object? alwaysAllow = const $CopyWithPlaceholder(),
  }) {
    return ApprovalDecisionRequest(
      decision: decision == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfApprovalDecisionRequest.copyWith(...)` or like so:`instanceOfApprovalDecisionRequest.copyWith.fieldName(...)`.
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
