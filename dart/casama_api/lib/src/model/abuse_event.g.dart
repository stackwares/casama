// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abuse_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AbuseEventCWProxy {
  AbuseEvent id(String id);

  AbuseEvent orgId(String? orgId);

  AbuseEvent orgName(String? orgName);

  AbuseEvent computerId(String? computerId);

  AbuseEvent kind(String kind);

  AbuseEvent action(String action);

  AbuseEvent detail(Map<String, Object?> detail);

  AbuseEvent createdAt(String createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AbuseEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AbuseEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  AbuseEvent call({
    String id,
    String? orgId,
    String? orgName,
    String? computerId,
    String kind,
    String action,
    Map<String, Object?> detail,
    String createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAbuseEvent.copyWith(...)` or call `instanceOfAbuseEvent.copyWith.fieldName(value)` for a single field.
class _$AbuseEventCWProxyImpl implements _$AbuseEventCWProxy {
  const _$AbuseEventCWProxyImpl(this._value);

  final AbuseEvent _value;

  @override
  AbuseEvent id(String id) => call(id: id);

  @override
  AbuseEvent orgId(String? orgId) => call(orgId: orgId);

  @override
  AbuseEvent orgName(String? orgName) => call(orgName: orgName);

  @override
  AbuseEvent computerId(String? computerId) => call(computerId: computerId);

  @override
  AbuseEvent kind(String kind) => call(kind: kind);

  @override
  AbuseEvent action(String action) => call(action: action);

  @override
  AbuseEvent detail(Map<String, Object?> detail) => call(detail: detail);

  @override
  AbuseEvent createdAt(String createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AbuseEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AbuseEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AbuseEvent call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AbuseEvent(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      orgName: orgName == const $CopyWithPlaceholder()
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String?,
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String?,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      detail: detail == const $CopyWithPlaceholder() || detail == null
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as Map<String, Object?>,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
    );
  }
}

extension $AbuseEventCopyWith on AbuseEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAbuseEvent.copyWith(...)` or `instanceOfAbuseEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AbuseEventCWProxy get copyWith => _$AbuseEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbuseEvent _$AbuseEventFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AbuseEvent',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'org_name',
        'computer_id',
        'kind',
        'action',
        'detail',
        'created_at',
      ],
    );
    final val = AbuseEvent(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String?),
      orgName: $checkedConvert('org_name', (v) => v as String?),
      computerId: $checkedConvert('computer_id', (v) => v as String?),
      kind: $checkedConvert('kind', (v) => v as String),
      action: $checkedConvert('action', (v) => v as String),
      detail: $checkedConvert('detail', (v) => v as Map<String, dynamic>),
      createdAt: $checkedConvert('created_at', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'orgName': 'org_name',
    'computerId': 'computer_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$AbuseEventToJson(AbuseEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'computer_id': instance.computerId,
      'kind': instance.kind,
      'action': instance.action,
      'detail': instance.detail,
      'created_at': instance.createdAt,
    };
