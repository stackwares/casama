// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_starter.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceStarterCWProxy {
  GlanceStarter emoji(String emoji);

  GlanceStarter text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceStarter call({String emoji, String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceStarter.copyWith(...)` or call `instanceOfGlanceStarter.copyWith.fieldName(value)` for a single field.
class _$GlanceStarterCWProxyImpl implements _$GlanceStarterCWProxy {
  const _$GlanceStarterCWProxyImpl(this._value);

  final GlanceStarter _value;

  @override
  GlanceStarter emoji(String emoji) => call(emoji: emoji);

  @override
  GlanceStarter text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceStarter call({
    Object? emoji = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return GlanceStarter(
      emoji: emoji == const $CopyWithPlaceholder() || emoji == null
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $GlanceStarterCopyWith on GlanceStarter {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceStarter.copyWith(...)` or `instanceOfGlanceStarter.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceStarterCWProxy get copyWith => _$GlanceStarterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceStarter _$GlanceStarterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceStarter', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['emoji', 'text']);
      final val = GlanceStarter(
        emoji: $checkedConvert('emoji', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GlanceStarterToJson(GlanceStarter instance) =>
    <String, dynamic>{'emoji': instance.emoji, 'text': instance.text};
