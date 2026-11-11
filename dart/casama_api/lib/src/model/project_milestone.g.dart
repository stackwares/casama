// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_milestone.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProjectMilestoneCWProxy {
  ProjectMilestone id(String id);

  ProjectMilestone name(String name);

  ProjectMilestone position(int position);

  ProjectMilestone requiresSignoff(bool requiresSignoff);

  ProjectMilestone status(ProjectMilestoneStatusEnum status);

  ProjectMilestone ticketsDone(int ticketsDone);

  ProjectMilestone ticketsTotal(int ticketsTotal);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectMilestone(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectMilestone(...).copyWith(id: 12, name: "My name")
  /// ```
  ProjectMilestone call({
    String id,
    String name,
    int position,
    bool requiresSignoff,
    ProjectMilestoneStatusEnum status,
    int ticketsDone,
    int ticketsTotal,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProjectMilestone.copyWith(...)` or call `instanceOfProjectMilestone.copyWith.fieldName(value)` for a single field.
class _$ProjectMilestoneCWProxyImpl implements _$ProjectMilestoneCWProxy {
  const _$ProjectMilestoneCWProxyImpl(this._value);

  final ProjectMilestone _value;

  @override
  ProjectMilestone id(String id) => call(id: id);

  @override
  ProjectMilestone name(String name) => call(name: name);

  @override
  ProjectMilestone position(int position) => call(position: position);

  @override
  ProjectMilestone requiresSignoff(bool requiresSignoff) =>
      call(requiresSignoff: requiresSignoff);

  @override
  ProjectMilestone status(ProjectMilestoneStatusEnum status) =>
      call(status: status);

  @override
  ProjectMilestone ticketsDone(int ticketsDone) =>
      call(ticketsDone: ticketsDone);

  @override
  ProjectMilestone ticketsTotal(int ticketsTotal) =>
      call(ticketsTotal: ticketsTotal);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectMilestone(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectMilestone(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProjectMilestone call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? requiresSignoff = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? ticketsDone = const $CopyWithPlaceholder(),
    Object? ticketsTotal = const $CopyWithPlaceholder(),
  }) {
    return ProjectMilestone(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      position: position == const $CopyWithPlaceholder() || position == null
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as int,
      requiresSignoff:
          requiresSignoff == const $CopyWithPlaceholder() ||
              requiresSignoff == null
          ? _value.requiresSignoff
          // ignore: cast_nullable_to_non_nullable
          : requiresSignoff as bool,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ProjectMilestoneStatusEnum,
      ticketsDone:
          ticketsDone == const $CopyWithPlaceholder() || ticketsDone == null
          ? _value.ticketsDone
          // ignore: cast_nullable_to_non_nullable
          : ticketsDone as int,
      ticketsTotal:
          ticketsTotal == const $CopyWithPlaceholder() || ticketsTotal == null
          ? _value.ticketsTotal
          // ignore: cast_nullable_to_non_nullable
          : ticketsTotal as int,
    );
  }
}

extension $ProjectMilestoneCopyWith on ProjectMilestone {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProjectMilestone.copyWith(...)` or `instanceOfProjectMilestone.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProjectMilestoneCWProxy get copyWith => _$ProjectMilestoneCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectMilestone _$ProjectMilestoneFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProjectMilestone',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'position',
        'requires_signoff',
        'status',
        'tickets_done',
        'tickets_total',
      ],
    );
    final val = ProjectMilestone(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      position: $checkedConvert('position', (v) => (v as num).toInt()),
      requiresSignoff: $checkedConvert('requires_signoff', (v) => v as bool),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$ProjectMilestoneStatusEnumEnumMap, v),
      ),
      ticketsDone: $checkedConvert('tickets_done', (v) => (v as num).toInt()),
      ticketsTotal: $checkedConvert('tickets_total', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'requiresSignoff': 'requires_signoff',
    'ticketsDone': 'tickets_done',
    'ticketsTotal': 'tickets_total',
  },
);

Map<String, dynamic> _$ProjectMilestoneToJson(ProjectMilestone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'position': instance.position,
      'requires_signoff': instance.requiresSignoff,
      'status': _$ProjectMilestoneStatusEnumEnumMap[instance.status]!,
      'tickets_done': instance.ticketsDone,
      'tickets_total': instance.ticketsTotal,
    };

const _$ProjectMilestoneStatusEnumEnumMap = {
  ProjectMilestoneStatusEnum.open: 'open',
  ProjectMilestoneStatusEnum.awaitingSignoff: 'awaiting_signoff',
  ProjectMilestoneStatusEnum.done: 'done',
};
