// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_canvas_grant.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetCanvasGrantCWProxy {
  SetCanvasGrant botId(String botId);

  SetCanvasGrant allowed(bool allowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetCanvasGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetCanvasGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  SetCanvasGrant call({String botId, bool allowed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetCanvasGrant.copyWith(...)` or call `instanceOfSetCanvasGrant.copyWith.fieldName(value)` for a single field.
class _$SetCanvasGrantCWProxyImpl implements _$SetCanvasGrantCWProxy {
  const _$SetCanvasGrantCWProxyImpl(this._value);

  final SetCanvasGrant _value;

  @override
  SetCanvasGrant botId(String botId) => call(botId: botId);

  @override
  SetCanvasGrant allowed(bool allowed) => call(allowed: allowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetCanvasGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetCanvasGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetCanvasGrant call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? allowed = const $CopyWithPlaceholder(),
  }) {
    return SetCanvasGrant(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      allowed: allowed == const $CopyWithPlaceholder() || allowed == null
          ? _value.allowed
          // ignore: cast_nullable_to_non_nullable
          : allowed as bool,
    );
  }
}

extension $SetCanvasGrantCopyWith on SetCanvasGrant {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetCanvasGrant.copyWith(...)` or `instanceOfSetCanvasGrant.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetCanvasGrantCWProxy get copyWith => _$SetCanvasGrantCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetCanvasGrant _$SetCanvasGrantFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetCanvasGrant', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['bot_id', 'allowed']);
      final val = SetCanvasGrant(
        botId: $checkedConvert('bot_id', (v) => v as String),
        allowed: $checkedConvert('allowed', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$SetCanvasGrantToJson(SetCanvasGrant instance) =>
    <String, dynamic>{'bot_id': instance.botId, 'allowed': instance.allowed};
