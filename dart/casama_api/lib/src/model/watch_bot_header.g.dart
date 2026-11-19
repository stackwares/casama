// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_bot_header.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchBotHeaderCWProxy {
  WatchBotHeader id(String id);

  WatchBotHeader name(String name);

  WatchBotHeader avatar(String avatar);

  WatchBotHeader status(WatchBotHeaderStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchBotHeader(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchBotHeader(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchBotHeader call({
    String id,
    String name,
    String avatar,
    WatchBotHeaderStatusEnum status,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchBotHeader.copyWith(...)` or call `instanceOfWatchBotHeader.copyWith.fieldName(value)` for a single field.
class _$WatchBotHeaderCWProxyImpl implements _$WatchBotHeaderCWProxy {
  const _$WatchBotHeaderCWProxyImpl(this._value);

  final WatchBotHeader _value;

  @override
  WatchBotHeader id(String id) => call(id: id);

  @override
  WatchBotHeader name(String name) => call(name: name);

  @override
  WatchBotHeader avatar(String avatar) => call(avatar: avatar);

  @override
  WatchBotHeader status(WatchBotHeaderStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchBotHeader(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchBotHeader(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchBotHeader call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? avatar = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return WatchBotHeader(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      avatar: avatar == const $CopyWithPlaceholder() || avatar == null
          ? _value.avatar
          // ignore: cast_nullable_to_non_nullable
          : avatar as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as WatchBotHeaderStatusEnum,
    );
  }
}

extension $WatchBotHeaderCopyWith on WatchBotHeader {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchBotHeader.copyWith(...)` or `instanceOfWatchBotHeader.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchBotHeaderCWProxy get copyWith => _$WatchBotHeaderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchBotHeader _$WatchBotHeaderFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchBotHeader', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'avatar', 'status']);
      final val = WatchBotHeader(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        avatar: $checkedConvert('avatar', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$WatchBotHeaderStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WatchBotHeaderToJson(WatchBotHeader instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'status': _$WatchBotHeaderStatusEnumEnumMap[instance.status]!,
    };

const _$WatchBotHeaderStatusEnumEnumMap = {
  WatchBotHeaderStatusEnum.idle: 'idle',
  WatchBotHeaderStatusEnum.working: 'working',
  WatchBotHeaderStatusEnum.waiting: 'waiting',
  WatchBotHeaderStatusEnum.disabled: 'disabled',
};
