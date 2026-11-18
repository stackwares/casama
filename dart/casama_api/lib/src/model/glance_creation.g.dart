// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_creation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceCreationCWProxy {
  GlanceCreation id(String id);

  GlanceCreation kind(GlanceCreationKindEnum kind);

  GlanceCreation title(String title);

  GlanceCreation bot(String? bot);

  GlanceCreation hasCover(bool hasCover);

  GlanceCreation version(int version);

  GlanceCreation at(DateTime at);

  GlanceCreation link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceCreation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceCreation(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceCreation call({
    String id,
    GlanceCreationKindEnum kind,
    String title,
    String? bot,
    bool hasCover,
    int version,
    DateTime at,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceCreation.copyWith(...)` or call `instanceOfGlanceCreation.copyWith.fieldName(value)` for a single field.
class _$GlanceCreationCWProxyImpl implements _$GlanceCreationCWProxy {
  const _$GlanceCreationCWProxyImpl(this._value);

  final GlanceCreation _value;

  @override
  GlanceCreation id(String id) => call(id: id);

  @override
  GlanceCreation kind(GlanceCreationKindEnum kind) => call(kind: kind);

  @override
  GlanceCreation title(String title) => call(title: title);

  @override
  GlanceCreation bot(String? bot) => call(bot: bot);

  @override
  GlanceCreation hasCover(bool hasCover) => call(hasCover: hasCover);

  @override
  GlanceCreation version(int version) => call(version: version);

  @override
  GlanceCreation at(DateTime at) => call(at: at);

  @override
  GlanceCreation link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceCreation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceCreation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceCreation call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? hasCover = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceCreation(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GlanceCreationKindEnum,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      bot: bot == const $CopyWithPlaceholder()
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String?,
      hasCover: hasCover == const $CopyWithPlaceholder() || hasCover == null
          ? _value.hasCover
          // ignore: cast_nullable_to_non_nullable
          : hasCover as bool,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceCreationCopyWith on GlanceCreation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceCreation.copyWith(...)` or `instanceOfGlanceCreation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceCreationCWProxy get copyWith => _$GlanceCreationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceCreation _$GlanceCreationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceCreation', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'kind',
          'title',
          'bot',
          'has_cover',
          'version',
          'at',
          'link',
        ],
      );
      final val = GlanceCreation(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$GlanceCreationKindEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
        bot: $checkedConvert('bot', (v) => v as String?),
        hasCover: $checkedConvert('has_cover', (v) => v as bool),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        link: $checkedConvert('link', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'hasCover': 'has_cover'});

Map<String, dynamic> _$GlanceCreationToJson(GlanceCreation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$GlanceCreationKindEnumEnumMap[instance.kind]!,
      'title': instance.title,
      'bot': instance.bot,
      'has_cover': instance.hasCover,
      'version': instance.version,
      'at': instance.at.toIso8601String(),
      'link': instance.link,
    };

const _$GlanceCreationKindEnumEnumMap = {
  GlanceCreationKindEnum.page: 'page',
  GlanceCreationKindEnum.image: 'image',
  GlanceCreationKindEnum.video: 'video',
  GlanceCreationKindEnum.audio: 'audio',
  GlanceCreationKindEnum.document: 'document',
  GlanceCreationKindEnum.file: 'file',
};
