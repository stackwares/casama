// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_flags.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceFlagsCWProxy {
  GlanceFlags private(bool private);

  GlanceFlags hideReplyText(bool hideReplyText);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceFlags(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceFlags(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceFlags call({bool private, bool hideReplyText});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceFlags.copyWith(...)` or call `instanceOfGlanceFlags.copyWith.fieldName(value)` for a single field.
class _$GlanceFlagsCWProxyImpl implements _$GlanceFlagsCWProxy {
  const _$GlanceFlagsCWProxyImpl(this._value);

  final GlanceFlags _value;

  @override
  GlanceFlags private(bool private) => call(private: private);

  @override
  GlanceFlags hideReplyText(bool hideReplyText) =>
      call(hideReplyText: hideReplyText);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceFlags(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceFlags(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceFlags call({
    Object? private = const $CopyWithPlaceholder(),
    Object? hideReplyText = const $CopyWithPlaceholder(),
  }) {
    return GlanceFlags(
      private: private == const $CopyWithPlaceholder() || private == null
          ? _value.private
          // ignore: cast_nullable_to_non_nullable
          : private as bool,
      hideReplyText:
          hideReplyText == const $CopyWithPlaceholder() || hideReplyText == null
          ? _value.hideReplyText
          // ignore: cast_nullable_to_non_nullable
          : hideReplyText as bool,
    );
  }
}

extension $GlanceFlagsCopyWith on GlanceFlags {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceFlags.copyWith(...)` or `instanceOfGlanceFlags.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceFlagsCWProxy get copyWith => _$GlanceFlagsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceFlags _$GlanceFlagsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceFlags', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['private', 'hide_reply_text']);
      final val = GlanceFlags(
        private: $checkedConvert('private', (v) => v as bool),
        hideReplyText: $checkedConvert('hide_reply_text', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'hideReplyText': 'hide_reply_text'});

Map<String, dynamic> _$GlanceFlagsToJson(GlanceFlags instance) =>
    <String, dynamic>{
      'private': instance.private,
      'hide_reply_text': instance.hideReplyText,
    };
