// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_message.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchMessageCWProxy {
  WatchMessage id(String id);

  WatchMessage role(WatchMessageRoleEnum role);

  WatchMessage text(String text);

  WatchMessage cut(bool cut);

  WatchMessage attachments(List<WatchAttachment> attachments);

  WatchMessage at(DateTime at);

  WatchMessage canSpeak(bool canSpeak);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchMessage call({
    String id,
    WatchMessageRoleEnum role,
    String text,
    bool cut,
    List<WatchAttachment> attachments,
    DateTime at,
    bool canSpeak,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchMessage.copyWith(...)` or call `instanceOfWatchMessage.copyWith.fieldName(value)` for a single field.
class _$WatchMessageCWProxyImpl implements _$WatchMessageCWProxy {
  const _$WatchMessageCWProxyImpl(this._value);

  final WatchMessage _value;

  @override
  WatchMessage id(String id) => call(id: id);

  @override
  WatchMessage role(WatchMessageRoleEnum role) => call(role: role);

  @override
  WatchMessage text(String text) => call(text: text);

  @override
  WatchMessage cut(bool cut) => call(cut: cut);

  @override
  WatchMessage attachments(List<WatchAttachment> attachments) =>
      call(attachments: attachments);

  @override
  WatchMessage at(DateTime at) => call(at: at);

  @override
  WatchMessage canSpeak(bool canSpeak) => call(canSpeak: canSpeak);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchMessage call({
    Object? id = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? cut = const $CopyWithPlaceholder(),
    Object? attachments = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? canSpeak = const $CopyWithPlaceholder(),
  }) {
    return WatchMessage(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as WatchMessageRoleEnum,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      cut: cut == const $CopyWithPlaceholder() || cut == null
          ? _value.cut
          // ignore: cast_nullable_to_non_nullable
          : cut as bool,
      attachments:
          attachments == const $CopyWithPlaceholder() || attachments == null
          ? _value.attachments
          // ignore: cast_nullable_to_non_nullable
          : attachments as List<WatchAttachment>,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      canSpeak: canSpeak == const $CopyWithPlaceholder() || canSpeak == null
          ? _value.canSpeak
          // ignore: cast_nullable_to_non_nullable
          : canSpeak as bool,
    );
  }
}

extension $WatchMessageCopyWith on WatchMessage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchMessage.copyWith(...)` or `instanceOfWatchMessage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchMessageCWProxy get copyWith => _$WatchMessageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchMessage _$WatchMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchMessage', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'role',
          'text',
          'cut',
          'attachments',
          'at',
          'can_speak',
        ],
      );
      final val = WatchMessage(
        id: $checkedConvert('id', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$WatchMessageRoleEnumEnumMap, v),
        ),
        text: $checkedConvert('text', (v) => v as String),
        cut: $checkedConvert('cut', (v) => v as bool),
        attachments: $checkedConvert(
          'attachments',
          (v) => (v as List<dynamic>)
              .map((e) => WatchAttachment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        canSpeak: $checkedConvert('can_speak', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'canSpeak': 'can_speak'});

Map<String, dynamic> _$WatchMessageToJson(WatchMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$WatchMessageRoleEnumEnumMap[instance.role]!,
      'text': instance.text,
      'cut': instance.cut,
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'at': instance.at.toIso8601String(),
      'can_speak': instance.canSpeak,
    };

const _$WatchMessageRoleEnumEnumMap = {
  WatchMessageRoleEnum.user: 'user',
  WatchMessageRoleEnum.assistant: 'assistant',
};
