// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_project_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateProjectRequestCWProxy {
  CreateProjectRequest orgId(String orgId);

  CreateProjectRequest title(String title);

  CreateProjectRequest goalMd(String goalMd);

  CreateProjectRequest doneCriteriaMd(String? doneCriteriaMd);

  CreateProjectRequest leadBotId(String leadBotId);

  CreateProjectRequest budgetUsd(num? budgetUsd);

  CreateProjectRequest deadlineAt(DateTime? deadlineAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateProjectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateProjectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateProjectRequest call({
    String orgId,
    String title,
    String goalMd,
    String? doneCriteriaMd,
    String leadBotId,
    num? budgetUsd,
    DateTime? deadlineAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateProjectRequest.copyWith(...)` or call `instanceOfCreateProjectRequest.copyWith.fieldName(value)` for a single field.
class _$CreateProjectRequestCWProxyImpl
    implements _$CreateProjectRequestCWProxy {
  const _$CreateProjectRequestCWProxyImpl(this._value);

  final CreateProjectRequest _value;

  @override
  CreateProjectRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateProjectRequest title(String title) => call(title: title);

  @override
  CreateProjectRequest goalMd(String goalMd) => call(goalMd: goalMd);

  @override
  CreateProjectRequest doneCriteriaMd(String? doneCriteriaMd) =>
      call(doneCriteriaMd: doneCriteriaMd);

  @override
  CreateProjectRequest leadBotId(String leadBotId) =>
      call(leadBotId: leadBotId);

  @override
  CreateProjectRequest budgetUsd(num? budgetUsd) => call(budgetUsd: budgetUsd);

  @override
  CreateProjectRequest deadlineAt(DateTime? deadlineAt) =>
      call(deadlineAt: deadlineAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateProjectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateProjectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateProjectRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? goalMd = const $CopyWithPlaceholder(),
    Object? doneCriteriaMd = const $CopyWithPlaceholder(),
    Object? leadBotId = const $CopyWithPlaceholder(),
    Object? budgetUsd = const $CopyWithPlaceholder(),
    Object? deadlineAt = const $CopyWithPlaceholder(),
  }) {
    return CreateProjectRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      goalMd: goalMd == const $CopyWithPlaceholder() || goalMd == null
          ? _value.goalMd
          // ignore: cast_nullable_to_non_nullable
          : goalMd as String,
      doneCriteriaMd: doneCriteriaMd == const $CopyWithPlaceholder()
          ? _value.doneCriteriaMd
          // ignore: cast_nullable_to_non_nullable
          : doneCriteriaMd as String?,
      leadBotId: leadBotId == const $CopyWithPlaceholder() || leadBotId == null
          ? _value.leadBotId
          // ignore: cast_nullable_to_non_nullable
          : leadBotId as String,
      budgetUsd: budgetUsd == const $CopyWithPlaceholder()
          ? _value.budgetUsd
          // ignore: cast_nullable_to_non_nullable
          : budgetUsd as num?,
      deadlineAt: deadlineAt == const $CopyWithPlaceholder()
          ? _value.deadlineAt
          // ignore: cast_nullable_to_non_nullable
          : deadlineAt as DateTime?,
    );
  }
}

extension $CreateProjectRequestCopyWith on CreateProjectRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateProjectRequest.copyWith(...)` or `instanceOfCreateProjectRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateProjectRequestCWProxy get copyWith =>
      _$CreateProjectRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProjectRequest _$CreateProjectRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateProjectRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['org_id', 'title', 'goal_md', 'lead_bot_id'],
    );
    final val = CreateProjectRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      goalMd: $checkedConvert('goal_md', (v) => v as String),
      doneCriteriaMd: $checkedConvert('done_criteria_md', (v) => v as String?),
      leadBotId: $checkedConvert('lead_bot_id', (v) => v as String),
      budgetUsd: $checkedConvert('budget_usd', (v) => v as num?),
      deadlineAt: $checkedConvert(
        'deadline_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'goalMd': 'goal_md',
    'doneCriteriaMd': 'done_criteria_md',
    'leadBotId': 'lead_bot_id',
    'budgetUsd': 'budget_usd',
    'deadlineAt': 'deadline_at',
  },
);

Map<String, dynamic> _$CreateProjectRequestToJson(
  CreateProjectRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'title': instance.title,
  'goal_md': instance.goalMd,
  'done_criteria_md': ?instance.doneCriteriaMd,
  'lead_bot_id': instance.leadBotId,
  'budget_usd': ?instance.budgetUsd,
  'deadline_at': ?instance.deadlineAt?.toIso8601String(),
};
