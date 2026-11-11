// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_option_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelOptionListCWProxy {
  ModelOptionList items(List<ModelOption> items);

  ModelOptionList source_(ModelOptionListSource_Enum source_);

  ModelOptionList error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelOptionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelOptionList(...).copyWith(id: 12, name: "My name")
  /// ```
  ModelOptionList call({
    List<ModelOption> items,
    ModelOptionListSource_Enum source_,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfModelOptionList.copyWith(...)` or call `instanceOfModelOptionList.copyWith.fieldName(value)` for a single field.
class _$ModelOptionListCWProxyImpl implements _$ModelOptionListCWProxy {
  const _$ModelOptionListCWProxyImpl(this._value);

  final ModelOptionList _value;

  @override
  ModelOptionList items(List<ModelOption> items) => call(items: items);

  @override
  ModelOptionList source_(ModelOptionListSource_Enum source_) =>
      call(source_: source_);

  @override
  ModelOptionList error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelOptionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelOptionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ModelOptionList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ModelOptionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ModelOption>,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as ModelOptionListSource_Enum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $ModelOptionListCopyWith on ModelOptionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfModelOptionList.copyWith(...)` or `instanceOfModelOptionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelOptionListCWProxy get copyWith => _$ModelOptionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelOptionList _$ModelOptionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModelOptionList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'source']);
      final val = ModelOptionList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ModelOption.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$ModelOptionListSource_EnumEnumMap, v),
        ),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$ModelOptionListToJson(ModelOptionList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'source': _$ModelOptionListSource_EnumEnumMap[instance.source_]!,
      'error': ?instance.error,
    };

const _$ModelOptionListSource_EnumEnumMap = {
  ModelOptionListSource_Enum.live: 'live',
  ModelOptionListSource_Enum.featured: 'featured',
};
