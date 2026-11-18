// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_done.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceDoneCWProxy {
  GlanceDone botId(String botId);

  GlanceDone bot(String bot);

  GlanceDone botAvatar(String botAvatar);

  GlanceDone title(String title);

  GlanceDone at(DateTime at);

  GlanceDone link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceDone(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceDone(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceDone call({
    String botId,
    String bot,
    String botAvatar,
    String title,
    DateTime at,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceDone.copyWith(...)` or call `instanceOfGlanceDone.copyWith.fieldName(value)` for a single field.
class _$GlanceDoneCWProxyImpl implements _$GlanceDoneCWProxy {
  const _$GlanceDoneCWProxyImpl(this._value);

  final GlanceDone _value;

  @override
  GlanceDone botId(String botId) => call(botId: botId);

  @override
  GlanceDone bot(String bot) => call(bot: bot);

  @override
  GlanceDone botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  GlanceDone title(String title) => call(title: title);

  @override
  GlanceDone at(DateTime at) => call(at: at);

  @override
  GlanceDone link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceDone(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceDone(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceDone call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceDone(
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
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceDoneCopyWith on GlanceDone {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceDone.copyWith(...)` or `instanceOfGlanceDone.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceDoneCWProxy get copyWith => _$GlanceDoneCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceDone _$GlanceDoneFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceDone', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'bot_id',
          'bot',
          'bot_avatar',
          'title',
          'at',
          'link',
        ],
      );
      final val = GlanceDone(
        botId: $checkedConvert('bot_id', (v) => v as String),
        bot: $checkedConvert('bot', (v) => v as String),
        botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        link: $checkedConvert('link', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id', 'botAvatar': 'bot_avatar'});

Map<String, dynamic> _$GlanceDoneToJson(GlanceDone instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'bot': instance.bot,
      'bot_avatar': instance.botAvatar,
      'title': instance.title,
      'at': instance.at.toIso8601String(),
      'link': instance.link,
    };
