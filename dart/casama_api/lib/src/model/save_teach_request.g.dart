// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_teach_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveTeachRequestCWProxy {
  SaveTeachRequest name(String name);

  SaveTeachRequest description(String description);

  SaveTeachRequest body(String body);

  SaveTeachRequest tryNow(bool? tryNow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveTeachRequest call({
    String name,
    String description,
    String body,
    bool? tryNow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveTeachRequest.copyWith(...)` or call `instanceOfSaveTeachRequest.copyWith.fieldName(value)` for a single field.
class _$SaveTeachRequestCWProxyImpl implements _$SaveTeachRequestCWProxy {
  const _$SaveTeachRequestCWProxyImpl(this._value);

  final SaveTeachRequest _value;

  @override
  SaveTeachRequest name(String name) => call(name: name);

  @override
  SaveTeachRequest description(String description) =>
      call(description: description);

  @override
  SaveTeachRequest body(String body) => call(body: body);

  @override
  SaveTeachRequest tryNow(bool? tryNow) => call(tryNow: tryNow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveTeachRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveTeachRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveTeachRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? tryNow = const $CopyWithPlaceholder(),
  }) {
    return SaveTeachRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      tryNow: tryNow == const $CopyWithPlaceholder()
          ? _value.tryNow
          // ignore: cast_nullable_to_non_nullable
          : tryNow as bool?,
    );
  }
}

extension $SaveTeachRequestCopyWith on SaveTeachRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveTeachRequest.copyWith(...)` or `instanceOfSaveTeachRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveTeachRequestCWProxy get copyWith => _$SaveTeachRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveTeachRequest _$SaveTeachRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SaveTeachRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'description', 'body']);
      final val = SaveTeachRequest(
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        tryNow: $checkedConvert('try_now', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'tryNow': 'try_now'});

Map<String, dynamic> _$SaveTeachRequestToJson(SaveTeachRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'body': instance.body,
      'try_now': ?instance.tryNow,
    };
