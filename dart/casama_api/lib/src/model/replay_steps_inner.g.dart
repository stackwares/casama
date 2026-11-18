// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay_steps_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReplayStepsInnerCWProxy {
  ReplayStepsInner tool(String tool);

  ReplayStepsInner note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayStepsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayStepsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  ReplayStepsInner call({String tool, String? note});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReplayStepsInner.copyWith(...)` or call `instanceOfReplayStepsInner.copyWith.fieldName(value)` for a single field.
class _$ReplayStepsInnerCWProxyImpl implements _$ReplayStepsInnerCWProxy {
  const _$ReplayStepsInnerCWProxyImpl(this._value);

  final ReplayStepsInner _value;

  @override
  ReplayStepsInner tool(String tool) => call(tool: tool);

  @override
  ReplayStepsInner note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReplayStepsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReplayStepsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReplayStepsInner call({
    Object? tool = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return ReplayStepsInner(
      tool: tool == const $CopyWithPlaceholder() || tool == null
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $ReplayStepsInnerCopyWith on ReplayStepsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReplayStepsInner.copyWith(...)` or `instanceOfReplayStepsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReplayStepsInnerCWProxy get copyWith => _$ReplayStepsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayStepsInner _$ReplayStepsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReplayStepsInner', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['tool']);
      final val = ReplayStepsInner(
        tool: $checkedConvert('tool', (v) => v as String),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReplayStepsInnerToJson(ReplayStepsInner instance) =>
    <String, dynamic>{'tool': instance.tool, 'note': ?instance.note};
