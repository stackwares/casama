// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateListCWProxy {
  TemplateList items(List<Template> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateList(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateList call({List<Template> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplateList.copyWith(...)` or call `instanceOfTemplateList.copyWith.fieldName(value)` for a single field.
class _$TemplateListCWProxyImpl implements _$TemplateListCWProxy {
  const _$TemplateListCWProxyImpl(this._value);

  final TemplateList _value;

  @override
  TemplateList items(List<Template> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TemplateList call({Object? items = const $CopyWithPlaceholder()}) {
    return TemplateList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Template>,
    );
  }
}

extension $TemplateListCopyWith on TemplateList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplateList.copyWith(...)` or `instanceOfTemplateList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateListCWProxy get copyWith => _$TemplateListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateList _$TemplateListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = TemplateList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Template.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TemplateListToJson(TemplateList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
