// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_stats_revisions_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillStatsRevisionsInnerCWProxy {
  SkillStatsRevisionsInner id(String id);

  SkillStatsRevisionsInner description(String description);

  SkillStatsRevisionsInner bodyMd(String bodyMd);

  SkillStatsRevisionsInner byBot(bool byBot);

  SkillStatsRevisionsInner createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillStatsRevisionsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillStatsRevisionsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillStatsRevisionsInner call({
    String id,
    String description,
    String bodyMd,
    bool byBot,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillStatsRevisionsInner.copyWith(...)` or call `instanceOfSkillStatsRevisionsInner.copyWith.fieldName(value)` for a single field.
class _$SkillStatsRevisionsInnerCWProxyImpl
    implements _$SkillStatsRevisionsInnerCWProxy {
  const _$SkillStatsRevisionsInnerCWProxyImpl(this._value);

  final SkillStatsRevisionsInner _value;

  @override
  SkillStatsRevisionsInner id(String id) => call(id: id);

  @override
  SkillStatsRevisionsInner description(String description) =>
      call(description: description);

  @override
  SkillStatsRevisionsInner bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  @override
  SkillStatsRevisionsInner byBot(bool byBot) => call(byBot: byBot);

  @override
  SkillStatsRevisionsInner createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillStatsRevisionsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillStatsRevisionsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillStatsRevisionsInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
    Object? byBot = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return SkillStatsRevisionsInner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
      byBot: byBot == const $CopyWithPlaceholder() || byBot == null
          ? _value.byBot
          // ignore: cast_nullable_to_non_nullable
          : byBot as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SkillStatsRevisionsInnerCopyWith on SkillStatsRevisionsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillStatsRevisionsInner.copyWith(...)` or `instanceOfSkillStatsRevisionsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillStatsRevisionsInnerCWProxy get copyWith =>
      _$SkillStatsRevisionsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillStatsRevisionsInner _$SkillStatsRevisionsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SkillStatsRevisionsInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'description',
        'body_md',
        'by_bot',
        'created_at',
      ],
    );
    final val = SkillStatsRevisionsInner(
      id: $checkedConvert('id', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      bodyMd: $checkedConvert('body_md', (v) => v as String),
      byBot: $checkedConvert('by_bot', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'bodyMd': 'body_md',
    'byBot': 'by_bot',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$SkillStatsRevisionsInnerToJson(
  SkillStatsRevisionsInner instance,
) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'body_md': instance.bodyMd,
  'by_bot': instance.byBot,
  'created_at': instance.createdAt.toIso8601String(),
};
