// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProjectDetailCWProxy {
  ProjectDetail id(String id);

  ProjectDetail orgId(String orgId);

  ProjectDetail slug(String slug);

  ProjectDetail title(String title);

  ProjectDetail goalMd(String goalMd);

  ProjectDetail doneCriteriaMd(String doneCriteriaMd);

  ProjectDetail status(ProjectStatus status);

  ProjectDetail planStatus(ProjectDetailPlanStatusEnum planStatus);

  ProjectDetail statusReason(String? statusReason);

  ProjectDetail leadBotId(String leadBotId);

  ProjectDetail ownerUserId(String? ownerUserId);

  ProjectDetail conversationId(String? conversationId);

  ProjectDetail budgetUsd(num? budgetUsd);

  ProjectDetail spentUsd(num spentUsd);

  ProjectDetail deadlineAt(DateTime? deadlineAt);

  ProjectDetail planMd(String planMd);

  ProjectDetail sessions(int sessions);

  ProjectDetail createdAt(DateTime createdAt);

  ProjectDetail milestones(List<ProjectMilestone> milestones);

  ProjectDetail runs(List<ProjectRun> runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  ProjectDetail call({
    String id,
    String orgId,
    String slug,
    String title,
    String goalMd,
    String doneCriteriaMd,
    ProjectStatus status,
    ProjectDetailPlanStatusEnum planStatus,
    String? statusReason,
    String leadBotId,
    String? ownerUserId,
    String? conversationId,
    num? budgetUsd,
    num spentUsd,
    DateTime? deadlineAt,
    String planMd,
    int sessions,
    DateTime createdAt,
    List<ProjectMilestone> milestones,
    List<ProjectRun> runs,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProjectDetail.copyWith(...)` or call `instanceOfProjectDetail.copyWith.fieldName(value)` for a single field.
class _$ProjectDetailCWProxyImpl implements _$ProjectDetailCWProxy {
  const _$ProjectDetailCWProxyImpl(this._value);

  final ProjectDetail _value;

  @override
  ProjectDetail id(String id) => call(id: id);

  @override
  ProjectDetail orgId(String orgId) => call(orgId: orgId);

  @override
  ProjectDetail slug(String slug) => call(slug: slug);

  @override
  ProjectDetail title(String title) => call(title: title);

  @override
  ProjectDetail goalMd(String goalMd) => call(goalMd: goalMd);

  @override
  ProjectDetail doneCriteriaMd(String doneCriteriaMd) =>
      call(doneCriteriaMd: doneCriteriaMd);

  @override
  ProjectDetail status(ProjectStatus status) => call(status: status);

  @override
  ProjectDetail planStatus(ProjectDetailPlanStatusEnum planStatus) =>
      call(planStatus: planStatus);

  @override
  ProjectDetail statusReason(String? statusReason) =>
      call(statusReason: statusReason);

  @override
  ProjectDetail leadBotId(String leadBotId) => call(leadBotId: leadBotId);

  @override
  ProjectDetail ownerUserId(String? ownerUserId) =>
      call(ownerUserId: ownerUserId);

  @override
  ProjectDetail conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  ProjectDetail budgetUsd(num? budgetUsd) => call(budgetUsd: budgetUsd);

  @override
  ProjectDetail spentUsd(num spentUsd) => call(spentUsd: spentUsd);

  @override
  ProjectDetail deadlineAt(DateTime? deadlineAt) =>
      call(deadlineAt: deadlineAt);

  @override
  ProjectDetail planMd(String planMd) => call(planMd: planMd);

  @override
  ProjectDetail sessions(int sessions) => call(sessions: sessions);

  @override
  ProjectDetail createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  ProjectDetail milestones(List<ProjectMilestone> milestones) =>
      call(milestones: milestones);

  @override
  ProjectDetail runs(List<ProjectRun> runs) => call(runs: runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProjectDetail call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? goalMd = const $CopyWithPlaceholder(),
    Object? doneCriteriaMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? planStatus = const $CopyWithPlaceholder(),
    Object? statusReason = const $CopyWithPlaceholder(),
    Object? leadBotId = const $CopyWithPlaceholder(),
    Object? ownerUserId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? budgetUsd = const $CopyWithPlaceholder(),
    Object? spentUsd = const $CopyWithPlaceholder(),
    Object? deadlineAt = const $CopyWithPlaceholder(),
    Object? planMd = const $CopyWithPlaceholder(),
    Object? sessions = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? milestones = const $CopyWithPlaceholder(),
    Object? runs = const $CopyWithPlaceholder(),
  }) {
    return ProjectDetail(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      slug: slug == const $CopyWithPlaceholder() || slug == null
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      goalMd: goalMd == const $CopyWithPlaceholder() || goalMd == null
          ? _value.goalMd
          // ignore: cast_nullable_to_non_nullable
          : goalMd as String,
      doneCriteriaMd:
          doneCriteriaMd == const $CopyWithPlaceholder() ||
              doneCriteriaMd == null
          ? _value.doneCriteriaMd
          // ignore: cast_nullable_to_non_nullable
          : doneCriteriaMd as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ProjectStatus,
      planStatus:
          planStatus == const $CopyWithPlaceholder() || planStatus == null
          ? _value.planStatus
          // ignore: cast_nullable_to_non_nullable
          : planStatus as ProjectDetailPlanStatusEnum,
      statusReason: statusReason == const $CopyWithPlaceholder()
          ? _value.statusReason
          // ignore: cast_nullable_to_non_nullable
          : statusReason as String?,
      leadBotId: leadBotId == const $CopyWithPlaceholder() || leadBotId == null
          ? _value.leadBotId
          // ignore: cast_nullable_to_non_nullable
          : leadBotId as String,
      ownerUserId: ownerUserId == const $CopyWithPlaceholder()
          ? _value.ownerUserId
          // ignore: cast_nullable_to_non_nullable
          : ownerUserId as String?,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      budgetUsd: budgetUsd == const $CopyWithPlaceholder()
          ? _value.budgetUsd
          // ignore: cast_nullable_to_non_nullable
          : budgetUsd as num?,
      spentUsd: spentUsd == const $CopyWithPlaceholder() || spentUsd == null
          ? _value.spentUsd
          // ignore: cast_nullable_to_non_nullable
          : spentUsd as num,
      deadlineAt: deadlineAt == const $CopyWithPlaceholder()
          ? _value.deadlineAt
          // ignore: cast_nullable_to_non_nullable
          : deadlineAt as DateTime?,
      planMd: planMd == const $CopyWithPlaceholder() || planMd == null
          ? _value.planMd
          // ignore: cast_nullable_to_non_nullable
          : planMd as String,
      sessions: sessions == const $CopyWithPlaceholder() || sessions == null
          ? _value.sessions
          // ignore: cast_nullable_to_non_nullable
          : sessions as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      milestones:
          milestones == const $CopyWithPlaceholder() || milestones == null
          ? _value.milestones
          // ignore: cast_nullable_to_non_nullable
          : milestones as List<ProjectMilestone>,
      runs: runs == const $CopyWithPlaceholder() || runs == null
          ? _value.runs
          // ignore: cast_nullable_to_non_nullable
          : runs as List<ProjectRun>,
    );
  }
}

extension $ProjectDetailCopyWith on ProjectDetail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProjectDetail.copyWith(...)` or `instanceOfProjectDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProjectDetailCWProxy get copyWith => _$ProjectDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectDetail _$ProjectDetailFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProjectDetail',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'slug',
        'title',
        'goal_md',
        'done_criteria_md',
        'status',
        'plan_status',
        'status_reason',
        'lead_bot_id',
        'owner_user_id',
        'conversation_id',
        'budget_usd',
        'spent_usd',
        'deadline_at',
        'plan_md',
        'sessions',
        'created_at',
        'milestones',
        'runs',
      ],
    );
    final val = ProjectDetail(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      slug: $checkedConvert('slug', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      goalMd: $checkedConvert('goal_md', (v) => v as String),
      doneCriteriaMd: $checkedConvert('done_criteria_md', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$ProjectStatusEnumMap, v),
      ),
      planStatus: $checkedConvert(
        'plan_status',
        (v) => $enumDecode(_$ProjectDetailPlanStatusEnumEnumMap, v),
      ),
      statusReason: $checkedConvert('status_reason', (v) => v as String?),
      leadBotId: $checkedConvert('lead_bot_id', (v) => v as String),
      ownerUserId: $checkedConvert('owner_user_id', (v) => v as String?),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      budgetUsd: $checkedConvert('budget_usd', (v) => v as num?),
      spentUsd: $checkedConvert('spent_usd', (v) => v as num),
      deadlineAt: $checkedConvert(
        'deadline_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      planMd: $checkedConvert('plan_md', (v) => v as String),
      sessions: $checkedConvert('sessions', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      milestones: $checkedConvert(
        'milestones',
        (v) => (v as List<dynamic>)
            .map((e) => ProjectMilestone.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      runs: $checkedConvert(
        'runs',
        (v) => (v as List<dynamic>)
            .map((e) => ProjectRun.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'goalMd': 'goal_md',
    'doneCriteriaMd': 'done_criteria_md',
    'planStatus': 'plan_status',
    'statusReason': 'status_reason',
    'leadBotId': 'lead_bot_id',
    'ownerUserId': 'owner_user_id',
    'conversationId': 'conversation_id',
    'budgetUsd': 'budget_usd',
    'spentUsd': 'spent_usd',
    'deadlineAt': 'deadline_at',
    'planMd': 'plan_md',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ProjectDetailToJson(ProjectDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'slug': instance.slug,
      'title': instance.title,
      'goal_md': instance.goalMd,
      'done_criteria_md': instance.doneCriteriaMd,
      'status': _$ProjectStatusEnumMap[instance.status]!,
      'plan_status': _$ProjectDetailPlanStatusEnumEnumMap[instance.planStatus]!,
      'status_reason': instance.statusReason,
      'lead_bot_id': instance.leadBotId,
      'owner_user_id': instance.ownerUserId,
      'conversation_id': instance.conversationId,
      'budget_usd': instance.budgetUsd,
      'spent_usd': instance.spentUsd,
      'deadline_at': instance.deadlineAt?.toIso8601String(),
      'plan_md': instance.planMd,
      'sessions': instance.sessions,
      'created_at': instance.createdAt.toIso8601String(),
      'milestones': instance.milestones.map((e) => e.toJson()).toList(),
      'runs': instance.runs.map((e) => e.toJson()).toList(),
    };

const _$ProjectStatusEnumMap = {
  ProjectStatus.planning: 'planning',
  ProjectStatus.active: 'active',
  ProjectStatus.paused: 'paused',
  ProjectStatus.blocked: 'blocked',
  ProjectStatus.done: 'done',
  ProjectStatus.cancelled: 'cancelled',
};

const _$ProjectDetailPlanStatusEnumEnumMap = {
  ProjectDetailPlanStatusEnum.draft: 'draft',
  ProjectDetailPlanStatusEnum.proposed: 'proposed',
  ProjectDetailPlanStatusEnum.approved: 'approved',
};
