// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasCWProxy {
  Canvas id(String id);

  Canvas orgId(String orgId);

  Canvas name(String name);

  Canvas botId(String botId);

  Canvas bot(String bot);

  Canvas botAvatar(String botAvatar);

  Canvas status(CanvasStatusEnum status);

  Canvas hideWhenLocked(bool hideWhenLocked);

  Canvas version(int version);

  Canvas setAt(DateTime setAt);

  Canvas until(DateTime? until);

  Canvas link(String link);

  Canvas rotation(CanvasRotation? rotation);

  Canvas entries(List<CanvasEntry> entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Canvas(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Canvas(...).copyWith(id: 12, name: "My name")
  /// ```
  Canvas call({
    String id,
    String orgId,
    String name,
    String botId,
    String bot,
    String botAvatar,
    CanvasStatusEnum status,
    bool hideWhenLocked,
    int version,
    DateTime setAt,
    DateTime? until,
    String link,
    CanvasRotation? rotation,
    List<CanvasEntry> entries,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvas.copyWith(...)` or call `instanceOfCanvas.copyWith.fieldName(value)` for a single field.
class _$CanvasCWProxyImpl implements _$CanvasCWProxy {
  const _$CanvasCWProxyImpl(this._value);

  final Canvas _value;

  @override
  Canvas id(String id) => call(id: id);

  @override
  Canvas orgId(String orgId) => call(orgId: orgId);

  @override
  Canvas name(String name) => call(name: name);

  @override
  Canvas botId(String botId) => call(botId: botId);

  @override
  Canvas bot(String bot) => call(bot: bot);

  @override
  Canvas botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  Canvas status(CanvasStatusEnum status) => call(status: status);

  @override
  Canvas hideWhenLocked(bool hideWhenLocked) =>
      call(hideWhenLocked: hideWhenLocked);

  @override
  Canvas version(int version) => call(version: version);

  @override
  Canvas setAt(DateTime setAt) => call(setAt: setAt);

  @override
  Canvas until(DateTime? until) => call(until: until);

  @override
  Canvas link(String link) => call(link: link);

  @override
  Canvas rotation(CanvasRotation? rotation) => call(rotation: rotation);

  @override
  Canvas entries(List<CanvasEntry> entries) => call(entries: entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Canvas(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Canvas(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Canvas call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? hideWhenLocked = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? setAt = const $CopyWithPlaceholder(),
    Object? until = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
    Object? rotation = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
  }) {
    return Canvas(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      botAvatar: botAvatar == const $CopyWithPlaceholder() || botAvatar == null
          ? _value.botAvatar
          // ignore: cast_nullable_to_non_nullable
          : botAvatar as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CanvasStatusEnum,
      hideWhenLocked:
          hideWhenLocked == const $CopyWithPlaceholder() ||
              hideWhenLocked == null
          ? _value.hideWhenLocked
          // ignore: cast_nullable_to_non_nullable
          : hideWhenLocked as bool,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      setAt: setAt == const $CopyWithPlaceholder() || setAt == null
          ? _value.setAt
          // ignore: cast_nullable_to_non_nullable
          : setAt as DateTime,
      until: until == const $CopyWithPlaceholder()
          ? _value.until
          // ignore: cast_nullable_to_non_nullable
          : until as DateTime?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
      rotation: rotation == const $CopyWithPlaceholder()
          ? _value.rotation
          // ignore: cast_nullable_to_non_nullable
          : rotation as CanvasRotation?,
      entries: entries == const $CopyWithPlaceholder() || entries == null
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as List<CanvasEntry>,
    );
  }
}

extension $CanvasCopyWith on Canvas {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvas.copyWith(...)` or `instanceOfCanvas.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasCWProxy get copyWith => _$CanvasCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Canvas _$CanvasFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Canvas',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'name',
        'bot_id',
        'bot',
        'bot_avatar',
        'status',
        'hide_when_locked',
        'version',
        'set_at',
        'until',
        'link',
        'rotation',
        'entries',
      ],
    );
    final val = Canvas(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      bot: $checkedConvert('bot', (v) => v as String),
      botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$CanvasStatusEnumEnumMap, v),
      ),
      hideWhenLocked: $checkedConvert('hide_when_locked', (v) => v as bool),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
      setAt: $checkedConvert('set_at', (v) => DateTime.parse(v as String)),
      until: $checkedConvert(
        'until',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      link: $checkedConvert('link', (v) => v as String),
      rotation: $checkedConvert(
        'rotation',
        (v) => v == null
            ? null
            : CanvasRotation.fromJson(v as Map<String, dynamic>),
      ),
      entries: $checkedConvert(
        'entries',
        (v) => (v as List<dynamic>)
            .map((e) => CanvasEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'botAvatar': 'bot_avatar',
    'hideWhenLocked': 'hide_when_locked',
    'setAt': 'set_at',
  },
);

Map<String, dynamic> _$CanvasToJson(Canvas instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'name': instance.name,
  'bot_id': instance.botId,
  'bot': instance.bot,
  'bot_avatar': instance.botAvatar,
  'status': _$CanvasStatusEnumEnumMap[instance.status]!,
  'hide_when_locked': instance.hideWhenLocked,
  'version': instance.version,
  'set_at': instance.setAt.toIso8601String(),
  'until': instance.until?.toIso8601String(),
  'link': instance.link,
  'rotation': instance.rotation?.toJson(),
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};

const _$CanvasStatusEnumEnumMap = {
  CanvasStatusEnum.waiting: 'waiting',
  CanvasStatusEnum.shown: 'shown',
  CanvasStatusEnum.paused: 'paused',
};
