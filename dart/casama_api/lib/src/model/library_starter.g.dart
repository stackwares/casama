// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_starter.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LibraryStarterCWProxy {
  LibraryStarter id(String id);

  LibraryStarter label(String label);

  LibraryStarter prompt(String prompt);

  LibraryStarter icon(String icon);

  LibraryStarter hue(num hue);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LibraryStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LibraryStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  LibraryStarter call({
    String id,
    String label,
    String prompt,
    String icon,
    num hue,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLibraryStarter.copyWith(...)` or call `instanceOfLibraryStarter.copyWith.fieldName(value)` for a single field.
class _$LibraryStarterCWProxyImpl implements _$LibraryStarterCWProxy {
  const _$LibraryStarterCWProxyImpl(this._value);

  final LibraryStarter _value;

  @override
  LibraryStarter id(String id) => call(id: id);

  @override
  LibraryStarter label(String label) => call(label: label);

  @override
  LibraryStarter prompt(String prompt) => call(prompt: prompt);

  @override
  LibraryStarter icon(String icon) => call(icon: icon);

  @override
  LibraryStarter hue(num hue) => call(hue: hue);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LibraryStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LibraryStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LibraryStarter call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? hue = const $CopyWithPlaceholder(),
  }) {
    return LibraryStarter(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      prompt: prompt == const $CopyWithPlaceholder() || prompt == null
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      hue: hue == const $CopyWithPlaceholder() || hue == null
          ? _value.hue
          // ignore: cast_nullable_to_non_nullable
          : hue as num,
    );
  }
}

extension $LibraryStarterCopyWith on LibraryStarter {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLibraryStarter.copyWith(...)` or `instanceOfLibraryStarter.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LibraryStarterCWProxy get copyWith => _$LibraryStarterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryStarter _$LibraryStarterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LibraryStarter', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'label', 'prompt', 'icon', 'hue'],
      );
      final val = LibraryStarter(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        prompt: $checkedConvert('prompt', (v) => v as String),
        icon: $checkedConvert('icon', (v) => v as String),
        hue: $checkedConvert('hue', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$LibraryStarterToJson(LibraryStarter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'prompt': instance.prompt,
      'icon': instance.icon,
      'hue': instance.hue,
    };
