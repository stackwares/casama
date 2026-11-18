// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_bot_link_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateBotLinkRequestCWProxy {
  CreateBotLinkRequest name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateBotLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateBotLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateBotLinkRequest call({String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateBotLinkRequest.copyWith(...)` or call `instanceOfCreateBotLinkRequest.copyWith.fieldName(value)` for a single field.
class _$CreateBotLinkRequestCWProxyImpl
    implements _$CreateBotLinkRequestCWProxy {
  const _$CreateBotLinkRequestCWProxyImpl(this._value);

  final CreateBotLinkRequest _value;

  @override
  CreateBotLinkRequest name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateBotLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateBotLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateBotLinkRequest call({Object? name = const $CopyWithPlaceholder()}) {
    return CreateBotLinkRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $CreateBotLinkRequestCopyWith on CreateBotLinkRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateBotLinkRequest.copyWith(...)` or `instanceOfCreateBotLinkRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateBotLinkRequestCWProxy get copyWith =>
      _$CreateBotLinkRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBotLinkRequest _$CreateBotLinkRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateBotLinkRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = CreateBotLinkRequest(
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CreateBotLinkRequestToJson(
  CreateBotLinkRequest instance,
) => <String, dynamic>{'name': instance.name};
