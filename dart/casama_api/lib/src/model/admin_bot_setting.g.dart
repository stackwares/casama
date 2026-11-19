// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_bot_setting.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminBotSettingCWProxy {
  AdminBotSetting enabled(bool enabled);

  AdminBotSetting botId(String? botId);

  AdminBotSetting available(bool available);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminBotSetting(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminBotSetting(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminBotSetting call({bool enabled, String? botId, bool available});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminBotSetting.copyWith(...)` or call `instanceOfAdminBotSetting.copyWith.fieldName(value)` for a single field.
class _$AdminBotSettingCWProxyImpl implements _$AdminBotSettingCWProxy {
  const _$AdminBotSettingCWProxyImpl(this._value);

  final AdminBotSetting _value;

  @override
  AdminBotSetting enabled(bool enabled) => call(enabled: enabled);

  @override
  AdminBotSetting botId(String? botId) => call(botId: botId);

  @override
  AdminBotSetting available(bool available) => call(available: available);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminBotSetting(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminBotSetting(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminBotSetting call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
  }) {
    return AdminBotSetting(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
    );
  }
}

extension $AdminBotSettingCopyWith on AdminBotSetting {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminBotSetting.copyWith(...)` or `instanceOfAdminBotSetting.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminBotSettingCWProxy get copyWith => _$AdminBotSettingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminBotSetting _$AdminBotSettingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminBotSetting', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['enabled', 'bot_id', 'available']);
      final val = AdminBotSetting(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        botId: $checkedConvert('bot_id', (v) => v as String?),
        available: $checkedConvert('available', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$AdminBotSettingToJson(AdminBotSetting instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'bot_id': instance.botId,
      'available': instance.available,
    };
