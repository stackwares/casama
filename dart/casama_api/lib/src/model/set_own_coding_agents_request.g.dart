// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_own_coding_agents_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetOwnCodingAgentsRequestCWProxy {
  SetOwnCodingAgentsRequest agents(List<OwnCodingAgent> agents);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetOwnCodingAgentsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetOwnCodingAgentsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetOwnCodingAgentsRequest call({List<OwnCodingAgent> agents});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetOwnCodingAgentsRequest.copyWith(...)` or call `instanceOfSetOwnCodingAgentsRequest.copyWith.fieldName(value)` for a single field.
class _$SetOwnCodingAgentsRequestCWProxyImpl
    implements _$SetOwnCodingAgentsRequestCWProxy {
  const _$SetOwnCodingAgentsRequestCWProxyImpl(this._value);

  final SetOwnCodingAgentsRequest _value;

  @override
  SetOwnCodingAgentsRequest agents(List<OwnCodingAgent> agents) =>
      call(agents: agents);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetOwnCodingAgentsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetOwnCodingAgentsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetOwnCodingAgentsRequest call({
    Object? agents = const $CopyWithPlaceholder(),
  }) {
    return SetOwnCodingAgentsRequest(
      agents: agents == const $CopyWithPlaceholder() || agents == null
          ? _value.agents
          // ignore: cast_nullable_to_non_nullable
          : agents as List<OwnCodingAgent>,
    );
  }
}

extension $SetOwnCodingAgentsRequestCopyWith on SetOwnCodingAgentsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetOwnCodingAgentsRequest.copyWith(...)` or `instanceOfSetOwnCodingAgentsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetOwnCodingAgentsRequestCWProxy get copyWith =>
      _$SetOwnCodingAgentsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetOwnCodingAgentsRequest _$SetOwnCodingAgentsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetOwnCodingAgentsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['agents']);
  final val = SetOwnCodingAgentsRequest(
    agents: $checkedConvert(
      'agents',
      (v) => (v as List<dynamic>)
          .map((e) => OwnCodingAgent.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetOwnCodingAgentsRequestToJson(
  SetOwnCodingAgentsRequest instance,
) => <String, dynamic>{
  'agents': instance.agents.map((e) => e.toJson()).toList(),
};
