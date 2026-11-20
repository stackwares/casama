// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasEntryCWProxy {
  CanvasEntry at(DateTime? at);

  CanvasEntry template(CanvasEntryTemplateEnum template);

  CanvasEntry title(String? title);

  CanvasEntry text(String? text);

  CanvasEntry footer(String? footer);

  CanvasEntry target(DateTime? target);

  CanvasEntry count(CanvasEntryCountEnum? count);

  CanvasEntry value(num? value);

  CanvasEntry of_(num? of_);

  CanvasEntry unit(String? unit);

  CanvasEntry items(List<CanvasEntryItemsInner> items);

  CanvasEntry picture(String? picture);

  CanvasEntry short(String short);

  CanvasEntry tiny(String tiny);

  CanvasEntry look(CanvasLook look);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasEntry call({
    DateTime? at,
    CanvasEntryTemplateEnum template,
    String? title,
    String? text,
    String? footer,
    DateTime? target,
    CanvasEntryCountEnum? count,
    num? value,
    num? of_,
    String? unit,
    List<CanvasEntryItemsInner> items,
    String? picture,
    String short,
    String tiny,
    CanvasLook look,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasEntry.copyWith(...)` or call `instanceOfCanvasEntry.copyWith.fieldName(value)` for a single field.
class _$CanvasEntryCWProxyImpl implements _$CanvasEntryCWProxy {
  const _$CanvasEntryCWProxyImpl(this._value);

  final CanvasEntry _value;

  @override
  CanvasEntry at(DateTime? at) => call(at: at);

  @override
  CanvasEntry template(CanvasEntryTemplateEnum template) =>
      call(template: template);

  @override
  CanvasEntry title(String? title) => call(title: title);

  @override
  CanvasEntry text(String? text) => call(text: text);

  @override
  CanvasEntry footer(String? footer) => call(footer: footer);

  @override
  CanvasEntry target(DateTime? target) => call(target: target);

  @override
  CanvasEntry count(CanvasEntryCountEnum? count) => call(count: count);

  @override
  CanvasEntry value(num? value) => call(value: value);

  @override
  CanvasEntry of_(num? of_) => call(of_: of_);

  @override
  CanvasEntry unit(String? unit) => call(unit: unit);

  @override
  CanvasEntry items(List<CanvasEntryItemsInner> items) => call(items: items);

  @override
  CanvasEntry picture(String? picture) => call(picture: picture);

  @override
  CanvasEntry short(String short) => call(short: short);

  @override
  CanvasEntry tiny(String tiny) => call(tiny: tiny);

  @override
  CanvasEntry look(CanvasLook look) => call(look: look);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasEntry call({
    Object? at = const $CopyWithPlaceholder(),
    Object? template = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? footer = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? of_ = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? picture = const $CopyWithPlaceholder(),
    Object? short = const $CopyWithPlaceholder(),
    Object? tiny = const $CopyWithPlaceholder(),
    Object? look = const $CopyWithPlaceholder(),
  }) {
    return CanvasEntry(
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime?,
      template: template == const $CopyWithPlaceholder() || template == null
          ? _value.template
          // ignore: cast_nullable_to_non_nullable
          : template as CanvasEntryTemplateEnum,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      footer: footer == const $CopyWithPlaceholder()
          ? _value.footer
          // ignore: cast_nullable_to_non_nullable
          : footer as String?,
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as DateTime?,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as CanvasEntryCountEnum?,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num?,
      of_: of_ == const $CopyWithPlaceholder()
          ? _value.of_
          // ignore: cast_nullable_to_non_nullable
          : of_ as num?,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CanvasEntryItemsInner>,
      picture: picture == const $CopyWithPlaceholder()
          ? _value.picture
          // ignore: cast_nullable_to_non_nullable
          : picture as String?,
      short: short == const $CopyWithPlaceholder() || short == null
          ? _value.short
          // ignore: cast_nullable_to_non_nullable
          : short as String,
      tiny: tiny == const $CopyWithPlaceholder() || tiny == null
          ? _value.tiny
          // ignore: cast_nullable_to_non_nullable
          : tiny as String,
      look: look == const $CopyWithPlaceholder() || look == null
          ? _value.look
          // ignore: cast_nullable_to_non_nullable
          : look as CanvasLook,
    );
  }
}

extension $CanvasEntryCopyWith on CanvasEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasEntry.copyWith(...)` or `instanceOfCanvasEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasEntryCWProxy get copyWith => _$CanvasEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasEntry _$CanvasEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasEntry', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'at',
          'template',
          'title',
          'text',
          'footer',
          'target',
          'count',
          'value',
          'of',
          'unit',
          'items',
          'picture',
          'short',
          'tiny',
          'look',
        ],
      );
      final val = CanvasEntry(
        at: $checkedConvert(
          'at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        template: $checkedConvert(
          'template',
          (v) => $enumDecode(_$CanvasEntryTemplateEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String?),
        text: $checkedConvert('text', (v) => v as String?),
        footer: $checkedConvert('footer', (v) => v as String?),
        target: $checkedConvert(
          'target',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        count: $checkedConvert(
          'count',
          (v) => $enumDecodeNullable(_$CanvasEntryCountEnumEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as num?),
        of_: $checkedConvert('of', (v) => v as num?),
        unit: $checkedConvert('unit', (v) => v as String?),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    CanvasEntryItemsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        picture: $checkedConvert('picture', (v) => v as String?),
        short: $checkedConvert('short', (v) => v as String),
        tiny: $checkedConvert('tiny', (v) => v as String),
        look: $checkedConvert(
          'look',
          (v) => CanvasLook.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'of_': 'of'});

Map<String, dynamic> _$CanvasEntryToJson(CanvasEntry instance) =>
    <String, dynamic>{
      'at': instance.at?.toIso8601String(),
      'template': _$CanvasEntryTemplateEnumEnumMap[instance.template]!,
      'title': instance.title,
      'text': instance.text,
      'footer': instance.footer,
      'target': instance.target?.toIso8601String(),
      'count': _$CanvasEntryCountEnumEnumMap[instance.count],
      'value': instance.value,
      'of': instance.of_,
      'unit': instance.unit,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'picture': instance.picture,
      'short': instance.short,
      'tiny': instance.tiny,
      'look': instance.look.toJson(),
    };

const _$CanvasEntryTemplateEnumEnumMap = {
  CanvasEntryTemplateEnum.text: 'text',
  CanvasEntryTemplateEnum.countdown: 'countdown',
  CanvasEntryTemplateEnum.number: 'number',
  CanvasEntryTemplateEnum.list: 'list',
  CanvasEntryTemplateEnum.picture: 'picture',
};

const _$CanvasEntryCountEnumEnumMap = {
  CanvasEntryCountEnum.down: 'down',
  CanvasEntryCountEnum.up: 'up',
};
