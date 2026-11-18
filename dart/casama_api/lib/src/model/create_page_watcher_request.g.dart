// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_page_watcher_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatePageWatcherRequestCWProxy {
  CreatePageWatcherRequest botId(String botId);

  CreatePageWatcherRequest name(String name);

  CreatePageWatcherRequest url(String url);

  CreatePageWatcherRequest anchor(String? anchor);

  CreatePageWatcherRequest chars(int? chars);

  CreatePageWatcherRequest condition(String? condition);

  CreatePageWatcherRequest checkEveryMinutes(int? checkEveryMinutes);

  CreatePageWatcherRequest where(CreatePageWatcherRequestWhereEnum? where);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePageWatcherRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePageWatcherRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatePageWatcherRequest call({
    String botId,
    String name,
    String url,
    String? anchor,
    int? chars,
    String? condition,
    int? checkEveryMinutes,
    CreatePageWatcherRequestWhereEnum? where,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatePageWatcherRequest.copyWith(...)` or call `instanceOfCreatePageWatcherRequest.copyWith.fieldName(value)` for a single field.
class _$CreatePageWatcherRequestCWProxyImpl
    implements _$CreatePageWatcherRequestCWProxy {
  const _$CreatePageWatcherRequestCWProxyImpl(this._value);

  final CreatePageWatcherRequest _value;

  @override
  CreatePageWatcherRequest botId(String botId) => call(botId: botId);

  @override
  CreatePageWatcherRequest name(String name) => call(name: name);

  @override
  CreatePageWatcherRequest url(String url) => call(url: url);

  @override
  CreatePageWatcherRequest anchor(String? anchor) => call(anchor: anchor);

  @override
  CreatePageWatcherRequest chars(int? chars) => call(chars: chars);

  @override
  CreatePageWatcherRequest condition(String? condition) =>
      call(condition: condition);

  @override
  CreatePageWatcherRequest checkEveryMinutes(int? checkEveryMinutes) =>
      call(checkEveryMinutes: checkEveryMinutes);

  @override
  CreatePageWatcherRequest where(CreatePageWatcherRequestWhereEnum? where) =>
      call(where: where);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePageWatcherRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePageWatcherRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatePageWatcherRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? anchor = const $CopyWithPlaceholder(),
    Object? chars = const $CopyWithPlaceholder(),
    Object? condition = const $CopyWithPlaceholder(),
    Object? checkEveryMinutes = const $CopyWithPlaceholder(),
    Object? where = const $CopyWithPlaceholder(),
  }) {
    return CreatePageWatcherRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      anchor: anchor == const $CopyWithPlaceholder()
          ? _value.anchor
          // ignore: cast_nullable_to_non_nullable
          : anchor as String?,
      chars: chars == const $CopyWithPlaceholder()
          ? _value.chars
          // ignore: cast_nullable_to_non_nullable
          : chars as int?,
      condition: condition == const $CopyWithPlaceholder()
          ? _value.condition
          // ignore: cast_nullable_to_non_nullable
          : condition as String?,
      checkEveryMinutes: checkEveryMinutes == const $CopyWithPlaceholder()
          ? _value.checkEveryMinutes
          // ignore: cast_nullable_to_non_nullable
          : checkEveryMinutes as int?,
      where: where == const $CopyWithPlaceholder()
          ? _value.where
          // ignore: cast_nullable_to_non_nullable
          : where as CreatePageWatcherRequestWhereEnum?,
    );
  }
}

extension $CreatePageWatcherRequestCopyWith on CreatePageWatcherRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatePageWatcherRequest.copyWith(...)` or `instanceOfCreatePageWatcherRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatePageWatcherRequestCWProxy get copyWith =>
      _$CreatePageWatcherRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePageWatcherRequest _$CreatePageWatcherRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreatePageWatcherRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['bot_id', 'name', 'url']);
    final val = CreatePageWatcherRequest(
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      anchor: $checkedConvert('anchor', (v) => v as String?),
      chars: $checkedConvert('chars', (v) => (v as num?)?.toInt()),
      condition: $checkedConvert('condition', (v) => v as String?),
      checkEveryMinutes: $checkedConvert(
        'check_every_minutes',
        (v) => (v as num?)?.toInt(),
      ),
      where: $checkedConvert(
        'where',
        (v) =>
            $enumDecodeNullable(_$CreatePageWatcherRequestWhereEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'checkEveryMinutes': 'check_every_minutes',
  },
);

Map<String, dynamic> _$CreatePageWatcherRequestToJson(
  CreatePageWatcherRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'name': instance.name,
  'url': instance.url,
  'anchor': ?instance.anchor,
  'chars': ?instance.chars,
  'condition': ?instance.condition,
  'check_every_minutes': ?instance.checkEveryMinutes,
  'where': ?_$CreatePageWatcherRequestWhereEnumEnumMap[instance.where],
};

const _$CreatePageWatcherRequestWhereEnumEnumMap = {
  CreatePageWatcherRequestWhereEnum.server: 'server',
  CreatePageWatcherRequestWhereEnum.mine: 'mine',
};
