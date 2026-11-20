// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_background.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasBackgroundCWProxy {
  CanvasBackground kind(CanvasBackgroundKindEnum kind);

  CanvasBackground color(String? color);

  CanvasBackground from(String? from);

  CanvasBackground to(String? to);

  CanvasBackground picture(String? picture);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasBackground(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasBackground(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasBackground call({
    CanvasBackgroundKindEnum kind,
    String? color,
    String? from,
    String? to,
    String? picture,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasBackground.copyWith(...)` or call `instanceOfCanvasBackground.copyWith.fieldName(value)` for a single field.
class _$CanvasBackgroundCWProxyImpl implements _$CanvasBackgroundCWProxy {
  const _$CanvasBackgroundCWProxyImpl(this._value);

  final CanvasBackground _value;

  @override
  CanvasBackground kind(CanvasBackgroundKindEnum kind) => call(kind: kind);

  @override
  CanvasBackground color(String? color) => call(color: color);

  @override
  CanvasBackground from(String? from) => call(from: from);

  @override
  CanvasBackground to(String? to) => call(to: to);

  @override
  CanvasBackground picture(String? picture) => call(picture: picture);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasBackground(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasBackground(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasBackground call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
    Object? picture = const $CopyWithPlaceholder(),
  }) {
    return CanvasBackground(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as CanvasBackgroundKindEnum,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String?,
      from: from == const $CopyWithPlaceholder()
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as String?,
      to: to == const $CopyWithPlaceholder()
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as String?,
      picture: picture == const $CopyWithPlaceholder()
          ? _value.picture
          // ignore: cast_nullable_to_non_nullable
          : picture as String?,
    );
  }
}

extension $CanvasBackgroundCopyWith on CanvasBackground {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasBackground.copyWith(...)` or `instanceOfCanvasBackground.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasBackgroundCWProxy get copyWith => _$CanvasBackgroundCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasBackground _$CanvasBackgroundFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasBackground', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['kind', 'color', 'from', 'to', 'picture'],
      );
      final val = CanvasBackground(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$CanvasBackgroundKindEnumEnumMap, v),
        ),
        color: $checkedConvert('color', (v) => v as String?),
        from: $checkedConvert('from', (v) => v as String?),
        to: $checkedConvert('to', (v) => v as String?),
        picture: $checkedConvert('picture', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CanvasBackgroundToJson(CanvasBackground instance) =>
    <String, dynamic>{
      'kind': _$CanvasBackgroundKindEnumEnumMap[instance.kind]!,
      'color': instance.color,
      'from': instance.from,
      'to': instance.to,
      'picture': instance.picture,
    };

const _$CanvasBackgroundKindEnumEnumMap = {
  CanvasBackgroundKindEnum.auto: 'auto',
  CanvasBackgroundKindEnum.color: 'color',
  CanvasBackgroundKindEnum.gradient: 'gradient',
  CanvasBackgroundKindEnum.picture: 'picture',
};
