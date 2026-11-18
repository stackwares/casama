// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_bot_use.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerBotUseCWProxy {
  ComputerBotUse botId(String botId);

  ComputerBotUse name(String name);

  ComputerBotUse lastActiveAt(DateTime? lastActiveAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerBotUse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerBotUse(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerBotUse call({String botId, String name, DateTime? lastActiveAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerBotUse.copyWith(...)` or call `instanceOfComputerBotUse.copyWith.fieldName(value)` for a single field.
class _$ComputerBotUseCWProxyImpl implements _$ComputerBotUseCWProxy {
  const _$ComputerBotUseCWProxyImpl(this._value);

  final ComputerBotUse _value;

  @override
  ComputerBotUse botId(String botId) => call(botId: botId);

  @override
  ComputerBotUse name(String name) => call(name: name);

  @override
  ComputerBotUse lastActiveAt(DateTime? lastActiveAt) =>
      call(lastActiveAt: lastActiveAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerBotUse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerBotUse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerBotUse call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? lastActiveAt = const $CopyWithPlaceholder(),
  }) {
    return ComputerBotUse(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      lastActiveAt: lastActiveAt == const $CopyWithPlaceholder()
          ? _value.lastActiveAt
          // ignore: cast_nullable_to_non_nullable
          : lastActiveAt as DateTime?,
    );
  }
}

extension $ComputerBotUseCopyWith on ComputerBotUse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerBotUse.copyWith(...)` or `instanceOfComputerBotUse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerBotUseCWProxy get copyWith => _$ComputerBotUseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerBotUse _$ComputerBotUseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComputerBotUse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['bot_id', 'name', 'last_active_at']);
  final val = ComputerBotUse(
    botId: $checkedConvert('bot_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    lastActiveAt: $checkedConvert(
      'last_active_at',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id', 'lastActiveAt': 'last_active_at'});

Map<String, dynamic> _$ComputerBotUseToJson(ComputerBotUse instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'name': instance.name,
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
    };
