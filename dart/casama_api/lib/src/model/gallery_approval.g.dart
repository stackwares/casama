// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_approval.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryApprovalCWProxy {
  GalleryApproval id(String id);

  GalleryApproval orgId(String orgId);

  GalleryApproval type(GalleryWorkspaceKind type);

  GalleryApproval pack(bool? pack);

  GalleryApproval itemId(String itemId);

  GalleryApproval name(String name);

  GalleryApproval requestedBy(String? requestedBy);

  GalleryApproval requestedByName(String? requestedByName);

  GalleryApproval reason(String reason);

  GalleryApproval status(GalleryApprovalStatusEnum status);

  GalleryApproval error(String? error);

  GalleryApproval createdAt(DateTime createdAt);

  GalleryApproval decidedAt(DateTime? decidedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryApproval call({
    String id,
    String orgId,
    GalleryWorkspaceKind type,
    bool? pack,
    String itemId,
    String name,
    String? requestedBy,
    String? requestedByName,
    String reason,
    GalleryApprovalStatusEnum status,
    String? error,
    DateTime createdAt,
    DateTime? decidedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryApproval.copyWith(...)` or call `instanceOfGalleryApproval.copyWith.fieldName(value)` for a single field.
class _$GalleryApprovalCWProxyImpl implements _$GalleryApprovalCWProxy {
  const _$GalleryApprovalCWProxyImpl(this._value);

  final GalleryApproval _value;

  @override
  GalleryApproval id(String id) => call(id: id);

  @override
  GalleryApproval orgId(String orgId) => call(orgId: orgId);

  @override
  GalleryApproval type(GalleryWorkspaceKind type) => call(type: type);

  @override
  GalleryApproval pack(bool? pack) => call(pack: pack);

  @override
  GalleryApproval itemId(String itemId) => call(itemId: itemId);

  @override
  GalleryApproval name(String name) => call(name: name);

  @override
  GalleryApproval requestedBy(String? requestedBy) =>
      call(requestedBy: requestedBy);

  @override
  GalleryApproval requestedByName(String? requestedByName) =>
      call(requestedByName: requestedByName);

  @override
  GalleryApproval reason(String reason) => call(reason: reason);

  @override
  GalleryApproval status(GalleryApprovalStatusEnum status) =>
      call(status: status);

  @override
  GalleryApproval error(String? error) => call(error: error);

  @override
  GalleryApproval createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  GalleryApproval decidedAt(DateTime? decidedAt) => call(decidedAt: decidedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryApproval(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryApproval(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryApproval call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? pack = const $CopyWithPlaceholder(),
    Object? itemId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? requestedBy = const $CopyWithPlaceholder(),
    Object? requestedByName = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? decidedAt = const $CopyWithPlaceholder(),
  }) {
    return GalleryApproval(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryWorkspaceKind,
      pack: pack == const $CopyWithPlaceholder()
          ? _value.pack
          // ignore: cast_nullable_to_non_nullable
          : pack as bool?,
      itemId: itemId == const $CopyWithPlaceholder() || itemId == null
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      requestedBy: requestedBy == const $CopyWithPlaceholder()
          ? _value.requestedBy
          // ignore: cast_nullable_to_non_nullable
          : requestedBy as String?,
      requestedByName: requestedByName == const $CopyWithPlaceholder()
          ? _value.requestedByName
          // ignore: cast_nullable_to_non_nullable
          : requestedByName as String?,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GalleryApprovalStatusEnum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      decidedAt: decidedAt == const $CopyWithPlaceholder()
          ? _value.decidedAt
          // ignore: cast_nullable_to_non_nullable
          : decidedAt as DateTime?,
    );
  }
}

extension $GalleryApprovalCopyWith on GalleryApproval {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryApproval.copyWith(...)` or `instanceOfGalleryApproval.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryApprovalCWProxy get copyWith => _$GalleryApprovalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryApproval _$GalleryApprovalFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GalleryApproval',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'org_id',
            'type',
            'item_id',
            'name',
            'requested_by',
            'requested_by_name',
            'reason',
            'status',
            'error',
            'created_at',
            'decided_at',
          ],
        );
        final val = GalleryApproval(
          id: $checkedConvert('id', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String),
          type: $checkedConvert(
            'type',
            (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
          ),
          pack: $checkedConvert('pack', (v) => v as bool?),
          itemId: $checkedConvert('item_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          requestedBy: $checkedConvert('requested_by', (v) => v as String?),
          requestedByName: $checkedConvert(
            'requested_by_name',
            (v) => v as String?,
          ),
          reason: $checkedConvert('reason', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$GalleryApprovalStatusEnumEnumMap, v),
          ),
          error: $checkedConvert('error', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          decidedAt: $checkedConvert(
            'decided_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'itemId': 'item_id',
        'requestedBy': 'requested_by',
        'requestedByName': 'requested_by_name',
        'createdAt': 'created_at',
        'decidedAt': 'decided_at',
      },
    );

Map<String, dynamic> _$GalleryApprovalToJson(GalleryApproval instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'type': _$GalleryWorkspaceKindEnumMap[instance.type]!,
      'pack': ?instance.pack,
      'item_id': instance.itemId,
      'name': instance.name,
      'requested_by': instance.requestedBy,
      'requested_by_name': instance.requestedByName,
      'reason': instance.reason,
      'status': _$GalleryApprovalStatusEnumEnumMap[instance.status]!,
      'error': instance.error,
      'created_at': instance.createdAt.toIso8601String(),
      'decided_at': instance.decidedAt?.toIso8601String(),
    };

const _$GalleryWorkspaceKindEnumMap = {
  GalleryWorkspaceKind.skill: 'skill',
  GalleryWorkspaceKind.app: 'app',
  GalleryWorkspaceKind.bot: 'bot',
  GalleryWorkspaceKind.routine: 'routine',
  GalleryWorkspaceKind.plugin: 'plugin',
};

const _$GalleryApprovalStatusEnumEnumMap = {
  GalleryApprovalStatusEnum.pending: 'pending',
  GalleryApprovalStatusEnum.approved: 'approved',
  GalleryApprovalStatusEnum.denied: 'denied',
  GalleryApprovalStatusEnum.failed: 'failed',
};
