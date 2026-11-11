// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_bot_response_connections_to_add_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportBotResponseConnectionsToAddInnerCWProxy {
  ImportBotResponseConnectionsToAddInner kind(String kind);

  ImportBotResponseConnectionsToAddInner name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotResponseConnectionsToAddInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotResponseConnectionsToAddInner(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportBotResponseConnectionsToAddInner call({String kind, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportBotResponseConnectionsToAddInner.copyWith(...)` or call `instanceOfImportBotResponseConnectionsToAddInner.copyWith.fieldName(value)` for a single field.
class _$ImportBotResponseConnectionsToAddInnerCWProxyImpl
    implements _$ImportBotResponseConnectionsToAddInnerCWProxy {
  const _$ImportBotResponseConnectionsToAddInnerCWProxyImpl(this._value);

  final ImportBotResponseConnectionsToAddInner _value;

  @override
  ImportBotResponseConnectionsToAddInner kind(String kind) => call(kind: kind);

  @override
  ImportBotResponseConnectionsToAddInner name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportBotResponseConnectionsToAddInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportBotResponseConnectionsToAddInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportBotResponseConnectionsToAddInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return ImportBotResponseConnectionsToAddInner(
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

extension $ImportBotResponseConnectionsToAddInnerCopyWith
    on ImportBotResponseConnectionsToAddInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportBotResponseConnectionsToAddInner.copyWith(...)` or `instanceOfImportBotResponseConnectionsToAddInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportBotResponseConnectionsToAddInnerCWProxy get copyWith =>
      _$ImportBotResponseConnectionsToAddInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportBotResponseConnectionsToAddInner
_$ImportBotResponseConnectionsToAddInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ImportBotResponseConnectionsToAddInner', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['kind', 'name']);
      final val = ImportBotResponseConnectionsToAddInner(
        kind: $checkedConvert('kind', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ImportBotResponseConnectionsToAddInnerToJson(
  ImportBotResponseConnectionsToAddInner instance,
) => <String, dynamic>{'kind': instance.kind, 'name': instance.name};
