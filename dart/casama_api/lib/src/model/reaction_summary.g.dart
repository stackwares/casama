// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReactionSummaryCWProxy {
  ReactionSummary emoji(String emoji);

  ReactionSummary count(int count);

  ReactionSummary mine(bool mine);

  ReactionSummary users(List<String> users);

  ReactionSummary bots(List<String> bots);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReactionSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReactionSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  ReactionSummary call({
    String emoji,
    int count,
    bool mine,
    List<String> users,
    List<String> bots,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReactionSummary.copyWith(...)` or call `instanceOfReactionSummary.copyWith.fieldName(value)` for a single field.
class _$ReactionSummaryCWProxyImpl implements _$ReactionSummaryCWProxy {
  const _$ReactionSummaryCWProxyImpl(this._value);

  final ReactionSummary _value;

  @override
  ReactionSummary emoji(String emoji) => call(emoji: emoji);

  @override
  ReactionSummary count(int count) => call(count: count);

  @override
  ReactionSummary mine(bool mine) => call(mine: mine);

  @override
  ReactionSummary users(List<String> users) => call(users: users);

  @override
  ReactionSummary bots(List<String> bots) => call(bots: bots);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReactionSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReactionSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReactionSummary call({
    Object? emoji = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? mine = const $CopyWithPlaceholder(),
    Object? users = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
  }) {
    return ReactionSummary(
      emoji: emoji == const $CopyWithPlaceholder() || emoji == null
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      mine: mine == const $CopyWithPlaceholder() || mine == null
          ? _value.mine
          // ignore: cast_nullable_to_non_nullable
          : mine as bool,
      users: users == const $CopyWithPlaceholder() || users == null
          ? _value.users
          // ignore: cast_nullable_to_non_nullable
          : users as List<String>,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as List<String>,
    );
  }
}

extension $ReactionSummaryCopyWith on ReactionSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReactionSummary.copyWith(...)` or `instanceOfReactionSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReactionSummaryCWProxy get copyWith => _$ReactionSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReactionSummary _$ReactionSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReactionSummary', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['emoji', 'count', 'mine', 'users', 'bots'],
      );
      final val = ReactionSummary(
        emoji: $checkedConvert('emoji', (v) => v as String),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        mine: $checkedConvert('mine', (v) => v as bool),
        users: $checkedConvert(
          'users',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        bots: $checkedConvert(
          'bots',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReactionSummaryToJson(ReactionSummary instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'count': instance.count,
      'mine': instance.mine,
      'users': instance.users,
      'bots': instance.bots,
    };
