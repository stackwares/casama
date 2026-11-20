// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grant_comp_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GrantCompRequestCWProxy {
  GrantCompRequest email(String? email);

  GrantCompRequest userId(String? userId);

  GrantCompRequest orgId(String? orgId);

  GrantCompRequest planCode(String planCode);

  GrantCompRequest months(int months);

  GrantCompRequest note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GrantCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GrantCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GrantCompRequest call({
    String? email,
    String? userId,
    String? orgId,
    String planCode,
    int months,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGrantCompRequest.copyWith(...)` or call `instanceOfGrantCompRequest.copyWith.fieldName(value)` for a single field.
class _$GrantCompRequestCWProxyImpl implements _$GrantCompRequestCWProxy {
  const _$GrantCompRequestCWProxyImpl(this._value);

  final GrantCompRequest _value;

  @override
  GrantCompRequest email(String? email) => call(email: email);

  @override
  GrantCompRequest userId(String? userId) => call(userId: userId);

  @override
  GrantCompRequest orgId(String? orgId) => call(orgId: orgId);

  @override
  GrantCompRequest planCode(String planCode) => call(planCode: planCode);

  @override
  GrantCompRequest months(int months) => call(months: months);

  @override
  GrantCompRequest note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GrantCompRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GrantCompRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GrantCompRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? months = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return GrantCompRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      months: months == const $CopyWithPlaceholder() || months == null
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as int,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $GrantCompRequestCopyWith on GrantCompRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGrantCompRequest.copyWith(...)` or `instanceOfGrantCompRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GrantCompRequestCWProxy get copyWith => _$GrantCompRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrantCompRequest _$GrantCompRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GrantCompRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['plan_code', 'months']);
        final val = GrantCompRequest(
          email: $checkedConvert('email', (v) => v as String?),
          userId: $checkedConvert('user_id', (v) => v as String?),
          orgId: $checkedConvert('org_id', (v) => v as String?),
          planCode: $checkedConvert('plan_code', (v) => v as String),
          months: $checkedConvert('months', (v) => (v as num).toInt()),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'orgId': 'org_id',
        'planCode': 'plan_code',
      },
    );

Map<String, dynamic> _$GrantCompRequestToJson(GrantCompRequest instance) =>
    <String, dynamic>{
      'email': ?instance.email,
      'user_id': ?instance.userId,
      'org_id': ?instance.orgId,
      'plan_code': instance.planCode,
      'months': instance.months,
      'note': ?instance.note,
    };
