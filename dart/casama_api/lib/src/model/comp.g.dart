// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comp.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompCWProxy {
  Comp id(String id);

  Comp orgId(String orgId);

  Comp orgName(String? orgName);

  Comp userId(String? userId);

  Comp email(String? email);

  Comp planCode(String planCode);

  Comp months(int months);

  Comp startsAt(DateTime startsAt);

  Comp endsAt(DateTime endsAt);

  Comp from(CompFromEnum from);

  Comp codeId(String? codeId);

  Comp note(String? note);

  Comp endedAt(DateTime? endedAt);

  Comp endReason(String? endReason);

  Comp createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Comp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Comp(...).copyWith(id: 12, name: "My name")
  /// ```
  Comp call({
    String id,
    String orgId,
    String? orgName,
    String? userId,
    String? email,
    String planCode,
    int months,
    DateTime startsAt,
    DateTime endsAt,
    CompFromEnum from,
    String? codeId,
    String? note,
    DateTime? endedAt,
    String? endReason,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComp.copyWith(...)` or call `instanceOfComp.copyWith.fieldName(value)` for a single field.
class _$CompCWProxyImpl implements _$CompCWProxy {
  const _$CompCWProxyImpl(this._value);

  final Comp _value;

  @override
  Comp id(String id) => call(id: id);

  @override
  Comp orgId(String orgId) => call(orgId: orgId);

  @override
  Comp orgName(String? orgName) => call(orgName: orgName);

  @override
  Comp userId(String? userId) => call(userId: userId);

  @override
  Comp email(String? email) => call(email: email);

  @override
  Comp planCode(String planCode) => call(planCode: planCode);

  @override
  Comp months(int months) => call(months: months);

  @override
  Comp startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  Comp endsAt(DateTime endsAt) => call(endsAt: endsAt);

  @override
  Comp from(CompFromEnum from) => call(from: from);

  @override
  Comp codeId(String? codeId) => call(codeId: codeId);

  @override
  Comp note(String? note) => call(note: note);

  @override
  Comp endedAt(DateTime? endedAt) => call(endedAt: endedAt);

  @override
  Comp endReason(String? endReason) => call(endReason: endReason);

  @override
  Comp createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Comp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Comp(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Comp call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? months = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? codeId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? endedAt = const $CopyWithPlaceholder(),
    Object? endReason = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Comp(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      orgName: orgName == const $CopyWithPlaceholder()
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String?,
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      months: months == const $CopyWithPlaceholder() || months == null
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as int,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      endsAt: endsAt == const $CopyWithPlaceholder() || endsAt == null
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime,
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as CompFromEnum,
      codeId: codeId == const $CopyWithPlaceholder()
          ? _value.codeId
          // ignore: cast_nullable_to_non_nullable
          : codeId as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      endedAt: endedAt == const $CopyWithPlaceholder()
          ? _value.endedAt
          // ignore: cast_nullable_to_non_nullable
          : endedAt as DateTime?,
      endReason: endReason == const $CopyWithPlaceholder()
          ? _value.endReason
          // ignore: cast_nullable_to_non_nullable
          : endReason as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CompCopyWith on Comp {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComp.copyWith(...)` or `instanceOfComp.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompCWProxy get copyWith => _$CompCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comp _$CompFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Comp',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'org_name',
        'user_id',
        'email',
        'plan_code',
        'months',
        'starts_at',
        'ends_at',
        'from',
        'code_id',
        'note',
        'ended_at',
        'end_reason',
        'created_at',
      ],
    );
    final val = Comp(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      orgName: $checkedConvert('org_name', (v) => v as String?),
      userId: $checkedConvert('user_id', (v) => v as String?),
      email: $checkedConvert('email', (v) => v as String?),
      planCode: $checkedConvert('plan_code', (v) => v as String),
      months: $checkedConvert('months', (v) => (v as num).toInt()),
      startsAt: $checkedConvert(
        'starts_at',
        (v) => DateTime.parse(v as String),
      ),
      endsAt: $checkedConvert('ends_at', (v) => DateTime.parse(v as String)),
      from: $checkedConvert(
        'from',
        (v) => $enumDecode(_$CompFromEnumEnumMap, v),
      ),
      codeId: $checkedConvert('code_id', (v) => v as String?),
      note: $checkedConvert('note', (v) => v as String?),
      endedAt: $checkedConvert(
        'ended_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      endReason: $checkedConvert('end_reason', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'orgName': 'org_name',
    'userId': 'user_id',
    'planCode': 'plan_code',
    'startsAt': 'starts_at',
    'endsAt': 'ends_at',
    'codeId': 'code_id',
    'endedAt': 'ended_at',
    'endReason': 'end_reason',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CompToJson(Comp instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'org_name': instance.orgName,
  'user_id': instance.userId,
  'email': instance.email,
  'plan_code': instance.planCode,
  'months': instance.months,
  'starts_at': instance.startsAt.toIso8601String(),
  'ends_at': instance.endsAt.toIso8601String(),
  'from': _$CompFromEnumEnumMap[instance.from]!,
  'code_id': instance.codeId,
  'note': instance.note,
  'ended_at': instance.endedAt?.toIso8601String(),
  'end_reason': instance.endReason,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$CompFromEnumEnumMap = {
  CompFromEnum.grant: 'grant',
  CompFromEnum.code: 'code',
};
