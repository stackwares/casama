// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryRequestCWProxy {
  GalleryRequest id(String id);

  GalleryRequest kind(GalleryKind kind);

  GalleryRequest title(String title);

  GalleryRequest details(String details);

  GalleryRequest status(GalleryRequestStatusEnum status);

  GalleryRequest doneItemKey(String? doneItemKey);

  GalleryRequest votes(int votes);

  GalleryRequest voted(bool voted);

  GalleryRequest mine(bool mine);

  GalleryRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryRequest call({
    String id,
    GalleryKind kind,
    String title,
    String details,
    GalleryRequestStatusEnum status,
    String? doneItemKey,
    int votes,
    bool voted,
    bool mine,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryRequest.copyWith(...)` or call `instanceOfGalleryRequest.copyWith.fieldName(value)` for a single field.
class _$GalleryRequestCWProxyImpl implements _$GalleryRequestCWProxy {
  const _$GalleryRequestCWProxyImpl(this._value);

  final GalleryRequest _value;

  @override
  GalleryRequest id(String id) => call(id: id);

  @override
  GalleryRequest kind(GalleryKind kind) => call(kind: kind);

  @override
  GalleryRequest title(String title) => call(title: title);

  @override
  GalleryRequest details(String details) => call(details: details);

  @override
  GalleryRequest status(GalleryRequestStatusEnum status) =>
      call(status: status);

  @override
  GalleryRequest doneItemKey(String? doneItemKey) =>
      call(doneItemKey: doneItemKey);

  @override
  GalleryRequest votes(int votes) => call(votes: votes);

  @override
  GalleryRequest voted(bool voted) => call(voted: voted);

  @override
  GalleryRequest mine(bool mine) => call(mine: mine);

  @override
  GalleryRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? doneItemKey = const $CopyWithPlaceholder(),
    Object? votes = const $CopyWithPlaceholder(),
    Object? voted = const $CopyWithPlaceholder(),
    Object? mine = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return GalleryRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GalleryKind,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      details: details == const $CopyWithPlaceholder() || details == null
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GalleryRequestStatusEnum,
      doneItemKey: doneItemKey == const $CopyWithPlaceholder()
          ? _value.doneItemKey
          // ignore: cast_nullable_to_non_nullable
          : doneItemKey as String?,
      votes: votes == const $CopyWithPlaceholder() || votes == null
          ? _value.votes
          // ignore: cast_nullable_to_non_nullable
          : votes as int,
      voted: voted == const $CopyWithPlaceholder() || voted == null
          ? _value.voted
          // ignore: cast_nullable_to_non_nullable
          : voted as bool,
      mine: mine == const $CopyWithPlaceholder() || mine == null
          ? _value.mine
          // ignore: cast_nullable_to_non_nullable
          : mine as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $GalleryRequestCopyWith on GalleryRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryRequest.copyWith(...)` or `instanceOfGalleryRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryRequestCWProxy get copyWith => _$GalleryRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryRequest _$GalleryRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GalleryRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'kind',
            'title',
            'details',
            'status',
            'done_item_key',
            'votes',
            'voted',
            'mine',
            'created_at',
          ],
        );
        final val = GalleryRequest(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$GalleryKindEnumMap, v),
          ),
          title: $checkedConvert('title', (v) => v as String),
          details: $checkedConvert('details', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$GalleryRequestStatusEnumEnumMap, v),
          ),
          doneItemKey: $checkedConvert('done_item_key', (v) => v as String?),
          votes: $checkedConvert('votes', (v) => (v as num).toInt()),
          voted: $checkedConvert('voted', (v) => v as bool),
          mine: $checkedConvert('mine', (v) => v as bool),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'doneItemKey': 'done_item_key',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$GalleryRequestToJson(GalleryRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$GalleryKindEnumMap[instance.kind]!,
      'title': instance.title,
      'details': instance.details,
      'status': _$GalleryRequestStatusEnumEnumMap[instance.status]!,
      'done_item_key': instance.doneItemKey,
      'votes': instance.votes,
      'voted': instance.voted,
      'mine': instance.mine,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$GalleryKindEnumMap = {
  GalleryKind.theme: 'theme',
  GalleryKind.scheme: 'scheme',
  GalleryKind.wallpaper: 'wallpaper',
  GalleryKind.skill: 'skill',
  GalleryKind.app: 'app',
  GalleryKind.bot: 'bot',
  GalleryKind.routine: 'routine',
  GalleryKind.plugin: 'plugin',
};

const _$GalleryRequestStatusEnumEnumMap = {
  GalleryRequestStatusEnum.open: 'open',
  GalleryRequestStatusEnum.planned: 'planned',
  GalleryRequestStatusEnum.done: 'done',
  GalleryRequestStatusEnum.declined: 'declined',
};
