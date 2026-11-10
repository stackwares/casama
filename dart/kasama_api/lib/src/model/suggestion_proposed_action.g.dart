// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_proposed_action.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuggestionProposedActionCWProxy {
  SuggestionProposedAction tool(String tool);

  SuggestionProposedAction args(Map<String, Object?>? args);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuggestionProposedAction(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuggestionProposedAction(...).copyWith(id: 12, name: "My name")
  /// ```
  SuggestionProposedAction call({String tool, Map<String, Object?>? args});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSuggestionProposedAction.copyWith(...)` or call `instanceOfSuggestionProposedAction.copyWith.fieldName(value)` for a single field.
class _$SuggestionProposedActionCWProxyImpl
    implements _$SuggestionProposedActionCWProxy {
  const _$SuggestionProposedActionCWProxyImpl(this._value);

  final SuggestionProposedAction _value;

  @override
  SuggestionProposedAction tool(String tool) => call(tool: tool);

  @override
  SuggestionProposedAction args(Map<String, Object?>? args) => call(args: args);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SuggestionProposedAction(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SuggestionProposedAction(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SuggestionProposedAction call({
    Object? tool = const $CopyWithPlaceholder(),
    Object? args = const $CopyWithPlaceholder(),
  }) {
    return SuggestionProposedAction(
      tool: tool == const $CopyWithPlaceholder() || tool == null
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      args: args == const $CopyWithPlaceholder()
          ? _value.args
          // ignore: cast_nullable_to_non_nullable
          : args as Map<String, Object?>?,
    );
  }
}

extension $SuggestionProposedActionCopyWith on SuggestionProposedAction {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSuggestionProposedAction.copyWith(...)` or `instanceOfSuggestionProposedAction.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuggestionProposedActionCWProxy get copyWith =>
      _$SuggestionProposedActionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestionProposedAction _$SuggestionProposedActionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SuggestionProposedAction', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['tool']);
  final val = SuggestionProposedAction(
    tool: $checkedConvert('tool', (v) => v as String),
    args: $checkedConvert('args', (v) => v as Map<String, dynamic>?),
  );
  return val;
});

Map<String, dynamic> _$SuggestionProposedActionToJson(
  SuggestionProposedAction instance,
) => <String, dynamic>{'tool': instance.tool, 'args': ?instance.args};
