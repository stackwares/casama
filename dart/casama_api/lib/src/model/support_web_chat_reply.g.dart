// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_chat_reply.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebChatReplyCWProxy {
  SupportWebChatReply reply(String reply);

  SupportWebChatReply sources(List<SupportSource> sources);

  SupportWebChatReply places(List<SupportPlace>? places);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatReply(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatReply(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebChatReply call({
    String reply,
    List<SupportSource> sources,
    List<SupportPlace>? places,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebChatReply.copyWith(...)` or call `instanceOfSupportWebChatReply.copyWith.fieldName(value)` for a single field.
class _$SupportWebChatReplyCWProxyImpl implements _$SupportWebChatReplyCWProxy {
  const _$SupportWebChatReplyCWProxyImpl(this._value);

  final SupportWebChatReply _value;

  @override
  SupportWebChatReply reply(String reply) => call(reply: reply);

  @override
  SupportWebChatReply sources(List<SupportSource> sources) =>
      call(sources: sources);

  @override
  SupportWebChatReply places(List<SupportPlace>? places) =>
      call(places: places);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatReply(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatReply(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebChatReply call({
    Object? reply = const $CopyWithPlaceholder(),
    Object? sources = const $CopyWithPlaceholder(),
    Object? places = const $CopyWithPlaceholder(),
  }) {
    return SupportWebChatReply(
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
    );
  }
}

extension $SupportWebChatReplyCopyWith on SupportWebChatReply {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebChatReply.copyWith(...)` or `instanceOfSupportWebChatReply.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebChatReplyCWProxy get copyWith =>
      _$SupportWebChatReplyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebChatReply _$SupportWebChatReplyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportWebChatReply', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reply', 'sources']);
      final val = SupportWebChatReply(
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
      );
      return val;
    });

Map<String, dynamic> _$SupportWebChatReplyToJson(
  SupportWebChatReply instance,
) => <String, dynamic>{
  'reply': instance.reply,
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'places': ?instance.places?.map((e) => e.toJson()).toList(),
};
