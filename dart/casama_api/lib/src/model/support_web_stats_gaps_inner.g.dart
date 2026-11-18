// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_stats_gaps_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebStatsGapsInnerCWProxy {
  SupportWebStatsGapsInner question(String question);

  SupportWebStatsGapsInner page(String? page);

  SupportWebStatsGapsInner createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebStatsGapsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebStatsGapsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebStatsGapsInner call({
    String question,
    String? page,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebStatsGapsInner.copyWith(...)` or call `instanceOfSupportWebStatsGapsInner.copyWith.fieldName(value)` for a single field.
class _$SupportWebStatsGapsInnerCWProxyImpl
    implements _$SupportWebStatsGapsInnerCWProxy {
  const _$SupportWebStatsGapsInnerCWProxyImpl(this._value);

  final SupportWebStatsGapsInner _value;

  @override
  SupportWebStatsGapsInner question(String question) =>
      call(question: question);

  @override
  SupportWebStatsGapsInner page(String? page) => call(page: page);

  @override
  SupportWebStatsGapsInner createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebStatsGapsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebStatsGapsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebStatsGapsInner call({
    Object? question = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return SupportWebStatsGapsInner(
      question: question == const $CopyWithPlaceholder() || question == null
          ? _value.question
          // ignore: cast_nullable_to_non_nullable
          : question as String,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SupportWebStatsGapsInnerCopyWith on SupportWebStatsGapsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebStatsGapsInner.copyWith(...)` or `instanceOfSupportWebStatsGapsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebStatsGapsInnerCWProxy get copyWith =>
      _$SupportWebStatsGapsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebStatsGapsInner _$SupportWebStatsGapsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportWebStatsGapsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['question', 'page', 'created_at']);
  final val = SupportWebStatsGapsInner(
    question: $checkedConvert('question', (v) => v as String),
    page: $checkedConvert('page', (v) => v as String?),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$SupportWebStatsGapsInnerToJson(
  SupportWebStatsGapsInner instance,
) => <String, dynamic>{
  'question': instance.question,
  'page': instance.page,
  'created_at': instance.createdAt.toIso8601String(),
};
