// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChannelEventCWProxy {
  ChannelEvent id(String id);

  ChannelEvent direction(ChannelEventDirectionEnum direction);

  ChannelEvent status(ChannelEventStatusEnum status);

  ChannelEvent sender(String? sender);

  ChannelEvent preview(String? preview);

  ChannelEvent detail(String? detail);

  ChannelEvent createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ChannelEvent call({
    String id,
    ChannelEventDirectionEnum direction,
    ChannelEventStatusEnum status,
    String? sender,
    String? preview,
    String? detail,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChannelEvent.copyWith(...)` or call `instanceOfChannelEvent.copyWith.fieldName(value)` for a single field.
class _$ChannelEventCWProxyImpl implements _$ChannelEventCWProxy {
  const _$ChannelEventCWProxyImpl(this._value);

  final ChannelEvent _value;

  @override
  ChannelEvent id(String id) => call(id: id);

  @override
  ChannelEvent direction(ChannelEventDirectionEnum direction) =>
      call(direction: direction);

  @override
  ChannelEvent status(ChannelEventStatusEnum status) => call(status: status);

  @override
  ChannelEvent sender(String? sender) => call(sender: sender);

  @override
  ChannelEvent preview(String? preview) => call(preview: preview);

  @override
  ChannelEvent detail(String? detail) => call(detail: detail);

  @override
  ChannelEvent createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChannelEvent call({
    Object? id = const $CopyWithPlaceholder(),
    Object? direction = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? sender = const $CopyWithPlaceholder(),
    Object? preview = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ChannelEvent(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      direction: direction == const $CopyWithPlaceholder() || direction == null
          ? _value.direction
          // ignore: cast_nullable_to_non_nullable
          : direction as ChannelEventDirectionEnum,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ChannelEventStatusEnum,
      sender: sender == const $CopyWithPlaceholder()
          ? _value.sender
          // ignore: cast_nullable_to_non_nullable
          : sender as String?,
      preview: preview == const $CopyWithPlaceholder()
          ? _value.preview
          // ignore: cast_nullable_to_non_nullable
          : preview as String?,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ChannelEventCopyWith on ChannelEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChannelEvent.copyWith(...)` or `instanceOfChannelEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChannelEventCWProxy get copyWith => _$ChannelEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelEvent _$ChannelEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChannelEvent', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'direction',
          'status',
          'sender',
          'preview',
          'detail',
          'created_at',
        ],
      );
      final val = ChannelEvent(
        id: $checkedConvert('id', (v) => v as String),
        direction: $checkedConvert(
          'direction',
          (v) => $enumDecode(_$ChannelEventDirectionEnumEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ChannelEventStatusEnumEnumMap, v),
        ),
        sender: $checkedConvert('sender', (v) => v as String?),
        preview: $checkedConvert('preview', (v) => v as String?),
        detail: $checkedConvert('detail', (v) => v as String?),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$ChannelEventToJson(ChannelEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'direction': _$ChannelEventDirectionEnumEnumMap[instance.direction]!,
      'status': _$ChannelEventStatusEnumEnumMap[instance.status]!,
      'sender': instance.sender,
      'preview': instance.preview,
      'detail': instance.detail,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ChannelEventDirectionEnumEnumMap = {
  ChannelEventDirectionEnum.in_: 'in',
  ChannelEventDirectionEnum.out_: 'out',
};

const _$ChannelEventStatusEnumEnumMap = {
  ChannelEventStatusEnum.accepted: 'accepted',
  ChannelEventStatusEnum.ignored: 'ignored',
  ChannelEventStatusEnum.routine: 'routine',
  ChannelEventStatusEnum.sent: 'sent',
  ChannelEventStatusEnum.failed: 'failed',
};
