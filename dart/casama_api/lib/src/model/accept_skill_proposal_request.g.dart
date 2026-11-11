// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_skill_proposal_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AcceptSkillProposalRequestCWProxy {
  AcceptSkillProposalRequest name(String? name);

  AcceptSkillProposalRequest description(String? description);

  AcceptSkillProposalRequest bodyMd(String? bodyMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AcceptSkillProposalRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AcceptSkillProposalRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AcceptSkillProposalRequest call({
    String? name,
    String? description,
    String? bodyMd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAcceptSkillProposalRequest.copyWith(...)` or call `instanceOfAcceptSkillProposalRequest.copyWith.fieldName(value)` for a single field.
class _$AcceptSkillProposalRequestCWProxyImpl
    implements _$AcceptSkillProposalRequestCWProxy {
  const _$AcceptSkillProposalRequestCWProxyImpl(this._value);

  final AcceptSkillProposalRequest _value;

  @override
  AcceptSkillProposalRequest name(String? name) => call(name: name);

  @override
  AcceptSkillProposalRequest description(String? description) =>
      call(description: description);

  @override
  AcceptSkillProposalRequest bodyMd(String? bodyMd) => call(bodyMd: bodyMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AcceptSkillProposalRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AcceptSkillProposalRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AcceptSkillProposalRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
  }) {
    return AcceptSkillProposalRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      bodyMd: bodyMd == const $CopyWithPlaceholder()
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String?,
    );
  }
}

extension $AcceptSkillProposalRequestCopyWith on AcceptSkillProposalRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAcceptSkillProposalRequest.copyWith(...)` or `instanceOfAcceptSkillProposalRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AcceptSkillProposalRequestCWProxy get copyWith =>
      _$AcceptSkillProposalRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptSkillProposalRequest _$AcceptSkillProposalRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AcceptSkillProposalRequest', json, ($checkedConvert) {
  final val = AcceptSkillProposalRequest(
    name: $checkedConvert('name', (v) => v as String?),
    description: $checkedConvert('description', (v) => v as String?),
    bodyMd: $checkedConvert('body_md', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'bodyMd': 'body_md'});

Map<String, dynamic> _$AcceptSkillProposalRequestToJson(
  AcceptSkillProposalRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'description': ?instance.description,
  'body_md': ?instance.bodyMd,
};
