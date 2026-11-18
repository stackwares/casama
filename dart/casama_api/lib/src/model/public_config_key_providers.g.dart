// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_config_key_providers.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicConfigKeyProvidersCWProxy {
  PublicConfigKeyProviders chat(List<String> chat);

  PublicConfigKeyProviders more(List<String> more);

  PublicConfigKeyProviders cloud(List<String> cloud);

  PublicConfigKeyProviders runsChat(List<String> runsChat);

  PublicConfigKeyProviders hints(Map<String, String>? hints);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfigKeyProviders(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfigKeyProviders(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicConfigKeyProviders call({
    List<String> chat,
    List<String> more,
    List<String> cloud,
    List<String> runsChat,
    Map<String, String>? hints,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicConfigKeyProviders.copyWith(...)` or call `instanceOfPublicConfigKeyProviders.copyWith.fieldName(value)` for a single field.
class _$PublicConfigKeyProvidersCWProxyImpl
    implements _$PublicConfigKeyProvidersCWProxy {
  const _$PublicConfigKeyProvidersCWProxyImpl(this._value);

  final PublicConfigKeyProviders _value;

  @override
  PublicConfigKeyProviders chat(List<String> chat) => call(chat: chat);

  @override
  PublicConfigKeyProviders more(List<String> more) => call(more: more);

  @override
  PublicConfigKeyProviders cloud(List<String> cloud) => call(cloud: cloud);

  @override
  PublicConfigKeyProviders runsChat(List<String> runsChat) =>
      call(runsChat: runsChat);

  @override
  PublicConfigKeyProviders hints(Map<String, String>? hints) =>
      call(hints: hints);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfigKeyProviders(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfigKeyProviders(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicConfigKeyProviders call({
    Object? chat = const $CopyWithPlaceholder(),
    Object? more = const $CopyWithPlaceholder(),
    Object? cloud = const $CopyWithPlaceholder(),
    Object? runsChat = const $CopyWithPlaceholder(),
    Object? hints = const $CopyWithPlaceholder(),
  }) {
    return PublicConfigKeyProviders(
      chat: chat == const $CopyWithPlaceholder() || chat == null
          ? _value.chat
          // ignore: cast_nullable_to_non_nullable
          : chat as List<String>,
      more: more == const $CopyWithPlaceholder() || more == null
          ? _value.more
          // ignore: cast_nullable_to_non_nullable
          : more as List<String>,
      cloud: cloud == const $CopyWithPlaceholder() || cloud == null
          ? _value.cloud
          // ignore: cast_nullable_to_non_nullable
          : cloud as List<String>,
      runsChat: runsChat == const $CopyWithPlaceholder() || runsChat == null
          ? _value.runsChat
          // ignore: cast_nullable_to_non_nullable
          : runsChat as List<String>,
      hints: hints == const $CopyWithPlaceholder()
          ? _value.hints
          // ignore: cast_nullable_to_non_nullable
          : hints as Map<String, String>?,
    );
  }
}

extension $PublicConfigKeyProvidersCopyWith on PublicConfigKeyProviders {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicConfigKeyProviders.copyWith(...)` or `instanceOfPublicConfigKeyProviders.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicConfigKeyProvidersCWProxy get copyWith =>
      _$PublicConfigKeyProvidersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicConfigKeyProviders _$PublicConfigKeyProvidersFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicConfigKeyProviders', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['chat', 'more', 'cloud', 'runs_chat']);
  final val = PublicConfigKeyProviders(
    chat: $checkedConvert(
      'chat',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    more: $checkedConvert(
      'more',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    cloud: $checkedConvert(
      'cloud',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    runsChat: $checkedConvert(
      'runs_chat',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    hints: $checkedConvert(
      'hints',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
    ),
  );
  return val;
}, fieldKeyMap: const {'runsChat': 'runs_chat'});

Map<String, dynamic> _$PublicConfigKeyProvidersToJson(
  PublicConfigKeyProviders instance,
) => <String, dynamic>{
  'chat': instance.chat,
  'more': instance.more,
  'cloud': instance.cloud,
  'runs_chat': instance.runsChat,
  'hints': ?instance.hints,
};
