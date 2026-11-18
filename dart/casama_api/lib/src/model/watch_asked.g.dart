// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_asked.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchAskedCWProxy {
  WatchAsked conversationId(String conversationId);

  WatchAsked messageId(String messageId);

  WatchAsked runId(String? runId);

  WatchAsked heard(String heard);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAsked(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAsked(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchAsked call({
    String conversationId,
    String messageId,
    String? runId,
    String heard,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchAsked.copyWith(...)` or call `instanceOfWatchAsked.copyWith.fieldName(value)` for a single field.
class _$WatchAskedCWProxyImpl implements _$WatchAskedCWProxy {
  const _$WatchAskedCWProxyImpl(this._value);

  final WatchAsked _value;

  @override
  WatchAsked conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  WatchAsked messageId(String messageId) => call(messageId: messageId);

  @override
  WatchAsked runId(String? runId) => call(runId: runId);

  @override
  WatchAsked heard(String heard) => call(heard: heard);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchAsked(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchAsked(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchAsked call({
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? messageId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? heard = const $CopyWithPlaceholder(),
  }) {
    return WatchAsked(
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
      heard: heard == const $CopyWithPlaceholder() || heard == null
          ? _value.heard
          // ignore: cast_nullable_to_non_nullable
          : heard as String,
    );
  }
}

extension $WatchAskedCopyWith on WatchAsked {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchAsked.copyWith(...)` or `instanceOfWatchAsked.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchAskedCWProxy get copyWith => _$WatchAskedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchAsked _$WatchAskedFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchAsked',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['conversation_id', 'message_id', 'run_id', 'heard'],
    );
    final val = WatchAsked(
      conversationId: $checkedConvert('conversation_id', (v) => v as String),
      messageId: $checkedConvert('message_id', (v) => v as String),
      runId: $checkedConvert('run_id', (v) => v as String?),
      heard: $checkedConvert('heard', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'conversationId': 'conversation_id',
    'messageId': 'message_id',
    'runId': 'run_id',
  },
);

Map<String, dynamic> _$WatchAskedToJson(WatchAsked instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'message_id': instance.messageId,
      'run_id': instance.runId,
      'heard': instance.heard,
    };
