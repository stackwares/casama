// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateListCWProxy {
  TemplateList items(List<Template> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateList(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateList call({List<Template> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateList.copyWith.fieldName(...)`
class _$TemplateListCWProxyImpl implements _$TemplateListCWProxy {
  const _$TemplateListCWProxyImpl(this._value);

  final TemplateList _value;

  @override
  TemplateList items(List<Template> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateList(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateList call({Object? items = const $CopyWithPlaceholder()}) {
    return TemplateList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Template>,
    );
  }
}

extension $TemplateListCopyWith on TemplateList {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateList.copyWith(...)` or like so:`instanceOfTemplateList.copyWith.fieldName(...)`.
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
