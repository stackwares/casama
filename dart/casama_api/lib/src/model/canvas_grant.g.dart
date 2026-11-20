// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_grant.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasGrantCWProxy {
  CanvasGrant botId(String botId);

  CanvasGrant bot(String bot);

  CanvasGrant createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasGrant call({String botId, String bot, DateTime createdAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasGrant.copyWith(...)` or call `instanceOfCanvasGrant.copyWith.fieldName(value)` for a single field.
class _$CanvasGrantCWProxyImpl implements _$CanvasGrantCWProxy {
  const _$CanvasGrantCWProxyImpl(this._value);

  final CanvasGrant _value;

  @override
  CanvasGrant botId(String botId) => call(botId: botId);

  @override
  CanvasGrant bot(String bot) => call(bot: bot);

  @override
  CanvasGrant createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasGrant call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return CanvasGrant(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CanvasGrantCopyWith on CanvasGrant {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasGrant.copyWith(...)` or `instanceOfCanvasGrant.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasGrantCWProxy get copyWith => _$CanvasGrantCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasGrant _$CanvasGrantFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasGrant', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['bot_id', 'bot', 'created_at']);
      final val = CanvasGrant(
        botId: $checkedConvert('bot_id', (v) => v as String),
        bot: $checkedConvert('bot', (v) => v as String),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id', 'createdAt': 'created_at'});

Map<String, dynamic> _$CanvasGrantToJson(CanvasGrant instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'bot': instance.bot,
      'created_at': instance.createdAt.toIso8601String(),
    };
