// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_chat_reply.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportChatReplyCWProxy {
  SupportChatReply reply(String reply);

  SupportChatReply sources(List<SupportSource> sources);

  SupportChatReply places(List<SupportPlace>? places);

  SupportChatReply handoff(SupportChatReplyHandoff? handoff);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatReply(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatReply(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportChatReply call({
    String reply,
    List<SupportSource> sources,
    List<SupportPlace>? places,
    SupportChatReplyHandoff? handoff,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportChatReply.copyWith(...)` or call `instanceOfSupportChatReply.copyWith.fieldName(value)` for a single field.
class _$SupportChatReplyCWProxyImpl implements _$SupportChatReplyCWProxy {
  const _$SupportChatReplyCWProxyImpl(this._value);

  final SupportChatReply _value;

  @override
  SupportChatReply reply(String reply) => call(reply: reply);

  @override
  SupportChatReply sources(List<SupportSource> sources) =>
      call(sources: sources);

  @override
  SupportChatReply places(List<SupportPlace>? places) => call(places: places);

  @override
  SupportChatReply handoff(SupportChatReplyHandoff? handoff) =>
      call(handoff: handoff);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatReply(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatReply(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportChatReply call({
    Object? reply = const $CopyWithPlaceholder(),
    Object? sources = const $CopyWithPlaceholder(),
    Object? places = const $CopyWithPlaceholder(),
    Object? handoff = const $CopyWithPlaceholder(),
  }) {
    return SupportChatReply(
      reply: reply == const $CopyWithPlaceholder() || reply == null
          ? _value.reply
          // ignore: cast_nullable_to_non_nullable
          : reply as String,
      sources: sources == const $CopyWithPlaceholder() || sources == null
          ? _value.sources
          // ignore: cast_nullable_to_non_nullable
          : sources as List<SupportSource>,
      places: places == const $CopyWithPlaceholder()
          ? _value.places
          // ignore: cast_nullable_to_non_nullable
          : places as List<SupportPlace>?,
      handoff: handoff == const $CopyWithPlaceholder()
          ? _value.handoff
          // ignore: cast_nullable_to_non_nullable
          : handoff as SupportChatReplyHandoff?,
    );
  }
}

extension $SupportChatReplyCopyWith on SupportChatReply {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportChatReply.copyWith(...)` or `instanceOfSupportChatReply.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportChatReplyCWProxy get copyWith => _$SupportChatReplyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportChatReply _$SupportChatReplyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportChatReply', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reply', 'sources', 'handoff']);
      final val = SupportChatReply(
        reply: $checkedConvert('reply', (v) => v as String),
        sources: $checkedConvert(
          'sources',
          (v) => (v as List<dynamic>)
              .map((e) => SupportSource.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        places: $checkedConvert(
          'places',
          (v) => (v as List<dynamic>?)
              ?.map((e) => SupportPlace.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        handoff: $checkedConvert(
          'handoff',
          (v) => v == null
              ? null
              : SupportChatReplyHandoff.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SupportChatReplyToJson(SupportChatReply instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'sources': instance.sources.map((e) => e.toJson()).toList(),
      'places': ?instance.places?.map((e) => e.toJson()).toList(),
      'handoff': instance.handoff?.toJson(),
    };
