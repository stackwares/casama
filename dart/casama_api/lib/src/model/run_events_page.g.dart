// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_events_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunEventsPageCWProxy {
  RunEventsPage items(List<RunEventEnvelope> items);

  RunEventsPage runStatus(RunStatus runStatus);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunEventsPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunEventsPage(...).copyWith(id: 12, name: "My name")
  /// ```
  RunEventsPage call({List<RunEventEnvelope> items, RunStatus runStatus});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunEventsPage.copyWith(...)` or call `instanceOfRunEventsPage.copyWith.fieldName(value)` for a single field.
class _$RunEventsPageCWProxyImpl implements _$RunEventsPageCWProxy {
  const _$RunEventsPageCWProxyImpl(this._value);

  final RunEventsPage _value;

  @override
  RunEventsPage items(List<RunEventEnvelope> items) => call(items: items);

  @override
  RunEventsPage runStatus(RunStatus runStatus) => call(runStatus: runStatus);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunEventsPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunEventsPage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunEventsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? runStatus = const $CopyWithPlaceholder(),
  }) {
    return RunEventsPage(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RunEventEnvelope>,
      runStatus: runStatus == const $CopyWithPlaceholder() || runStatus == null
          ? _value.runStatus
          // ignore: cast_nullable_to_non_nullable
          : runStatus as RunStatus,
    );
  }
}

extension $RunEventsPageCopyWith on RunEventsPage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunEventsPage.copyWith(...)` or `instanceOfRunEventsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunEventsPageCWProxy get copyWith => _$RunEventsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunEventsPage _$RunEventsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunEventsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'run_status']);
      final val = RunEventsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => RunEventEnvelope.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        runStatus: $checkedConvert(
          'run_status',
          (v) => $enumDecode(_$RunStatusEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runStatus': 'run_status'});

Map<String, dynamic> _$RunEventsPageToJson(RunEventsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'run_status': _$RunStatusEnumMap[instance.runStatus]!,
    };

const _$RunStatusEnumMap = {
  RunStatus.queued: 'queued',
  RunStatus.running: 'running',
  RunStatus.waitingApproval: 'waiting_approval',
  RunStatus.waitingTakeover: 'waiting_takeover',
  RunStatus.completed: 'completed',
  RunStatus.failed: 'failed',
  RunStatus.cancelled: 'cancelled',
};
