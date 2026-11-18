// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_last_message.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotLastMessageCWProxy {
  BotLastMessage text(String text);

  BotLastMessage from(BotLastMessageFromEnum from);

  BotLastMessage fileName(String? fileName);

  BotLastMessage fileMime(String? fileMime);

  BotLastMessage conversationId(String conversationId);

  BotLastMessage at(DateTime at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLastMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLastMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  BotLastMessage call({
    String text,
    BotLastMessageFromEnum from,
    String? fileName,
    String? fileMime,
    String conversationId,
    DateTime at,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotLastMessage.copyWith(...)` or call `instanceOfBotLastMessage.copyWith.fieldName(value)` for a single field.
class _$BotLastMessageCWProxyImpl implements _$BotLastMessageCWProxy {
  const _$BotLastMessageCWProxyImpl(this._value);

  final BotLastMessage _value;

  @override
  BotLastMessage text(String text) => call(text: text);

  @override
  BotLastMessage from(BotLastMessageFromEnum from) => call(from: from);

  @override
  BotLastMessage fileName(String? fileName) => call(fileName: fileName);

  @override
  BotLastMessage fileMime(String? fileMime) => call(fileMime: fileMime);

  @override
  BotLastMessage conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  BotLastMessage at(DateTime at) => call(at: at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLastMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLastMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotLastMessage call({
    Object? text = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? fileName = const $CopyWithPlaceholder(),
    Object? fileMime = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return BotLastMessage(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as BotLastMessageFromEnum,
      fileName: fileName == const $CopyWithPlaceholder()
          ? _value.fileName
          // ignore: cast_nullable_to_non_nullable
          : fileName as String?,
      fileMime: fileMime == const $CopyWithPlaceholder()
          ? _value.fileMime
          // ignore: cast_nullable_to_non_nullable
          : fileMime as String?,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $BotLastMessageCopyWith on BotLastMessage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotLastMessage.copyWith(...)` or `instanceOfBotLastMessage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotLastMessageCWProxy get copyWith => _$BotLastMessageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotLastMessage _$BotLastMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BotLastMessage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'text',
            'from',
            'file_name',
            'file_mime',
            'conversation_id',
            'at',
          ],
        );
        final val = BotLastMessage(
          text: $checkedConvert('text', (v) => v as String),
          from: $checkedConvert(
            'from',
            (v) => $enumDecode(_$BotLastMessageFromEnumEnumMap, v),
          ),
          fileName: $checkedConvert('file_name', (v) => v as String?),
          fileMime: $checkedConvert('file_mime', (v) => v as String?),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String,
          ),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'fileName': 'file_name',
        'fileMime': 'file_mime',
        'conversationId': 'conversation_id',
      },
    );

Map<String, dynamic> _$BotLastMessageToJson(BotLastMessage instance) =>
    <String, dynamic>{
      'text': instance.text,
      'from': _$BotLastMessageFromEnumEnumMap[instance.from]!,
      'file_name': instance.fileName,
      'file_mime': instance.fileMime,
      'conversation_id': instance.conversationId,
      'at': instance.at.toIso8601String(),
    };

const _$BotLastMessageFromEnumEnumMap = {
  BotLastMessageFromEnum.you: 'you',
  BotLastMessageFromEnum.bot: 'bot',
  BotLastMessageFromEnum.someone: 'someone',
};
