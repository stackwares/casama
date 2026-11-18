// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_cancelled_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCancelledEventPayloadCWProxy {
  RunCancelledEventPayload cancelledBy(String? cancelledBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCancelledEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCancelledEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  RunCancelledEventPayload call({String? cancelledBy});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunCancelledEventPayload.copyWith(...)` or call `instanceOfRunCancelledEventPayload.copyWith.fieldName(value)` for a single field.
class _$RunCancelledEventPayloadCWProxyImpl
    implements _$RunCancelledEventPayloadCWProxy {
  const _$RunCancelledEventPayloadCWProxyImpl(this._value);

  final RunCancelledEventPayload _value;

  @override
  RunCancelledEventPayload cancelledBy(String? cancelledBy) =>
      call(cancelledBy: cancelledBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCancelledEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCancelledEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunCancelledEventPayload call({
    Object? cancelledBy = const $CopyWithPlaceholder(),
  }) {
    return RunCancelledEventPayload(
      cancelledBy: cancelledBy == const $CopyWithPlaceholder()
          ? _value.cancelledBy
          // ignore: cast_nullable_to_non_nullable
          : cancelledBy as String?,
    );
  }
}

extension $RunCancelledEventPayloadCopyWith on RunCancelledEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunCancelledEventPayload.copyWith(...)` or `instanceOfRunCancelledEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCancelledEventPayloadCWProxy get copyWith =>
      _$RunCancelledEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCancelledEventPayload _$RunCancelledEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunCancelledEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['cancelled_by']);
  final val = RunCancelledEventPayload(
    cancelledBy: $checkedConvert('cancelled_by', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'cancelledBy': 'cancelled_by'});

Map<String, dynamic> _$RunCancelledEventPayloadToJson(
  RunCancelledEventPayload instance,
) => <String, dynamic>{'cancelled_by': instance.cancelledBy};
