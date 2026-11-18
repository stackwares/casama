// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInputCWProxy {
  GalleryInput key(String key);

  GalleryInput label(String label);

  GalleryInput type(GalleryInputTypeEnum type);

  GalleryInput default_(String? default_);

  GalleryInput options(List<String>? options);

  GalleryInput help(String? help);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInput(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInput call({
    String key,
    String label,
    GalleryInputTypeEnum type,
    String? default_,
    List<String>? options,
    String? help,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInput.copyWith(...)` or call `instanceOfGalleryInput.copyWith.fieldName(value)` for a single field.
class _$GalleryInputCWProxyImpl implements _$GalleryInputCWProxy {
  const _$GalleryInputCWProxyImpl(this._value);

  final GalleryInput _value;

  @override
  GalleryInput key(String key) => call(key: key);

  @override
  GalleryInput label(String label) => call(label: label);

  @override
  GalleryInput type(GalleryInputTypeEnum type) => call(type: type);

  @override
  GalleryInput default_(String? default_) => call(default_: default_);

  @override
  GalleryInput options(List<String>? options) => call(options: options);

  @override
  GalleryInput help(String? help) => call(help: help);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInput call({
    Object? key = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? default_ = const $CopyWithPlaceholder(),
    Object? options = const $CopyWithPlaceholder(),
    Object? help = const $CopyWithPlaceholder(),
  }) {
    return GalleryInput(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryInputTypeEnum,
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as String?,
      options: options == const $CopyWithPlaceholder()
          ? _value.options
          // ignore: cast_nullable_to_non_nullable
          : options as List<String>?,
      help: help == const $CopyWithPlaceholder()
          ? _value.help
          // ignore: cast_nullable_to_non_nullable
          : help as String?,
    );
  }
}

extension $GalleryInputCopyWith on GalleryInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInput.copyWith(...)` or `instanceOfGalleryInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInputCWProxy get copyWith => _$GalleryInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInput _$GalleryInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'label', 'type']);
      final val = GalleryInput(
        key: $checkedConvert('key', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$GalleryInputTypeEnumEnumMap, v),
        ),
        default_: $checkedConvert('default', (v) => v as String?),
        options: $checkedConvert(
          'options',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        help: $checkedConvert('help', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$GalleryInputToJson(GalleryInput instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': _$GalleryInputTypeEnumEnumMap[instance.type]!,
      'default': ?instance.default_,
      'options': ?instance.options,
      'help': ?instance.help,
    };

const _$GalleryInputTypeEnumEnumMap = {
  GalleryInputTypeEnum.text: 'text',
  GalleryInputTypeEnum.choice: 'choice',
  GalleryInputTypeEnum.time: 'time',
  GalleryInputTypeEnum.timezone: 'timezone',
};
