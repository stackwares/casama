// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_season.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateSeasonCWProxy {
  TemplateSeason from(String from);

  TemplateSeason to(String to);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateSeason(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateSeason(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateSeason call({String from, String to});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplateSeason.copyWith(...)` or call `instanceOfTemplateSeason.copyWith.fieldName(value)` for a single field.
class _$TemplateSeasonCWProxyImpl implements _$TemplateSeasonCWProxy {
  const _$TemplateSeasonCWProxyImpl(this._value);

  final TemplateSeason _value;

  @override
  TemplateSeason from(String from) => call(from: from);

  @override
  TemplateSeason to(String to) => call(to: to);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateSeason(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateSeason(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TemplateSeason call({
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
  }) {
    return TemplateSeason(
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as String,
      to: to == const $CopyWithPlaceholder() || to == null
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as String,
    );
  }
}

extension $TemplateSeasonCopyWith on TemplateSeason {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplateSeason.copyWith(...)` or `instanceOfTemplateSeason.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateSeasonCWProxy get copyWith => _$TemplateSeasonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateSeason _$TemplateSeasonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateSeason', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['from', 'to']);
      final val = TemplateSeason(
        from: $checkedConvert('from', (v) => v as String),
        to: $checkedConvert('to', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TemplateSeasonToJson(TemplateSeason instance) =>
    <String, dynamic>{'from': instance.from, 'to': instance.to};
