// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_project_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateProjectRequestCWProxy {
  UpdateProjectRequest title(String? title);

  UpdateProjectRequest status(UpdateProjectRequestStatusEnum? status);

  UpdateProjectRequest budgetUsd(num? budgetUsd);

  UpdateProjectRequest deadlineAt(DateTime? deadlineAt);

  UpdateProjectRequest planMd(String? planMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateProjectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateProjectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateProjectRequest call({
    String? title,
    UpdateProjectRequestStatusEnum? status,
    num? budgetUsd,
    DateTime? deadlineAt,
    String? planMd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateProjectRequest.copyWith(...)` or call `instanceOfUpdateProjectRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateProjectRequestCWProxyImpl
    implements _$UpdateProjectRequestCWProxy {
  const _$UpdateProjectRequestCWProxyImpl(this._value);

  final UpdateProjectRequest _value;

  @override
  UpdateProjectRequest title(String? title) => call(title: title);

  @override
  UpdateProjectRequest status(UpdateProjectRequestStatusEnum? status) =>
      call(status: status);

  @override
  UpdateProjectRequest budgetUsd(num? budgetUsd) => call(budgetUsd: budgetUsd);

  @override
  UpdateProjectRequest deadlineAt(DateTime? deadlineAt) =>
      call(deadlineAt: deadlineAt);

  @override
  UpdateProjectRequest planMd(String? planMd) => call(planMd: planMd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateProjectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateProjectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateProjectRequest call({
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? budgetUsd = const $CopyWithPlaceholder(),
    Object? deadlineAt = const $CopyWithPlaceholder(),
    Object? planMd = const $CopyWithPlaceholder(),
  }) {
    return UpdateProjectRequest(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UpdateProjectRequestStatusEnum?,
      budgetUsd: budgetUsd == const $CopyWithPlaceholder()
          ? _value.budgetUsd
          // ignore: cast_nullable_to_non_nullable
          : budgetUsd as num?,
      deadlineAt: deadlineAt == const $CopyWithPlaceholder()
          ? _value.deadlineAt
          // ignore: cast_nullable_to_non_nullable
          : deadlineAt as DateTime?,
      planMd: planMd == const $CopyWithPlaceholder()
          ? _value.planMd
          // ignore: cast_nullable_to_non_nullable
          : planMd as String?,
    );
  }
}

extension $UpdateProjectRequestCopyWith on UpdateProjectRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateProjectRequest.copyWith(...)` or `instanceOfUpdateProjectRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateProjectRequestCWProxy get copyWith =>
      _$UpdateProjectRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProjectRequest _$UpdateProjectRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateProjectRequest',
  json,
  ($checkedConvert) {
    final val = UpdateProjectRequest(
      title: $checkedConvert('title', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) => $enumDecodeNullable(_$UpdateProjectRequestStatusEnumEnumMap, v),
      ),
      budgetUsd: $checkedConvert('budget_usd', (v) => v as num?),
      deadlineAt: $checkedConvert(
        'deadline_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      planMd: $checkedConvert('plan_md', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'budgetUsd': 'budget_usd',
    'deadlineAt': 'deadline_at',
    'planMd': 'plan_md',
  },
);

Map<String, dynamic> _$UpdateProjectRequestToJson(
  UpdateProjectRequest instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'status': ?_$UpdateProjectRequestStatusEnumEnumMap[instance.status],
  'budget_usd': ?instance.budgetUsd,
  'deadline_at': ?instance.deadlineAt?.toIso8601String(),
  'plan_md': ?instance.planMd,
};

const _$UpdateProjectRequestStatusEnumEnumMap = {
  UpdateProjectRequestStatusEnum.active: 'active',
  UpdateProjectRequestStatusEnum.paused: 'paused',
  UpdateProjectRequestStatusEnum.cancelled: 'cancelled',
};
