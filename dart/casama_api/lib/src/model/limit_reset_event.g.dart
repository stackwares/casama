// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reset_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LimitResetEventCWProxy {
  LimitResetEvent id(String id);

  LimitResetEvent campaignId(String? campaignId);

  LimitResetEvent resetId(String? resetId);

  LimitResetEvent orgId(String? orgId);

  LimitResetEvent actorId(String? actorId);

  LimitResetEvent action(String action);

  LimitResetEvent before(Map<String, Object?>? before);

  LimitResetEvent after(Map<String, Object?>? after);

  LimitResetEvent createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  LimitResetEvent call({
    String id,
    String? campaignId,
    String? resetId,
    String? orgId,
    String? actorId,
    String action,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLimitResetEvent.copyWith(...)` or call `instanceOfLimitResetEvent.copyWith.fieldName(value)` for a single field.
class _$LimitResetEventCWProxyImpl implements _$LimitResetEventCWProxy {
  const _$LimitResetEventCWProxyImpl(this._value);

  final LimitResetEvent _value;

  @override
  LimitResetEvent id(String id) => call(id: id);

  @override
  LimitResetEvent campaignId(String? campaignId) =>
      call(campaignId: campaignId);

  @override
  LimitResetEvent resetId(String? resetId) => call(resetId: resetId);

  @override
  LimitResetEvent orgId(String? orgId) => call(orgId: orgId);

  @override
  LimitResetEvent actorId(String? actorId) => call(actorId: actorId);

  @override
  LimitResetEvent action(String action) => call(action: action);

  @override
  LimitResetEvent before(Map<String, Object?>? before) => call(before: before);

  @override
  LimitResetEvent after(Map<String, Object?>? after) => call(after: after);

  @override
  LimitResetEvent createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LimitResetEvent call({
    Object? id = const $CopyWithPlaceholder(),
    Object? campaignId = const $CopyWithPlaceholder(),
    Object? resetId = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? actorId = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? after = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return LimitResetEvent(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      campaignId: campaignId == const $CopyWithPlaceholder()
          ? _value.campaignId
          // ignore: cast_nullable_to_non_nullable
          : campaignId as String?,
      resetId: resetId == const $CopyWithPlaceholder()
          ? _value.resetId
          // ignore: cast_nullable_to_non_nullable
          : resetId as String?,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      actorId: actorId == const $CopyWithPlaceholder()
          ? _value.actorId
          // ignore: cast_nullable_to_non_nullable
          : actorId as String?,
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as Map<String, Object?>?,
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Map<String, Object?>?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $LimitResetEventCopyWith on LimitResetEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLimitResetEvent.copyWith(...)` or `instanceOfLimitResetEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LimitResetEventCWProxy get copyWith => _$LimitResetEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitResetEvent _$LimitResetEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LimitResetEvent',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'campaign_id',
            'reset_id',
            'org_id',
            'actor_id',
            'action',
            'before',
            'after',
            'created_at',
          ],
        );
        final val = LimitResetEvent(
          id: $checkedConvert('id', (v) => v as String),
          campaignId: $checkedConvert('campaign_id', (v) => v as String?),
          resetId: $checkedConvert('reset_id', (v) => v as String?),
          orgId: $checkedConvert('org_id', (v) => v as String?),
          actorId: $checkedConvert('actor_id', (v) => v as String?),
          action: $checkedConvert('action', (v) => v as String),
          before: $checkedConvert('before', (v) => v as Map<String, dynamic>?),
          after: $checkedConvert('after', (v) => v as Map<String, dynamic>?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'campaignId': 'campaign_id',
        'resetId': 'reset_id',
        'orgId': 'org_id',
        'actorId': 'actor_id',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$LimitResetEventToJson(LimitResetEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'campaign_id': instance.campaignId,
      'reset_id': instance.resetId,
      'org_id': instance.orgId,
      'actor_id': instance.actorId,
      'action': instance.action,
      'before': instance.before,
      'after': instance.after,
      'created_at': instance.createdAt.toIso8601String(),
    };
