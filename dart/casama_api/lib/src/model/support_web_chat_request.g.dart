// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_chat_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebChatRequestCWProxy {
  SupportWebChatRequest session(String session);

  SupportWebChatRequest messages(
    List<SupportWebChatRequestMessagesInner> messages,
  );

  SupportWebChatRequest page(String? page);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebChatRequest call({
    String session,
    List<SupportWebChatRequestMessagesInner> messages,
    String? page,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebChatRequest.copyWith(...)` or call `instanceOfSupportWebChatRequest.copyWith.fieldName(value)` for a single field.
class _$SupportWebChatRequestCWProxyImpl
    implements _$SupportWebChatRequestCWProxy {
  const _$SupportWebChatRequestCWProxyImpl(this._value);

  final SupportWebChatRequest _value;

  @override
  SupportWebChatRequest session(String session) => call(session: session);

  @override
  SupportWebChatRequest messages(
    List<SupportWebChatRequestMessagesInner> messages,
  ) => call(messages: messages);

  @override
  SupportWebChatRequest page(String? page) => call(page: page);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebChatRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebChatRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebChatRequest call({
    Object? session = const $CopyWithPlaceholder(),
    Object? messages = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return SupportWebChatRequest(
      session: session == const $CopyWithPlaceholder() || session == null
          ? _value.session
          // ignore: cast_nullable_to_non_nullable
          : session as String,
      messages: messages == const $CopyWithPlaceholder() || messages == null
          ? _value.messages
          // ignore: cast_nullable_to_non_nullable
          : messages as List<SupportWebChatRequestMessagesInner>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as String?,
    );
  }
}

extension $SupportWebChatRequestCopyWith on SupportWebChatRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebChatRequest.copyWith(...)` or `instanceOfSupportWebChatRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebChatRequestCWProxy get copyWith =>
      _$SupportWebChatRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebChatRequest _$SupportWebChatRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportWebChatRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['session', 'messages']);
  final val = SupportWebChatRequest(
    session: $checkedConvert('session', (v) => v as String),
    messages: $checkedConvert(
      'messages',
      (v) => (v as List<dynamic>)
          .map(
            (e) => SupportWebChatRequestMessagesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    page: $checkedConvert('page', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$SupportWebChatRequestToJson(
  SupportWebChatRequest instance,
) => <String, dynamic>{
  'session': instance.session,
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'page': ?instance.page,
};
