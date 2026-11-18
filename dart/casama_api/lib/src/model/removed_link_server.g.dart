// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'removed_link_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemovedLinkServerCWProxy {
  RemovedLinkServer removed(String removed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemovedLinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemovedLinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  RemovedLinkServer call({String removed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemovedLinkServer.copyWith(...)` or call `instanceOfRemovedLinkServer.copyWith.fieldName(value)` for a single field.
class _$RemovedLinkServerCWProxyImpl implements _$RemovedLinkServerCWProxy {
  const _$RemovedLinkServerCWProxyImpl(this._value);

  final RemovedLinkServer _value;

  @override
  RemovedLinkServer removed(String removed) => call(removed: removed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemovedLinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemovedLinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemovedLinkServer call({Object? removed = const $CopyWithPlaceholder()}) {
    return RemovedLinkServer(
      removed: removed == const $CopyWithPlaceholder() || removed == null
          ? _value.removed
          // ignore: cast_nullable_to_non_nullable
          : removed as String,
    );
  }
}

extension $RemovedLinkServerCopyWith on RemovedLinkServer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemovedLinkServer.copyWith(...)` or `instanceOfRemovedLinkServer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemovedLinkServerCWProxy get copyWith =>
      _$RemovedLinkServerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemovedLinkServer _$RemovedLinkServerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RemovedLinkServer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['removed']);
      final val = RemovedLinkServer(
        removed: $checkedConvert('removed', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RemovedLinkServerToJson(RemovedLinkServer instance) =>
    <String, dynamic>{'removed': instance.removed};
