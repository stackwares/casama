// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reset_audience.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LimitResetAudienceCWProxy {
  LimitResetAudience planCodes(List<String>? planCodes);

  LimitResetAudience createdBefore(DateTime? createdBefore);

  LimitResetAudience limitedWithinDays(int? limitedWithinDays);

  LimitResetAudience workspaceIds(List<String>? workspaceIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetAudience(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetAudience(...).copyWith(id: 12, name: "My name")
  /// ```
  LimitResetAudience call({
    List<String>? planCodes,
    DateTime? createdBefore,
    int? limitedWithinDays,
    List<String>? workspaceIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLimitResetAudience.copyWith(...)` or call `instanceOfLimitResetAudience.copyWith.fieldName(value)` for a single field.
class _$LimitResetAudienceCWProxyImpl implements _$LimitResetAudienceCWProxy {
  const _$LimitResetAudienceCWProxyImpl(this._value);

  final LimitResetAudience _value;

  @override
  LimitResetAudience planCodes(List<String>? planCodes) =>
      call(planCodes: planCodes);

  @override
  LimitResetAudience createdBefore(DateTime? createdBefore) =>
      call(createdBefore: createdBefore);

  @override
  LimitResetAudience limitedWithinDays(int? limitedWithinDays) =>
      call(limitedWithinDays: limitedWithinDays);

  @override
  LimitResetAudience workspaceIds(List<String>? workspaceIds) =>
      call(workspaceIds: workspaceIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetAudience(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetAudience(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LimitResetAudience call({
    Object? planCodes = const $CopyWithPlaceholder(),
    Object? createdBefore = const $CopyWithPlaceholder(),
    Object? limitedWithinDays = const $CopyWithPlaceholder(),
    Object? workspaceIds = const $CopyWithPlaceholder(),
  }) {
    return LimitResetAudience(
      planCodes: planCodes == const $CopyWithPlaceholder()
          ? _value.planCodes
          // ignore: cast_nullable_to_non_nullable
          : planCodes as List<String>?,
      createdBefore: createdBefore == const $CopyWithPlaceholder()
          ? _value.createdBefore
          // ignore: cast_nullable_to_non_nullable
          : createdBefore as DateTime?,
      limitedWithinDays: limitedWithinDays == const $CopyWithPlaceholder()
          ? _value.limitedWithinDays
          // ignore: cast_nullable_to_non_nullable
          : limitedWithinDays as int?,
      workspaceIds: workspaceIds == const $CopyWithPlaceholder()
          ? _value.workspaceIds
          // ignore: cast_nullable_to_non_nullable
          : workspaceIds as List<String>?,
    );
  }
}

extension $LimitResetAudienceCopyWith on LimitResetAudience {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLimitResetAudience.copyWith(...)` or `instanceOfLimitResetAudience.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LimitResetAudienceCWProxy get copyWith =>
      _$LimitResetAudienceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitResetAudience _$LimitResetAudienceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LimitResetAudience',
      json,
      ($checkedConvert) {
        final val = LimitResetAudience(
          planCodes: $checkedConvert(
            'plan_codes',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          ),
          createdBefore: $checkedConvert(
            'created_before',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          limitedWithinDays: $checkedConvert(
            'limited_within_days',
            (v) => (v as num?)?.toInt(),
          ),
          workspaceIds: $checkedConvert(
            'workspace_ids',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'planCodes': 'plan_codes',
        'createdBefore': 'created_before',
        'limitedWithinDays': 'limited_within_days',
        'workspaceIds': 'workspace_ids',
      },
    );

Map<String, dynamic> _$LimitResetAudienceToJson(LimitResetAudience instance) =>
    <String, dynamic>{
      'plan_codes': ?instance.planCodes,
      'created_before': ?instance.createdBefore?.toIso8601String(),
      'limited_within_days': ?instance.limitedWithinDays,
      'workspace_ids': ?instance.workspaceIds,
    };
