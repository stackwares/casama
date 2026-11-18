// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_submission.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySubmissionCWProxy {
  GallerySubmission id(String id);

  GallerySubmission type(GallerySubmissionKind type);

  GallerySubmission itemId(String itemId);

  GallerySubmission name(String name);

  GallerySubmission prUrl(String? prUrl);

  GallerySubmission status(GallerySubmissionStatusEnum status);

  GallerySubmission createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySubmission call({
    String id,
    GallerySubmissionKind type,
    String itemId,
    String name,
    String? prUrl,
    GallerySubmissionStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySubmission.copyWith(...)` or call `instanceOfGallerySubmission.copyWith.fieldName(value)` for a single field.
class _$GallerySubmissionCWProxyImpl implements _$GallerySubmissionCWProxy {
  const _$GallerySubmissionCWProxyImpl(this._value);

  final GallerySubmission _value;

  @override
  GallerySubmission id(String id) => call(id: id);

  @override
  GallerySubmission type(GallerySubmissionKind type) => call(type: type);

  @override
  GallerySubmission itemId(String itemId) => call(itemId: itemId);

  @override
  GallerySubmission name(String name) => call(name: name);

  @override
  GallerySubmission prUrl(String? prUrl) => call(prUrl: prUrl);

  @override
  GallerySubmission status(GallerySubmissionStatusEnum status) =>
      call(status: status);

  @override
  GallerySubmission createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySubmission call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? itemId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? prUrl = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return GallerySubmission(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GallerySubmissionKind,
      itemId: itemId == const $CopyWithPlaceholder() || itemId == null
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      prUrl: prUrl == const $CopyWithPlaceholder()
          ? _value.prUrl
          // ignore: cast_nullable_to_non_nullable
          : prUrl as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GallerySubmissionStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $GallerySubmissionCopyWith on GallerySubmission {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySubmission.copyWith(...)` or `instanceOfGallerySubmission.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySubmissionCWProxy get copyWith =>
      _$GallerySubmissionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySubmission _$GallerySubmissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GallerySubmission',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'type',
            'item_id',
            'name',
            'pr_url',
            'status',
            'created_at',
          ],
        );
        final val = GallerySubmission(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert(
            'type',
            (v) => $enumDecode(_$GallerySubmissionKindEnumMap, v),
          ),
          itemId: $checkedConvert('item_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          prUrl: $checkedConvert('pr_url', (v) => v as String?),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$GallerySubmissionStatusEnumEnumMap, v),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'itemId': 'item_id',
        'prUrl': 'pr_url',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$GallerySubmissionToJson(GallerySubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$GallerySubmissionKindEnumMap[instance.type]!,
      'item_id': instance.itemId,
      'name': instance.name,
      'pr_url': instance.prUrl,
      'status': _$GallerySubmissionStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$GallerySubmissionKindEnumMap = {
  GallerySubmissionKind.theme: 'theme',
  GallerySubmissionKind.scheme: 'scheme',
  GallerySubmissionKind.wallpaper: 'wallpaper',
  GallerySubmissionKind.skill: 'skill',
  GallerySubmissionKind.routine: 'routine',
  GallerySubmissionKind.bot: 'bot',
};

const _$GallerySubmissionStatusEnumEnumMap = {
  GallerySubmissionStatusEnum.open: 'open',
  GallerySubmissionStatusEnum.merged: 'merged',
  GallerySubmissionStatusEnum.closed: 'closed',
  GallerySubmissionStatusEnum.failed: 'failed',
};
