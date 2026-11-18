// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinResultCWProxy {
  JoinResult status(JoinResultStatusEnum status);

  JoinResult organization(OrganizationWithRole? organization);

  JoinResult workspaceName(String workspaceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinResult(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinResult call({
    JoinResultStatusEnum status,
    OrganizationWithRole? organization,
    String workspaceName,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinResult.copyWith(...)` or call `instanceOfJoinResult.copyWith.fieldName(value)` for a single field.
class _$JoinResultCWProxyImpl implements _$JoinResultCWProxy {
  const _$JoinResultCWProxyImpl(this._value);

  final JoinResult _value;

  @override
  JoinResult status(JoinResultStatusEnum status) => call(status: status);

  @override
  JoinResult organization(OrganizationWithRole? organization) =>
      call(organization: organization);

  @override
  JoinResult workspaceName(String workspaceName) =>
      call(workspaceName: workspaceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinResult call({
    Object? status = const $CopyWithPlaceholder(),
    Object? organization = const $CopyWithPlaceholder(),
    Object? workspaceName = const $CopyWithPlaceholder(),
  }) {
    return JoinResult(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as JoinResultStatusEnum,
      organization: organization == const $CopyWithPlaceholder()
          ? _value.organization
          // ignore: cast_nullable_to_non_nullable
          : organization as OrganizationWithRole?,
      workspaceName:
          workspaceName == const $CopyWithPlaceholder() || workspaceName == null
          ? _value.workspaceName
          // ignore: cast_nullable_to_non_nullable
          : workspaceName as String,
    );
  }
}

extension $JoinResultCopyWith on JoinResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinResult.copyWith(...)` or `instanceOfJoinResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinResultCWProxy get copyWith => _$JoinResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinResult _$JoinResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status', 'workspace_name']);
      final val = JoinResult(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$JoinResultStatusEnumEnumMap, v),
        ),
        organization: $checkedConvert(
          'organization',
          (v) => v == null
              ? null
              : OrganizationWithRole.fromJson(v as Map<String, dynamic>),
        ),
        workspaceName: $checkedConvert('workspace_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'workspaceName': 'workspace_name'});

Map<String, dynamic> _$JoinResultToJson(JoinResult instance) =>
    <String, dynamic>{
      'status': _$JoinResultStatusEnumEnumMap[instance.status]!,
      'organization': ?instance.organization?.toJson(),
      'workspace_name': instance.workspaceName,
    };

const _$JoinResultStatusEnumEnumMap = {
  JoinResultStatusEnum.joined: 'joined',
  JoinResultStatusEnum.member: 'member',
  JoinResultStatusEnum.requested: 'requested',
};
