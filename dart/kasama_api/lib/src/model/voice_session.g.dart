// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceSessionCWProxy {
  VoiceSession provider(VoiceSessionProviderEnum provider);

  VoiceSession model(String model);

  VoiceSession clientSecret(String clientSecret);

  VoiceSession expiresAt(DateTime expiresAt);

  VoiceSession connectUrl(String connectUrl);

  VoiceSession conversationId(String conversationId);

  VoiceSession tools(int tools);

  VoiceSession speakFirst(bool speakFirst);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSession(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceSession call({
    VoiceSessionProviderEnum provider,
    String model,
    String clientSecret,
    DateTime expiresAt,
    String connectUrl,
    String conversationId,
    int tools,
    bool speakFirst,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceSession.copyWith(...)` or call `instanceOfVoiceSession.copyWith.fieldName(value)` for a single field.
class _$VoiceSessionCWProxyImpl implements _$VoiceSessionCWProxy {
  const _$VoiceSessionCWProxyImpl(this._value);

  final VoiceSession _value;

  @override
  VoiceSession provider(VoiceSessionProviderEnum provider) =>
      call(provider: provider);

  @override
  VoiceSession model(String model) => call(model: model);

  @override
  VoiceSession clientSecret(String clientSecret) =>
      call(clientSecret: clientSecret);

  @override
  VoiceSession expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  VoiceSession connectUrl(String connectUrl) => call(connectUrl: connectUrl);

  @override
  VoiceSession conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  VoiceSession tools(int tools) => call(tools: tools);

  @override
  VoiceSession speakFirst(bool speakFirst) => call(speakFirst: speakFirst);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSession(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceSession call({
    Object? provider = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? clientSecret = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? connectUrl = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? speakFirst = const $CopyWithPlaceholder(),
  }) {
    return VoiceSession(
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as VoiceSessionProviderEnum,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      clientSecret:
          clientSecret == const $CopyWithPlaceholder() || clientSecret == null
          ? _value.clientSecret
          // ignore: cast_nullable_to_non_nullable
          : clientSecret as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      connectUrl:
          connectUrl == const $CopyWithPlaceholder() || connectUrl == null
          ? _value.connectUrl
          // ignore: cast_nullable_to_non_nullable
          : connectUrl as String,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as int,
      speakFirst:
          speakFirst == const $CopyWithPlaceholder() || speakFirst == null
          ? _value.speakFirst
          // ignore: cast_nullable_to_non_nullable
          : speakFirst as bool,
    );
  }
}

extension $VoiceSessionCopyWith on VoiceSession {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceSession.copyWith(...)` or `instanceOfVoiceSession.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceSessionCWProxy get copyWith => _$VoiceSessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSession _$VoiceSessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VoiceSession',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'provider',
            'model',
            'client_secret',
            'expires_at',
            'connect_url',
            'conversation_id',
            'tools',
            'speak_first',
          ],
        );
        final val = VoiceSession(
          provider: $checkedConvert(
            'provider',
            (v) => $enumDecode(_$VoiceSessionProviderEnumEnumMap, v),
          ),
          model: $checkedConvert('model', (v) => v as String),
          clientSecret: $checkedConvert('client_secret', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          connectUrl: $checkedConvert('connect_url', (v) => v as String),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String,
          ),
          tools: $checkedConvert('tools', (v) => (v as num).toInt()),
          speakFirst: $checkedConvert('speak_first', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientSecret': 'client_secret',
        'expiresAt': 'expires_at',
        'connectUrl': 'connect_url',
        'conversationId': 'conversation_id',
        'speakFirst': 'speak_first',
      },
    );

Map<String, dynamic> _$VoiceSessionToJson(VoiceSession instance) =>
    <String, dynamic>{
      'provider': _$VoiceSessionProviderEnumEnumMap[instance.provider]!,
      'model': instance.model,
      'client_secret': instance.clientSecret,
      'expires_at': instance.expiresAt.toIso8601String(),
      'connect_url': instance.connectUrl,
      'conversation_id': instance.conversationId,
      'tools': instance.tools,
      'speak_first': instance.speakFirst,
    };

const _$VoiceSessionProviderEnumEnumMap = {
  VoiceSessionProviderEnum.openai: 'openai',
};
