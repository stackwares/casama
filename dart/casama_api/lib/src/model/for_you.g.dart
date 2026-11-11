// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'for_you.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ForYouCWProxy {
  ForYou briefs(List<ForYouBrief> briefs);

  ForYou suggestions(List<Suggestion> suggestions);

  ForYou approvals(List<ForYouApproval> approvals);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYou(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYou(...).copyWith(id: 12, name: "My name")
  /// ```
  ForYou call({
    List<ForYouBrief> briefs,
    List<Suggestion> suggestions,
    List<ForYouApproval> approvals,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfForYou.copyWith(...)` or call `instanceOfForYou.copyWith.fieldName(value)` for a single field.
class _$ForYouCWProxyImpl implements _$ForYouCWProxy {
  const _$ForYouCWProxyImpl(this._value);

  final ForYou _value;

  @override
  ForYou briefs(List<ForYouBrief> briefs) => call(briefs: briefs);

  @override
  ForYou suggestions(List<Suggestion> suggestions) =>
      call(suggestions: suggestions);

  @override
  ForYou approvals(List<ForYouApproval> approvals) =>
      call(approvals: approvals);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYou(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYou(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ForYou call({
    Object? briefs = const $CopyWithPlaceholder(),
    Object? suggestions = const $CopyWithPlaceholder(),
    Object? approvals = const $CopyWithPlaceholder(),
  }) {
    return ForYou(
      briefs: briefs == const $CopyWithPlaceholder() || briefs == null
          ? _value.briefs
          // ignore: cast_nullable_to_non_nullable
          : briefs as List<ForYouBrief>,
      suggestions:
          suggestions == const $CopyWithPlaceholder() || suggestions == null
          ? _value.suggestions
          // ignore: cast_nullable_to_non_nullable
          : suggestions as List<Suggestion>,
      approvals: approvals == const $CopyWithPlaceholder() || approvals == null
          ? _value.approvals
          // ignore: cast_nullable_to_non_nullable
          : approvals as List<ForYouApproval>,
    );
  }
}

extension $ForYouCopyWith on ForYou {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfForYou.copyWith(...)` or `instanceOfForYou.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ForYouCWProxy get copyWith => _$ForYouCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForYou _$ForYouFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ForYou', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['briefs', 'suggestions', 'approvals'],
      );
      final val = ForYou(
        briefs: $checkedConvert(
          'briefs',
          (v) => (v as List<dynamic>)
              .map((e) => ForYouBrief.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        suggestions: $checkedConvert(
          'suggestions',
          (v) => (v as List<dynamic>)
              .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        approvals: $checkedConvert(
          'approvals',
          (v) => (v as List<dynamic>)
              .map((e) => ForYouApproval.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ForYouToJson(ForYou instance) => <String, dynamic>{
  'briefs': instance.briefs.map((e) => e.toJson()).toList(),
  'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
  'approvals': instance.approvals.map((e) => e.toJson()).toList(),
};
