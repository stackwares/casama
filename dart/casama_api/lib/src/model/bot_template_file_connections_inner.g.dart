// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file_connections_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileConnectionsInnerCWProxy {
  BotTemplateFileConnectionsInner kind(String kind);

  BotTemplateFileConnectionsInner name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileConnectionsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileConnectionsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFileConnectionsInner call({String kind, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFileConnectionsInner.copyWith(...)` or call `instanceOfBotTemplateFileConnectionsInner.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileConnectionsInnerCWProxyImpl
    implements _$BotTemplateFileConnectionsInnerCWProxy {
  const _$BotTemplateFileConnectionsInnerCWProxyImpl(this._value);

  final BotTemplateFileConnectionsInner _value;

  @override
  BotTemplateFileConnectionsInner kind(String kind) => call(kind: kind);

  @override
  BotTemplateFileConnectionsInner name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileConnectionsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileConnectionsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFileConnectionsInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFileConnectionsInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $BotTemplateFileConnectionsInnerCopyWith
    on BotTemplateFileConnectionsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFileConnectionsInner.copyWith(...)` or `instanceOfBotTemplateFileConnectionsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileConnectionsInnerCWProxy get copyWith =>
      _$BotTemplateFileConnectionsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFileConnectionsInner _$BotTemplateFileConnectionsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BotTemplateFileConnectionsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'name']);
  final val = BotTemplateFileConnectionsInner(
    kind: $checkedConvert('kind', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$BotTemplateFileConnectionsInnerToJson(
  BotTemplateFileConnectionsInner instance,
) => <String, dynamic>{'kind': instance.kind, 'name': instance.name};
