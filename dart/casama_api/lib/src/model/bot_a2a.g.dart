// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_a2a.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotA2aCWProxy {
  BotA2a workspaceEnabled(bool workspaceEnabled);

  BotA2a published(bool published);

  BotA2a agentCardUrl(String agentCardUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotA2a(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotA2a(...).copyWith(id: 12, name: "My name")
  /// ```
  BotA2a call({bool workspaceEnabled, bool published, String agentCardUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotA2a.copyWith(...)` or call `instanceOfBotA2a.copyWith.fieldName(value)` for a single field.
class _$BotA2aCWProxyImpl implements _$BotA2aCWProxy {
  const _$BotA2aCWProxyImpl(this._value);

  final BotA2a _value;

  @override
  BotA2a workspaceEnabled(bool workspaceEnabled) =>
      call(workspaceEnabled: workspaceEnabled);

  @override
  BotA2a published(bool published) => call(published: published);

  @override
  BotA2a agentCardUrl(String agentCardUrl) => call(agentCardUrl: agentCardUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotA2a(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotA2a(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotA2a call({
    Object? workspaceEnabled = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
    Object? agentCardUrl = const $CopyWithPlaceholder(),
  }) {
    return BotA2a(
      workspaceEnabled:
          workspaceEnabled == const $CopyWithPlaceholder() ||
              workspaceEnabled == null
          ? _value.workspaceEnabled
          // ignore: cast_nullable_to_non_nullable
          : workspaceEnabled as bool,
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
      agentCardUrl:
          agentCardUrl == const $CopyWithPlaceholder() || agentCardUrl == null
          ? _value.agentCardUrl
          // ignore: cast_nullable_to_non_nullable
          : agentCardUrl as String,
    );
  }
}

extension $BotA2aCopyWith on BotA2a {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotA2a.copyWith(...)` or `instanceOfBotA2a.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotA2aCWProxy get copyWith => _$BotA2aCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotA2a _$BotA2aFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotA2a',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['workspace_enabled', 'published', 'agent_card_url'],
    );
    final val = BotA2a(
      workspaceEnabled: $checkedConvert('workspace_enabled', (v) => v as bool),
      published: $checkedConvert('published', (v) => v as bool),
      agentCardUrl: $checkedConvert('agent_card_url', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'workspaceEnabled': 'workspace_enabled',
    'agentCardUrl': 'agent_card_url',
  },
);

Map<String, dynamic> _$BotA2aToJson(BotA2a instance) => <String, dynamic>{
  'workspace_enabled': instance.workspaceEnabled,
  'published': instance.published,
  'agent_card_url': instance.agentCardUrl,
};
