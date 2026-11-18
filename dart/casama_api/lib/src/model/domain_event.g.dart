// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainEventCWProxy {
  DomainEvent kind(String kind);

  DomainEvent detail(Map<String, Object?> detail);

  DomainEvent createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainEvent call({
    String kind,
    Map<String, Object?> detail,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainEvent.copyWith(...)` or call `instanceOfDomainEvent.copyWith.fieldName(value)` for a single field.
class _$DomainEventCWProxyImpl implements _$DomainEventCWProxy {
  const _$DomainEventCWProxyImpl(this._value);

  final DomainEvent _value;

  @override
  DomainEvent kind(String kind) => call(kind: kind);

  @override
  DomainEvent detail(Map<String, Object?> detail) => call(detail: detail);

  @override
  DomainEvent createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainEvent call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return DomainEvent(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      detail: detail == const $CopyWithPlaceholder() || detail == null
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as Map<String, Object?>,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $DomainEventCopyWith on DomainEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainEvent.copyWith(...)` or `instanceOfDomainEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainEventCWProxy get copyWith => _$DomainEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainEvent _$DomainEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainEvent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'detail', 'created_at']);
      final val = DomainEvent(
        kind: $checkedConvert('kind', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as Map<String, dynamic>),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$DomainEventToJson(DomainEvent instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'detail': instance.detail,
      'created_at': instance.createdAt.toIso8601String(),
    };
