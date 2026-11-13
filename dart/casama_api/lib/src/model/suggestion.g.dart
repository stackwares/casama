// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuggestionCWProxy {
  Suggestion id(String id);

  Suggestion botId(String botId);

  Suggestion title(String title);

  Suggestion bodyMd(String bodyMd);

  Suggestion pushText(String? pushText);

  Suggestion proposedAction(SuggestionProposedAction? proposedAction);

  Suggestion sources(List<String> sources);

  Suggestion urgency(SuggestionUrgencyEnum urgency);

  Suggestion expiresAt(DateTime expiresAt);

  Suggestion createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Suggestion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Suggestion(...).copyWith(id: 12, name: "My name")
  /// ```
  Suggestion call({
    String id,
    String botId,
    String title,
    String bodyMd,
    String? pushText,
    SuggestionProposedAction? proposedAction,
    List<String> sources,
    SuggestionUrgencyEnum urgency,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSuggestion.copyWith(...)` or call `instanceOfSuggestion.copyWith.fieldName(value)` for a single field.
class _$SuggestionCWProxyImpl implements _$SuggestionCWProxy {
  const _$SuggestionCWProxyImpl(this._value);

  final Suggestion _value;

  @override
  Suggestion id(String id) => call(id: id);

  @override
  Suggestion botId(String botId) => call(botId: botId);

  @override
  Suggestion title(String title) => call(title: title);

  @override
  Suggestion bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  @override
  Suggestion pushText(String? pushText) => call(pushText: pushText);

  @override
  Suggestion proposedAction(SuggestionProposedAction? proposedAction) =>
      call(proposedAction: proposedAction);

  @override
  Suggestion sources(List<String> sources) => call(sources: sources);

  @override
  Suggestion urgency(SuggestionUrgencyEnum urgency) => call(urgency: urgency);

  @override
  Suggestion expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  Suggestion createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Suggestion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Suggestion(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Suggestion call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
    Object? pushText = const $CopyWithPlaceholder(),
    Object? proposedAction = const $CopyWithPlaceholder(),
    Object? sources = const $CopyWithPlaceholder(),
    Object? urgency = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Suggestion(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
      pushText: pushText == const $CopyWithPlaceholder()
          ? _value.pushText
          // ignore: cast_nullable_to_non_nullable
          : pushText as String?,
      proposedAction: proposedAction == const $CopyWithPlaceholder()
          ? _value.proposedAction
          // ignore: cast_nullable_to_non_nullable
          : proposedAction as SuggestionProposedAction?,
      sources: sources == const $CopyWithPlaceholder() || sources == null
          ? _value.sources
          // ignore: cast_nullable_to_non_nullable
          : sources as List<String>,
      urgency: urgency == const $CopyWithPlaceholder() || urgency == null
          ? _value.urgency
          // ignore: cast_nullable_to_non_nullable
          : urgency as SuggestionUrgencyEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SuggestionCopyWith on Suggestion {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSuggestion.copyWith(...)` or `instanceOfSuggestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuggestionCWProxy get copyWith => _$SuggestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggestion _$SuggestionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Suggestion',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'title',
        'body_md',
        'proposed_action',
        'sources',
        'urgency',
        'expires_at',
        'created_at',
      ],
    );
    final val = Suggestion(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      bodyMd: $checkedConvert('body_md', (v) => v as String),
      pushText: $checkedConvert('push_text', (v) => v as String?),
      proposedAction: $checkedConvert(
        'proposed_action',
        (v) => v == null
            ? null
            : SuggestionProposedAction.fromJson(v as Map<String, dynamic>),
      ),
      sources: $checkedConvert(
        'sources',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      urgency: $checkedConvert(
        'urgency',
        (v) => $enumDecode(_$SuggestionUrgencyEnumEnumMap, v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'bodyMd': 'body_md',
    'pushText': 'push_text',
    'proposedAction': 'proposed_action',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$SuggestionToJson(Suggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'title': instance.title,
      'body_md': instance.bodyMd,
      'push_text': ?instance.pushText,
      'proposed_action': instance.proposedAction?.toJson(),
      'sources': instance.sources,
      'urgency': _$SuggestionUrgencyEnumEnumMap[instance.urgency]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$SuggestionUrgencyEnumEnumMap = {
  SuggestionUrgencyEnum.low: 'low',
  SuggestionUrgencyEnum.normal: 'normal',
  SuggestionUrgencyEnum.urgent: 'urgent',
};
