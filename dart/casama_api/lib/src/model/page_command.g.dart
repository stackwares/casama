// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_command.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageCommandCWProxy {
  PageCommand id(String id);

  PageCommand name(String name);

  PageCommand prompt(String prompt);

  PageCommand position(int position);

  PageCommand createdAt(DateTime createdAt);

  PageCommand updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageCommand(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageCommand(...).copyWith(id: 12, name: "My name")
  /// ```
  PageCommand call({
    String id,
    String name,
    String prompt,
    int position,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageCommand.copyWith(...)` or call `instanceOfPageCommand.copyWith.fieldName(value)` for a single field.
class _$PageCommandCWProxyImpl implements _$PageCommandCWProxy {
  const _$PageCommandCWProxyImpl(this._value);

  final PageCommand _value;

  @override
  PageCommand id(String id) => call(id: id);

  @override
  PageCommand name(String name) => call(name: name);

  @override
  PageCommand prompt(String prompt) => call(prompt: prompt);

  @override
  PageCommand position(int position) => call(position: position);

  @override
  PageCommand createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  PageCommand updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageCommand(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageCommand(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageCommand call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return PageCommand(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      prompt: prompt == const $CopyWithPlaceholder() || prompt == null
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as String,
      position: position == const $CopyWithPlaceholder() || position == null
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $PageCommandCopyWith on PageCommand {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageCommand.copyWith(...)` or `instanceOfPageCommand.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageCommandCWProxy get copyWith => _$PageCommandCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageCommand _$PageCommandFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PageCommand',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'prompt',
        'position',
        'created_at',
        'updated_at',
      ],
    );
    final val = PageCommand(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      prompt: $checkedConvert('prompt', (v) => v as String),
      position: $checkedConvert('position', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
);

Map<String, dynamic> _$PageCommandToJson(PageCommand instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prompt': instance.prompt,
      'position': instance.position,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
