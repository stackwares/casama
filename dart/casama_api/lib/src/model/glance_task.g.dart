// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_task.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceTaskCWProxy {
  GlanceTask id(String id);

  GlanceTask title(String title);

  GlanceTask status(GlanceTaskStatusEnum status);

  GlanceTask bot(String? bot);

  GlanceTask link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTask(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTask(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceTask call({
    String id,
    String title,
    GlanceTaskStatusEnum status,
    String? bot,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceTask.copyWith(...)` or call `instanceOfGlanceTask.copyWith.fieldName(value)` for a single field.
class _$GlanceTaskCWProxyImpl implements _$GlanceTaskCWProxy {
  const _$GlanceTaskCWProxyImpl(this._value);

  final GlanceTask _value;

  @override
  GlanceTask id(String id) => call(id: id);

  @override
  GlanceTask title(String title) => call(title: title);

  @override
  GlanceTask status(GlanceTaskStatusEnum status) => call(status: status);

  @override
  GlanceTask bot(String? bot) => call(bot: bot);

  @override
  GlanceTask link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTask(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTask(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceTask call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceTask(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GlanceTaskStatusEnum,
      bot: bot == const $CopyWithPlaceholder()
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceTaskCopyWith on GlanceTask {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceTask.copyWith(...)` or `instanceOfGlanceTask.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceTaskCWProxy get copyWith => _$GlanceTaskCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceTask _$GlanceTaskFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceTask', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'title', 'status', 'bot', 'link'],
      );
      final val = GlanceTask(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$GlanceTaskStatusEnumEnumMap, v),
        ),
        bot: $checkedConvert('bot', (v) => v as String?),
        link: $checkedConvert('link', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GlanceTaskToJson(GlanceTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': _$GlanceTaskStatusEnumEnumMap[instance.status]!,
      'bot': instance.bot,
      'link': instance.link,
    };

const _$GlanceTaskStatusEnumEnumMap = {
  GlanceTaskStatusEnum.todo: 'todo',
  GlanceTaskStatusEnum.inProgress: 'in_progress',
  GlanceTaskStatusEnum.inReview: 'in_review',
  GlanceTaskStatusEnum.blocked: 'blocked',
  GlanceTaskStatusEnum.done: 'done',
};
